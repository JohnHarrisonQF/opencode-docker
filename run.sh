#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="opencode-sandbox"

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

echo -e "\033[0;32mBuilding Docker image: $IMAGE\033[0m"
docker build -f "$SCRIPT_DIR/Dockerfile" $BUILD_ARGS -t $IMAGE "$SCRIPT_DIR"

DOCKER_ARGS=(
  -it --rm
  -v "$(pwd)":/workspace
  -v /var/run/docker.sock:/var/run/docker.sock
  --network host
)

if [ -f "$ENV_FILE" ]; then
  DOCKER_ARGS+=(--env-file "$ENV_FILE")
  echo -e "\033[0;32mUsing environment file: $ENV_FILE\033[0m"
fi

echo -e "\033[0;32mStarting container...\033[0m"
exec docker run "${DOCKER_ARGS[@]}" $IMAGE "$@"