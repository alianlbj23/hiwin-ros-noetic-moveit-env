#!/usr/bin/env pwsh

# --- 1. Configuration ---
$ContainerName = "hiwin_ros_gui"
$ImageName = "ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4"
$HomeDir = "/root"   # Default home inside container
$DisplayEnv = $env:DISPLAY

Write-Host "--- Starting Docker container with X11 (GUI) support ---"
Write-Host "Image: $ImageName"

# --- 2. X11 Forwarding Setup ---
if (-not $DisplayEnv) {
    Write-Host "[ERROR] DISPLAY environment variable is not set. Make sure X11 is running." -ForegroundColor Red
    exit 1
}

# Generate Xauthority file
$XAuthFile = "/tmp/.docker.xauth"
wsl sh -c "touch $XAuthFile"
wsl sh -c "xauth list $DisplayEnv | sed -e 's/^..../ffff/' | xauth -f $XAuthFile merge -"

# --- 3. Run Docker Container ---
docker run --rm -it `
    --name $ContainerName `
    -e DISPLAY=$DisplayEnv `
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw `
    -v "$XAuthFile:$HomeDir/.Xauthority:rw" `
    --net=host `
    --privileged `
    `
    -p 11311:11311 `
    -p 1503:1503 `
    -p 1504:1504 `
    -p 1505:1505 `
    `
    $ImageName `
    bash

# --- 4. Cleanup ---
wsl sh -c "rm -f $XAuthFile"

Write-Host "--- Container stopped and cleaned up ---"
