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

detect_container_runtime() {
    if [ -n "$CONTAINER_RUNTIME" ]; then
        COMPOSE_CMD="$CONTAINER_RUNTIME compose"
        return
    fi
    
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v podman &> /dev/null && podman compose version &> /dev/null 2>&1; then
        COMPOSE_CMD="podman compose"
    elif command -v podman-compose &> /dev/null; then
        COMPOSE_CMD="podman-compose"
    else
        echo -e "${RED}ERROR: No container runtime found. Install Docker or Podman.${RESET}" >&2
        exit 1
    fi
}

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

detect_container_runtime

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
    echo -e "${GREEN}Building image with $COMPOSE_CMD...${RESET}"
    $COMPOSE_CMD build --no-cache
fi

if ! $COMPOSE_CMD image inspect opencode-docker > /dev/null 2>&1; then
    echo -e "${GREEN}Building image (first run)...${RESET}"
    $COMPOSE_CMD build
fi

echo -e "${GREEN}Starting container...${RESET}"
$COMPOSE_CMD run --rm opencode "${OPENCODE_ARGS[@]}"