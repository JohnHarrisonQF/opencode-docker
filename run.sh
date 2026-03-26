#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="opencode-docker"
FORCE_BUILD=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --build|-B)
      FORCE_BUILD=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

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

ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

THEME="${THEME:-default}"
ENABLE_INTELLIJ="${ENABLE_INTELLIJ:-true}"
ENABLE_DDG_SEARCH="${ENABLE_DDG_SEARCH:-true}"
ENABLE_GSD="${ENABLE_GSD:-true}"

BUILD_ARGS=()

if [ -n "$PHP_VERSION" ]; then
  BUILD_ARGS+=(--build-arg "PHP_VERSION=$PHP_VERSION")
fi

if [ "$ENABLE_DDG_SEARCH" = "true" ]; then
  BUILD_ARGS+=(--build-arg "ENABLE_DDG_SEARCH=true")
fi

if [ "$ENABLE_GSD" = "true" ]; then
  BUILD_ARGS+=(--build-arg "ENABLE_GSD=true")
fi

if [ "$ENABLE_DEVCONTAINERS" = "true" ]; then
  BUILD_ARGS+=(--build-arg "ENABLE_DEVCONTAINERS=true")
fi

IMAGE_EXISTS=false
if docker image inspect "$IMAGE" > /dev/null 2>&1; then
  IMAGE_EXISTS=true
fi

if [ "$FORCE_BUILD" = true ] || [ "$IMAGE_EXISTS" = false ]; then
  echo -e "${GREEN}Building Docker image: $IMAGE${RESET}"
  docker buildx build -f "$SCRIPT_DIR/Dockerfile" "${BUILD_ARGS[@]}" -t "$IMAGE" --load "$SCRIPT_DIR"
else
  echo -e "${GREEN}Using existing image: $IMAGE${RESET}"
  echo -e "${YELLOW}Use --build or -B to force rebuild${RESET}"
fi

DOCKER_ARGS=(
  -it --rm
  -v "$(pwd)":/workspace
  --add-host host.docker.internal:host-gateway
)

if [ "$ENABLE_INTELLIJ" = "true" ]; then
  DOCKER_ARGS+=(--network host)
  echo -e "${YELLOW}Network mode: host (required for IntelliJ MCP)${RESET}"
fi

configure_clipboard() {
  local os_type
  os_type="$(uname -s)"
  
  case "$os_type" in
    Linux)
      if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
        DOCKER_ARGS+=(-e "WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
        DOCKER_ARGS+=(-e "XDG_RUNTIME_DIR=/tmp/xdg-runtime")
        DOCKER_ARGS+=(-v "$XDG_RUNTIME_DIR:/tmp/xdg-runtime")
      elif [ -n "$DISPLAY" ]; then
        DOCKER_ARGS+=(-e "DISPLAY=$DISPLAY")
        if [ -d "/tmp/.X11-unix" ]; then
          DOCKER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix")
        fi
      fi
      ;;
    Darwin)
      if [ -n "$DISPLAY" ]; then
        DOCKER_ARGS+=(-e "DISPLAY=$DISPLAY")
        if [ -d "/tmp/.X11-unix" ]; then
          DOCKER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix")
        fi
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      if [ -n "$DISPLAY" ]; then
        DOCKER_ARGS+=(-e "DISPLAY=$DISPLAY")
      fi
      ;;
  esac
}

configure_clipboard

if [ -f "$ENV_FILE" ]; then
  DOCKER_ARGS+=(--env-file "$ENV_FILE")
  echo -e "${GREEN}Using environment file: $ENV_FILE${RESET}"
fi

echo -e "${GREEN}Starting container...${RESET}"
exec docker run "${DOCKER_ARGS[@]}" $IMAGE "$@"