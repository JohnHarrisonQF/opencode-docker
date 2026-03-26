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
ENABLE_CONTEXT7="${ENABLE_CONTEXT7:-true}"
ENABLE_SHOPIFY_DEV="${ENABLE_SHOPIFY_DEV:-true}"
ENABLE_DDG_SEARCH="${ENABLE_DDG_SEARCH:-true}"
ENABLE_FIGMA="${ENABLE_FIGMA:-true}"
ENABLE_FIGMA_DESKTOP="${ENABLE_FIGMA_DESKTOP:-true}"

BUILD_ARGS=(
  --build-arg "ENABLE_INTELLIJ=$ENABLE_INTELLIJ"
  --build-arg "ENABLE_CONTEXT7=$ENABLE_CONTEXT7"
  --build-arg "ENABLE_SHOPIFY_DEV=$ENABLE_SHOPIFY_DEV"
  --build-arg "ENABLE_DDG_SEARCH=$ENABLE_DDG_SEARCH"
  --build-arg "ENABLE_FIGMA=$ENABLE_FIGMA"
  --build-arg "ENABLE_FIGMA_DESKTOP=$ENABLE_FIGMA_DESKTOP"
)

if [ -n "$OLLAMA_PROVIDER_NAME" ]; then
  BUILD_ARGS+=(--build-arg "OLLAMA_PROVIDER_NAME=$OLLAMA_PROVIDER_NAME")
fi
if [ -n "$OLLAMA_PROVIDER_PRETTY_NAME" ]; then
  BUILD_ARGS+=(--build-arg "OLLAMA_PROVIDER_PRETTY_NAME=$OLLAMA_PROVIDER_PRETTY_NAME")
fi
if [ -n "$OLLAMA_HOST" ]; then
  BUILD_ARGS+=(--build-arg "OLLAMA_HOST=$OLLAMA_HOST")
fi
if [ -n "$OLLAMA_MODELS" ]; then
  BUILD_ARGS+=(--build-arg "OLLAMA_MODELS=$OLLAMA_MODELS")
fi

if [ -n "$THEME" ] && [ "$THEME" != "default" ]; then
  BUILD_ARGS+=(--build-arg "THEME=$THEME")
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
  -v /var/run/docker.sock:/var/run/docker.sock
  --network host
)

if [ -f "$ENV_FILE" ]; then
  DOCKER_ARGS+=(--env-file "$ENV_FILE")
  echo -e "${GREEN}Using environment file: $ENV_FILE${RESET}"
fi

echo -e "${GREEN}Starting container...${RESET}"
exec docker run "${DOCKER_ARGS[@]}" $IMAGE "$@"