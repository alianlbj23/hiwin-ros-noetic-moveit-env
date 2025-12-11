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
    Write-Host "[INFO] DISPLAY is not set. Using default: host.docker.internal:0.0"
    $env:DISPLAY = "host.docker.internal:0.0"
}
Write-Host "[INFO] Using DISPLAY = $($env:DISPLAY)"

# --- 3. Detect if VcXsrv is installed ---
$possiblePaths = @(
    "C:\Program Files\VcXsrv\vcxsrv.exe",
    "C:\Program Files (x86)\VcXsrv\vcxsrv.exe"
)

$installed = $possiblePaths | Where-Object { Test-Path $_ }

if ($installed.Count -gt 0) {
    Write-Host "[OK] VcXsrv installation detected." -ForegroundColor Green
} else {
    Write-Host "[WARN] VcXsrv does not seem to be installed." -ForegroundColor Yellow
    Write-Host "       GUI may not display unless you install VcXsrv."
    Write-Host "       Download: https://sourceforge.net/projects/vcxsrv/"
    Write-Host ""
}

# --- 4. Check if VcXsrv is running ---
$vcxsrv = Get-Process -Name "vcxsrv" -ErrorAction SilentlyContinue

if ($vcxsrv) {
    Write-Host "[OK] X Server is running (vcxsrv detected)." -ForegroundColor Green
} else {

    Write-Host ""
    Write-Host "---------------------------------------------" -ForegroundColor Yellow
    Write-Host "[WARN] VcXsrv is installed but NOT running!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please launch XLaunch (VcXsrv) before running this script." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "How to start:" -ForegroundColor Cyan
    Write-Host "  → Press Windows Key"
    Write-Host "  → Search for: XLaunch"
    Write-Host "  → Run it with:"
    Write-Host "       - Display: 0"
    Write-Host "       - Multiple windows"
    Write-Host "       - Disable access control"
    Write-Host ""
    Write-Host "GUI applications may NOT appear until XLaunch is running."
    Write-Host "---------------------------------------------"
    Write-Host ""
}

# --- 5. Run Docker container ---
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
