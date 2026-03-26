#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "$NO_COLOR" ] || [ "$TERM" = "dumb" ]; then
    RED=""
    GREEN=""
    YELLOW=""
    RESET=""
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RESET='\033[0m'
fi

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS] [-- opencode args]"
    echo ""
    echo "Options:"
    echo "  -B, --build        Force rebuild the Docker image"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              Run opencode"
    echo "  $(basename "$0") --build      Rebuild and run"
    echo "  $(basename "$0") -- -h        Pass -h flag to opencode"
    exit 0
}

FORCE_BUILD=false
OPENCODE_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --build|-B)
            FORCE_BUILD=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        --)
            shift
            OPENCODE_ARGS=("$@")
            break
            ;;
        *)
            OPENCODE_ARGS=("$@")
            break
            ;;
    esac
done

cd "$SCRIPT_DIR" || exit

ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

ENABLE_INTELLIJ="${ENABLE_INTELLIJ:-true}"
ENABLE_FIGMA_DESKTOP="${ENABLE_FIGMA_DESKTOP:-true}"

if [ "$ENABLE_INTELLIJ" = "true" ] || [ "$ENABLE_FIGMA_DESKTOP" = "true" ]; then
    export NETWORK_MODE=host
    echo -e "${YELLOW}Network mode: host (required for IntelliJ/Figma Desktop MCP)${RESET}"
fi

if [ "$FORCE_BUILD" = true ]; then
    echo -e "${GREEN}Building Docker image...${RESET}"
    docker compose build --no-cache
fi

if ! docker image inspect opencode-docker > /dev/null 2>&1; then
    echo -e "${GREEN}Building Docker image (first run)...${RESET}"
    docker compose build
fi

echo -e "${GREEN}Starting container...${RESET}"
docker compose run --rm opencode "${OPENCODE_ARGS[@]}"