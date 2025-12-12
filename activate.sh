#!/usr/bin/env bash
set -euo pipefail

# --- 1. Configuration ---
CONTAINER_NAME="hiwin_ros_gui"
IMAGE_NAME="ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4"
HOME_DIR="/root"   # default user inside image is root

# --- helpers ---
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# Detect WSL (Linux kernel but WSL env)
is_wsl() {
  if is_linux; then
    grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]
  else
    return 1
  fi
}

# Detect Ubuntu (also covers many derivatives via /etc/os-release)
is_ubuntu_like() {
  if is_linux && [[ -r /etc/os-release ]]; then
    . /etc/os-release
    [[ "${ID:-}" == "ubuntu" ]] || [[ "${ID_LIKE:-}" =~ ubuntu ]]
  else
    return 1
  fi
}

need_xauth() {
  # Use XAUTH for non-Ubuntu or for WSL/macOS-style forwarding paths.
  # Ubuntu desktop typically doesn't need it if xhost is used.
  is_macos || is_wsl || ! is_ubuntu_like
}

echo "--- Starting Docker container with GUI support ---"
echo "Image: $IMAGE_NAME"
echo "Host OS: $(uname -s)"

# --- 2. DISPLAY check ---
if [[ -z "${DISPLAY:-}" ]]; then
  echo "[ERROR] DISPLAY is not set. Are you running inside a GUI/X11 session?"
  echo "        On Ubuntu desktop it is usually :0"
  exit 1
fi
echo "DISPLAY=$DISPLAY"

# --- 3. Setup and run ---
XAUTH_FILE="/tmp/.docker.xauth"

if need_xauth; then
  echo "[INFO] Mode: XAUTH (non-Ubuntu / macOS / WSL / remote X11)"
  if ! command -v xauth >/dev/null 2>&1; then
    echo "[ERROR] xauth not found on host. Install it:"
    echo "        Ubuntu/Debian: sudo apt-get install -y xauth"
    exit 1
  fi

  rm -f "$XAUTH_FILE"
  touch "$XAUTH_FILE"

  # Merge current DISPLAY cookie into docker xauth file (ignore if empty list)
  xauth list "$DISPLAY" 2>/dev/null | sed -e 's/^..../ffff/' | xauth -f "$XAUTH_FILE" merge - 2>/dev/null || true

  docker run --rm -it \
    --name "$CONTAINER_NAME" \
    -e DISPLAY="$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$XAUTH_FILE":"$HOME_DIR/.Xauthority":rw \
    -v "$(pwd)/scripts:/root/catkin_ws/scripts:rw" \
    --net=host \
    --privileged \
    -p 11311:11311 \
    -p 1503:1503 \
    -p 1504:1504 \
    -p 1505:1505 \
    "$IMAGE_NAME" \
    bash

  rm -f "$XAUTH_FILE"
else
  echo "[INFO] Mode: Ubuntu simplified (xhost + /tmp/.X11-unix)"
  if ! command -v xhost >/dev/null 2>&1; then
    echo "[ERROR] xhost not found on host. Install it:"
    echo "        sudo apt-get install -y x11-xserver-utils"
    exit 1
  fi

  # Allow local docker to access X server
  xhost +local:docker >/dev/null

  docker run --rm -it \
    --name "$CONTAINER_NAME" \
    -e DISPLAY="$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$(pwd)/scripts:/root/catkin_ws/scripts:rw" \
    --net=host \
    --privileged \
    -p 11311:11311 \
    -p 1503:1503 \
    -p 1504:1504 \
    -p 1505:1505 \
    "$IMAGE_NAME" \
    bash
fi

echo "--- Container stopped ---"
