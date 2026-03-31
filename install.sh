#!/bin/bash
set -e

REPO_URL="https://github.com/PlasticlightS/opencode-docker"

if [ -n "$NO_COLOR" ] || [ "$TERM" = "dumb" ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    RESET='\033[0m'
fi

error() {
    echo -e "${RED}ERROR:${RESET} $1" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO:${RESET} $1"
}

success() {
    echo -e "${GREEN}SUCCESS:${RESET} $1"
}

warn() {
    echo -e "${YELLOW}WARNING:${RESET} $1"
}

if ! command -v docker &> /dev/null; then
    error "Docker is required but not installed. Please install Docker first."
fi

DEFAULT_INSTALL_DIR="$HOME/opencode-docker"
if [ -e /dev/tty ]; then
    read -r -p "Where would you like to install opencode-docker? [$DEFAULT_INSTALL_DIR]: " INPUT_DIR < /dev/tty
    INSTALL_DIR="${INPUT_DIR:-$DEFAULT_INSTALL_DIR}"
else
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi

INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

if [ -d "$INSTALL_DIR" ]; then
    if [ -d "$INSTALL_DIR/.git" ]; then
        info "Repository found at $INSTALL_DIR, pulling latest version..."
        cd "$INSTALL_DIR"
        git pull
    else
        error "Directory $INSTALL_DIR exists but is not a git repository. Please choose a different location."
    fi
else
    info "Cloning repository to $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        info "Created .env file from .env.example"
    fi
fi

if ! command -v opencode &> /dev/null; then
    if [ -e /dev/tty ]; then
        echo ""
        read -r -p "Opencode is not installed. Would you like to install it now? [Y/n]: " INSTALL_OPENCODE < /dev/tty
        INSTALL_OPENCODE="${INSTALL_OPENCODE:-Y}"
    else
        INSTALL_OPENCODE="Y"
    fi
    
    if [[ "$INSTALL_OPENCODE" =~ ^[Yy]$ ]]; then
        info "Installing opencode..."
        curl -fsSL https://opencode.ai/install | bash
    else
        warn "Opencode was not installed."
        echo "Please install opencode manually: https://opencode.ai/docs#install"
    fi
fi

echo ""
success "Installation complete!"

# Alias management
# Detect shell - use $SHELL since the script runs with bash regardless
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" = "zsh" ]; then
    DEFAULT_CONFIG="$HOME/.zshrc"
else
    DEFAULT_CONFIG="$HOME/.bashrc"
fi

echo ""
while true; do
    if [ -e /dev/tty ]; then
        read -r -p "Which file should the alias be added to? [$DEFAULT_CONFIG]: " INPUT_CONFIG < /dev/tty
        CONFIG_FILE="${INPUT_CONFIG:-$DEFAULT_CONFIG}"
    else
        CONFIG_FILE="$DEFAULT_CONFIG"
    fi

    CONFIG_FILE="${CONFIG_FILE/#\~/$HOME}"

    if [ -f "$CONFIG_FILE" ]; then
        break
    else
        warn "Config file $CONFIG_FILE not found. Please provide a valid shell configuration file."


        if [ ! -e /dev/tty ]; then
            error "Config file $CONFIG_FILE not found and not in a TTY to prompt again."
        fi
    fi
done

ALIAS_LINE="alias opencode-docker='$INSTALL_DIR/run.sh'"

if grep -Fq "alias opencode-docker=" "$CONFIG_FILE"; then
    info "Alias 'opencode-docker' already exists in $CONFIG_FILE"
else
    if [ -s "$CONFIG_FILE" ]; then
        echo "" >> "$CONFIG_FILE"
    fi
    echo "# Opencode Docker" >> "$CONFIG_FILE"
    echo "$ALIAS_LINE" >> "$CONFIG_FILE"
    success "Added alias to $CONFIG_FILE"
fi

echo ""
echo "Then reload your shell and run from any project:"
echo "  source $CONFIG_FILE"
echo "  cd /path/to/your-project"
echo "  opencode-docker"
echo ""
echo "Configuration:"
echo "  Edit $INSTALL_DIR/.env to set API keys and preferences"
if [ -n "$EDITOR" ]; then
    echo "    $EDITOR $INSTALL_DIR/.env"
else
    echo "    nano $INSTALL_DIR/.env"
fi