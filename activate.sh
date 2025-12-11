#!/bin/bash

# --- 1. Configuration ---
CONTAINER_NAME="hiwin_ros_gui"
IMAGE_NAME="ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4"
USER_ID=$(id -u)
GROUP_ID=$(id -g)
HOME_DIR="/root"   # Default user inside your image is root

echo "--- Starting Docker container with X11 (GUI) support ---"
echo "Image: $IMAGE_NAME"

# --- 2. X11 Forwarding Setup ---
# Check DISPLAY availability
if [ -z "$DISPLAY" ]; then
    echo "[ERROR] DISPLAY environment variable is not set. Make sure you are running inside an X11 environment."
    exit 1
fi

# Generate X11 auth file
XAUTH_FILE="/tmp/.docker.xauth"
touch $XAUTH_FILE
xauth list "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH_FILE" merge -

# --- 3. Run Docker Container ---
docker run --rm -it \
    --name "$CONTAINER_NAME" \
    -e DISPLAY="$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$XAUTH_FILE":"$HOME_DIR/.Xauthority":rw \
    -v "$(pwd)/scripts:/root/catkin_ws/scripts:rw" \
    --net=host \
    --privileged \
    \
    -p 11311:11311 \
    -p 1503:1503 \
    -p 1504:1504 \
    -p 1505:1505 \
    \
    "$IMAGE_NAME" \
    bash

# --- 4. Cleanup ---
rm -f "$XAUTH_FILE"

echo "--- Container stopped and cleaned up ---"
