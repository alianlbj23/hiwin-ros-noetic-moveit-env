#!/usr/bin/env pwsh

# --- 1. Configuration ---
$ContainerName = "hiwin_ros_gui"
$ImageName     = "ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4"
$HomeDir       = "/root"

Write-Host "---------------------------------------------"
Write-Host "--- Starting Docker container (GUI mode) ---"
Write-Host "Image: $ImageName"
Write-Host "---------------------------------------------"

# --- 2. AUTO SET DISPLAY IF NOT SET ---
if (-not $env:DISPLAY) {
    Write-Host "[INFO] DISPLAY is not set. Applying default setting: host.docker.internal:0.0"
    $env:DISPLAY = "host.docker.internal:0.0"
}

Write-Host "[INFO] Using DISPLAY = $($env:DISPLAY)"

# --- 3. CHECK IF X SERVER IS RUNNING ---
# We check if VcXsrv is running (most common)
$vcxsrv = Get-Process -Name vcxsrv -ErrorAction SilentlyContinue

if (-not $vcxsrv) {

    Write-Host ""
    Write-Host "---------------------------------------------" -ForegroundColor Yellow
    Write-Host "[ERROR] No X Server detected on Windows!" -ForegroundColor Red
    Write-Host ""
    Write-Host "You must install and run an X11 server like VcXsrv to display GUI." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Download VcXsrv from:" -ForegroundColor Cyan
    Write-Host "https://sourceforge.net/projects/vcxsrv/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "After installing, launch VcXsrv with:" -ForegroundColor Yellow
    Write-Host " - Display: 0"
    Write-Host " - Disable access control (for testing)"
    Write-Host " - Start in multi-window mode"
    Write-Host "---------------------------------------------"
    Write-Host ""

    exit 1
}

Write-Host "[OK] X Server detected (VcXsrv running)." -ForegroundColor Green

# --- 4. RUN DOCKER CONTAINER ---
docker run --rm -it `
    --name $ContainerName `
    -e DISPLAY=$env:DISPLAY `
    -p 11311:11311 `
    -p 1503:1503 `
    -p 1504:1504 `
    -p 1505:1505 `
    --net=host `
    --privileged `
    $ImageName `
    bash

Write-Host "--- Container stopped ---"
