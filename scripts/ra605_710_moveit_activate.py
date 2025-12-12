#!/usr/bin/env python3
import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("[ERROR] Missing robot IP address.")
        print("Usage: python run_moveit.py <robot_ip>")
        sys.exit(1)

    robot_ip = sys.argv[1]

    print("--------------------------------------")
    print("Launching MoveIt for HIWIN RA605_710")
    print("Simulation mode: ON")
    print(f"Robot IP: {robot_ip}")
    print("--------------------------------------")

    cmd = [
        "roslaunch",
        "hiwin_ra605_710_moveit_config",
        "moveit_planning_execution.launch",
        "sim:=false",
        f"robot_ip:={robot_ip}",
    ]

    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print("[ERROR] roslaunch not found.")
        print("        Did you source ROS?")
        print("        e.g. source /opt/ros/noetic/setup.bash")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] roslaunch exited with code {e.returncode}")
        sys.exit(e.returncode)


if __name__ == "__main__":
    main()
