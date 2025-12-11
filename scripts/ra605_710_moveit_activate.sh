#!/bin/bash

# ================================
# HIWIN RA605 MoveIt Launch Script
# Usage:
#   ./run_moveit.sh <robot_ip>
#
# Example:
#   ./run_moveit.sh 192.168.0.103
# ================================

if [ -z "$1" ]; then
    echo "[ERROR] Missing robot IP address."
    echo "Usage: ./run_moveit.sh <robot_ip>"
    exit 1
fi

ROBOT_IP="$1"

echo "--------------------------------------"
echo "Launching MoveIt for HIWIN RA605_710"
echo "Simulation mode: ON"
echo "Robot IP: $ROBOT_IP"
echo "--------------------------------------"

# Execute ROS launch
roslaunch hiwin_ra605_710_moveit_config moveit_planning_execution.launch \
    sim:=true \
    robot_ip:=$ROBOT_IP
