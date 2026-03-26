#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="opencode-docker"
FORCE_BUILD=false
CONTAINER_CMD=""

detect_container_runtime() {
  if command -v docker &> /dev/null; then
      echo "docker"
  elif command -v podman &> /dev/null; then
    echo "podman"
  else
    echo -e "\033[0;31mError: Neither podman nor docker found. Please install one.\033[0m" >&2
    exit 1
  fi
}

CONTAINER_CMD="${CONTAINER_CMD:-$(detect_container_runtime)}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --build|-B)
      FORCE_BUILD=true
      shift
      ;;
    --podman)
      CONTAINER_CMD="podman"
      shift
      ;;
    --docker)
      CONTAINER_CMD="docker"
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

if [ "$CONTAINER_CMD" = "podman" ]; then
  CONTAINER_ARGS+=(-e "CONTAINER_RUNTIME=podman")
else
  CONTAINER_ARGS+=(-e "CONTAINER_RUNTIME=docker")
fi

IMAGE_EXISTS=false
if $CONTAINER_CMD image inspect "$IMAGE" > /dev/null 2>&1; then
  IMAGE_EXISTS=true
fi

if [ "$FORCE_BUILD" = true ] || [ "$IMAGE_EXISTS" = false ]; then
  echo -e "${GREEN}Building ${CONTAINER_CMD^} image: $IMAGE${RESET}"
  $CONTAINER_CMD build -f "$SCRIPT_DIR/Dockerfile" "${BUILD_ARGS[@]}" -t "$IMAGE" "$SCRIPT_DIR"
else
  echo -e "${GREEN}Using existing ${CONTAINER_CMD^} image: $IMAGE${RESET}"
  echo -e "${YELLOW}Use --build or -B to force rebuild${RESET}"
fi

CONTAINER_ARGS=(
  -it --rm
  -v "$(pwd)":/workspace
)

if [ "$CONTAINER_CMD" = "docker" ]; then
  CONTAINER_ARGS+=(--add-host host.docker.internal:host-gateway)
elif [ "$CONTAINER_CMD" = "podman" ]; then
  CONTAINER_ARGS+=(--add-host host.containers.internal:host-gateway)
  CONTAINER_ARGS+=(--add-host host.docker.internal:host-gateway)
fi

if [ "$ENABLE_INTELLIJ" = "true" ]; then
  CONTAINER_ARGS+=(--network host)
  echo -e "${YELLOW}Network mode: host (required for IntelliJ MCP)${RESET}"
fi

configure_clipboard() {
  local os_type
  os_type="$(uname -s)"
  
  case "$os_type" in
    Linux)
      if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
        CONTAINER_ARGS+=(-e "WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
        CONTAINER_ARGS+=(-e "XDG_RUNTIME_DIR=/tmp/xdg-runtime")
        CONTAINER_ARGS+=(-v "$XDG_RUNTIME_DIR:/tmp/xdg-runtime")
      elif [ -n "$DISPLAY" ]; then
        CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
        if [ -d "/tmp/.X11-unix" ]; then
          CONTAINER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix")
        fi
      fi
      ;;
    Darwin)
      if [ -n "$DISPLAY" ]; then
        CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
        if [ -d "/tmp/.X11-unix" ]; then
          CONTAINER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix")
        fi
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      if [ -n "$DISPLAY" ]; then
        CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
      fi
      ;;
  esac
}

configure_clipboard

if [ -f "$ENV_FILE" ]; then
  CONTAINER_ARGS+=(--env-file "$ENV_FILE")
  echo -e "${GREEN}Using environment file: $ENV_FILE${RESET}"
fi

echo -e "${GREEN}Starting container...${RESET}"
exec $CONTAINER_CMD run "${CONTAINER_ARGS[@]}" $IMAGE "$@"