#!/bin/bash
set -e

REPO_URL="https://github.com/JohnHarrisonQF/opencode-docker"

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

read -p "Where would you like to install opencode-docker? [~/opencode-docker]: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$HOME/opencode-docker}"
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
    echo ""
    read -p "Opencode is not installed. Would you like to install it now? [Y/n]: " INSTALL_OPENCODE
    INSTALL_OPENCODE="${INSTALL_OPENCODE:-Y}"
    
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
echo ""
echo "To run OpenCode, use the run.sh script:"
echo "  cd $INSTALL_DIR && ./run.sh"
echo ""
echo "Or create an alias (update path to .env file):"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  Add to your ~/.zshrc or ~/.bash_profile:"
    echo "    alias opencode-docker='$INSTALL_DIR/run.sh'"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "  Add to your ~/.bashrc:"
    echo "    alias opencode-docker='$INSTALL_DIR/run.sh'"
else
    echo "  Run directly:"
    echo "    $INSTALL_DIR/run.sh"
fi

echo ""
echo "Environment configuration:"
echo "  .env file location: $INSTALL_DIR/.env"
echo ""
echo "  Please edit your .env file and set your environment variables:"
if [ -n "$EDITOR" ]; then
    echo "    $EDITOR $INSTALL_DIR/.env"
else
    echo "    nano $INSTALL_DIR/.env"
fi