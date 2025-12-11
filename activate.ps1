#!/usr/bin/env pwsh

# --- 1. Configuration ---
$ContainerName = "hiwin_ros_gui"
$ImageName     = "ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4"
$HomeDir       = "/root"

# Host scripts folder
$HostScriptsDir = Join-Path (Get-Location) "scripts"
$ContainerScriptsDir = "/root/catkin_ws/scripts"

Write-Host "---------------------------------------------"
Write-Host "--- Starting Docker container (GUI mode) ---"
Write-Host "Image: $ImageName"
Write-Host "---------------------------------------------"

# --- 2. AUTO SET DISPLAY ---
if (-not $env:DISPLAY) {
    Write-Host "[INFO] DISPLAY is not set. Using host.docker.internal:0.0"
    $env:DISPLAY = "host.docker.internal:0.0"
}
Write-Host "[INFO] DISPLAY = $($env:DISPLAY)"

# --- 3. VcXsrv check (optional,只保留偵測) ---
$vcxsrv = Get-Process -Name "vcxsrv" -ErrorAction SilentlyContinue
if (-not $vcxsrv) {
    Write-Host "[WARN] VcXsrv not running. GUI may not show."
}

# --- 4. Ensure scripts directory exists ---
if (-not (Test-Path $HostScriptsDir)) {
    New-Item -ItemType Directory -Path $HostScriptsDir | Out-Null
    Write-Host "[INFO] Created scripts/ directory."
} else {
    Write-Host "[OK] scripts/ directory detected."
}

# Convert to Docker-compatible path
$HostScriptsDirDocker = $HostScriptsDir -replace "\\", "/"
Write-Host "[INFO] Mounting: $HostScriptsDirDocker -> $ContainerScriptsDir"

# --- 5. Start container & run fix_scripts.sh once, then drop into bash ---
docker run --rm -it `
    --name $ContainerName `
    -e DISPLAY=$env:DISPLAY `
    -v "${HostScriptsDirDocker}:${ContainerScriptsDir}:rw" `
    --net=host `
    --privileged `
    $ImageName `
    bash -c "echo '[INFO] Running fix_scripts.sh at startup...'; if [ -f /root/catkin_ws/scripts/fix_scripts.sh ]; then bash /root/catkin_ws/scripts/fix_scripts.sh; else echo '[WARN] fix_scripts.sh not found in scripts/.'; fi; echo '[INFO] Done.'; exec bash"

Write-Host "--- Container stopped ---"
