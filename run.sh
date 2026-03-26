#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="opencode-sandbox"

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
INCLUDE_INTIJ="${INCLUDE_INTIJ:-true}"

BUILD_ARGS="--build-arg INCLUDE_INTIJ=$INCLUDE_INTIJ"
if [ -n "$THEME" ] && [ "$THEME" != "default" ]; then
  BUILD_ARGS="$BUILD_ARGS --build-arg THEME=$THEME"
  IMAGE="${IMAGE}-${THEME}"
fi

echo -e "${GREEN}Building Docker image: $IMAGE${RESET}"
docker build -f "$SCRIPT_DIR/Dockerfile" $BUILD_ARGS -t $IMAGE "$SCRIPT_DIR"

DOCKER_ARGS=(
  -it --rm
  -v "$(pwd)":/workspace
  -v /var/run/docker.sock:/var/run/docker.sock
  --network host
)

if [ -f "$ENV_FILE" ]; then
  DOCKER_ARGS+=(--env-file "$ENV_FILE")
  echo -e "${GREEN}Using environment file: $ENV_FILE${RESET}"
fi

echo -e "${GREEN}Starting container...${RESET}"
exec docker run "${DOCKER_ARGS[@]}" $IMAGE "$@"