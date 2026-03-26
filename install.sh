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

if ! docker compose version &> /dev/null; then
    error "Docker Compose is required but not installed. Please install Docker Compose first."
fi

DEFAULT_INSTALL_DIR="$HOME/opencode-docker"
if [ -e /dev/tty ]; then
    read -p "Where would you like to install opencode-docker? [$DEFAULT_INSTALL_DIR]: " INPUT_DIR < /dev/tty
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

echo ""
success "Installation complete!"
echo ""
echo "Add this alias to your ~/.zshrc or ~/.bashrc:"
echo "  alias opencode-docker='$INSTALL_DIR/run.sh'"
echo ""
echo "Then reload your shell and run from any project:"
echo "  source ~/.zshrc or ~/.bashrc"
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