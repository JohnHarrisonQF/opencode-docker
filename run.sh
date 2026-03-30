#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="opencode-docker"
GUI_IMAGE="opencode-docker-gui"
FORCE_BUILD=false
GUI_MODE=false
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
    --gui)
      GUI_MODE=true
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

IMAGE_EXISTS=false
if $CONTAINER_CMD image inspect "$IMAGE" > /dev/null 2>&1; then
  IMAGE_EXISTS=true
fi

if [ "$GUI_MODE" = true ]; then
  IMAGE="$GUI_IMAGE"
  IMAGE_EXISTS=false
  if $CONTAINER_CMD image inspect "$GUI_IMAGE" > /dev/null 2>&1; then
    IMAGE_EXISTS=true
  fi
fi

if [ "$FORCE_BUILD" = true ] || [ "$IMAGE_EXISTS" = false ]; then
  echo -e "${GREEN}Building ${CONTAINER_CMD^} image: $IMAGE${RESET}"
  if [ "$GUI_MODE" = true ]; then
    $CONTAINER_CMD build -f "$SCRIPT_DIR/Dockerfile.gui" "${BUILD_ARGS[@]}" -t "$GUI_IMAGE" "$SCRIPT_DIR"
  else
    $CONTAINER_CMD build -f "$SCRIPT_DIR/Dockerfile" "${BUILD_ARGS[@]}" -t "$IMAGE" "$SCRIPT_DIR"
  fi
else
  echo -e "${GREEN}Using existing ${CONTAINER_CMD^} image: $IMAGE${RESET}"
  echo -e "${YELLOW}Use --build or -B to force rebuild${RESET}"
fi

CONTAINER_ARGS=(
  -it --rm
  -v "$(pwd)":/workspace
  --user "$(id -u):$(id -g)"
  -e "HOME=/home/opencode"
  -e "CONTAINER_RUNTIME=$CONTAINER_CMD"
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
  
  # For GUI mode, we configure display below
  if [ "$GUI_MODE" = true ]; then
    return
  fi
  
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

configure_gpu() {
  if [ -d "/dev/dri" ]; then
    CONTAINER_ARGS+=(--device /dev/dri)
    local video_gid render_gid
    video_gid=$(getent group video 2>/dev/null | cut -d: -f3)
    render_gid=$(getent group render 2>/dev/null | cut -d: -f3)
    if [ -n "$video_gid" ]; then
      CONTAINER_ARGS+=(--group-add "$video_gid")
    fi
    if [ -n "$render_gid" ] && [ "$render_gid" != "$video_gid" ]; then
      CONTAINER_ARGS+=(--group-add "$render_gid")
    fi
    echo -e "${GREEN}GPU acceleration enabled (/dev/dri)${RESET}"
  fi
  
  if [ -n "$(ls /dev/nvidia* 2>/dev/null)" ]; then
    echo -e "${YELLOW}NVIDIA GPU detected: Requires NVIDIA Container Toolkit${RESET}" >&2
    echo -e "${YELLOW}Install: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html${RESET}" >&2
  fi
}

configure_gui_display() {
  local os_type
  os_type="$(uname -s)"
  
  case "$os_type" in
    Linux)
      configure_gpu
      if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
        CONTAINER_ARGS+=(-e "WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
        CONTAINER_ARGS+=(-e "XDG_RUNTIME_DIR=/tmp/xdg-runtime")
        CONTAINER_ARGS+=(-v "$XDG_RUNTIME_DIR:/tmp/xdg-runtime")
        echo -e "${GREEN}GUI mode: Wayland display configured${RESET}"
      elif [ -n "$DISPLAY" ]; then
        if [ -d "/tmp/.X11-unix" ]; then
          CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
          CONTAINER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix:ro")
          if [ -f "$HOME/.Xauthority" ]; then
            CONTAINER_ARGS+=(-v "$HOME/.Xauthority:/tmp/.Xauthority:ro")
            CONTAINER_ARGS+=(-e "XAUTHORITY=/tmp/.Xauthority")
          fi
          echo -e "${GREEN}GUI mode: X11 display configured${RESET}"
        else
          echo -e "${RED}Error: X11 socket not found at /tmp/.X11-unix${RESET}" >&2
          echo -e "${YELLOW}Fix: Ensure X11 is running or export DISPLAY=:0${RESET}" >&2
          exit 1
        fi
      else
        echo -e "${RED}Error: No display detected. Set DISPLAY or WAYLAND_DISPLAY${RESET}" >&2
        echo -e "${YELLOW}Fix: export DISPLAY=:0 or run in graphical session${RESET}" >&2
        exit 1
      fi
      ;;
    Darwin)
      if [ -n "$DISPLAY" ]; then
        if [ -d "/tmp/.X11-unix" ]; then
          CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
          CONTAINER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix:ro")
          echo -e "${GREEN}GUI mode: macOS XQuartz configured${RESET}"
        else
          echo -e "${RED}Error: XQuartz not running or X11 socket missing${RESET}" >&2
          echo -e "${YELLOW}Fix: Install XQuartz: brew install --cask xquartz${RESET}" >&2
          echo -e "${YELLOW}Fix: Start XQuartz and enable network connections${RESET}" >&2
          exit 1
        fi
      else
        echo -e "${RED}Error: DISPLAY not set${RESET}" >&2
        echo -e "${YELLOW}Fix: Start XQuartz and run: export DISPLAY=:0${RESET}" >&2
        exit 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      if [ -n "$WAYLAND_DISPLAY" ] && [ -d "/mnt/wslg" ]; then
        CONTAINER_ARGS+=(-e "WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
        CONTAINER_ARGS+=(-e "XDG_RUNTIME_DIR=/tmp/xdg-runtime")
        if [ -n "$XDG_RUNTIME_DIR" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
          CONTAINER_ARGS+=(-v "$XDG_RUNTIME_DIR:/tmp/xdg-runtime")
        fi
        CONTAINER_ARGS+=(-v "/mnt/wslg:/mnt/wslg")
        if [ -n "$DISPLAY" ]; then
          CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
        fi
        if [ -n "$PULSE_SERVER" ]; then
          CONTAINER_ARGS+=(-e "PULSE_SERVER=$PULSE_SERVER")
        fi
        echo -e "${GREEN}GUI mode: WSLg configured (Wayland + X11 + PulseAudio)${RESET}"
      elif [ -n "$DISPLAY" ]; then
        CONTAINER_ARGS+=(-e "DISPLAY=$DISPLAY")
        if [ -d "/tmp/.X11-unix" ]; then
          CONTAINER_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix:ro")
          echo -e "${GREEN}GUI mode: Windows X11 socket configured${RESET}"
        else
          echo -e "${GREEN}GUI mode: Windows X11 configured (DISPLAY=$DISPLAY)${RESET}"
          echo -e "${YELLOW}Note: Using network X11 forwarding (VcXsrv/Xming/Docker Desktop)${RESET}"
        fi
      else
        echo -e "${RED}Error: No display configured for Windows GUI mode${RESET}" >&2
        echo -e "${YELLOW}Options:${RESET}" >&2
        echo -e "${YELLOW}  Windows 11 + WSLg: Run from WSL2, DISPLAY auto-set${RESET}" >&2
        echo -e "${YELLOW}  VcXsrv/Xming: Start server, then: export DISPLAY=host.docker.internal:0${RESET}" >&2
        echo -e "${YELLOW}  Docker Desktop: Set DISPLAY=host.docker.internal:0${RESET}" >&2
        exit 1
      fi
      ;;
    *)
      echo -e "${RED}Error: GUI mode not supported on $os_type${RESET}" >&2
      echo -e "${YELLOW}Use TUI mode (default) or native desktop app${RESET}" >&2
      exit 1
      ;;
  esac
}

configure_clipboard
if [ "$GUI_MODE" = true ]; then
  configure_gui_display
fi

if [ -f "$ENV_FILE" ]; then
  CONTAINER_ARGS+=(--env-file "$ENV_FILE")
  echo -e "${GREEN}Using environment file: $ENV_FILE${RESET}"
fi

echo -e "${GREEN}Starting container...${RESET}"
exec $CONTAINER_CMD run "${CONTAINER_ARGS[@]}" $IMAGE "$@"