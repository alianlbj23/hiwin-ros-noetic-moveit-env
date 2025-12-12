# hiwin-ros-noetic-moveit-env
This repository provides a complete development environment for HIWIN robots using ROS Noetic and MoveIt, packaged as a Docker image for easy and reproducible setup.

This workspace integrates:

- **HIWIN Robot Client Library**
https://github.com/HIWINCorporation/hiwin_robot_client_library

- **HIWIN ROS Packages**
https://github.com/HIWINCorporation/hiwin_ros

These libraries are built and included inside the Docker container so you can focus on development and motion planning.

---

## 🧠 What’s Inside

- **Dockerfile** - Builds a ROS Noetic + MoveIt image with HIWIN support

- **scripts/** - Utility scripts to launch your robot and GUI

- **Workspace** - Fully prepared `catkin_ws` including hiwin_ros and dependencies

- **activate.sh / activate.ps1** - One-click start scripts with GUI-enabled Docker runtime

## 💻 System Requirements

- **Operating System**: This setup is supported on **Windows** and **Linux**.
  - macOS users should use a virtual machine running a supported OS.
- **Windows Users**: Before starting, you must download and run **Xming Server** to enable GUI support.
  - [Download Xming here](https://sourceforge.net/projects/xming/)

---

## 🚀 Quick Start (Recommended: Use Prebuilt Image)

A prebuilt Docker image is available on GitHub Container Registry (GHCR).

### Pull the image:

```bash
docker pull ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4
```

or always pull latest:

```bash
docker pull ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:latest
```

### Start the environment (GUI supported):

```bash
python ./activate.py
```

### Run MoveIt for HIWIN RA605

Inside the container or by calling the script directly:

```bash
python3 ./scripts/ra605_710_moveit_activate.py <robot_ip>
```

### 🏗 Optional: Build Docker Image Locally

If you prefer building the image yourself:

### Build:

```bash
./build.sh
```

## 📦 Included Packages in the Docker Image

The image contains:

- ROS Noetic (desktop-full)
- MoveIt
- Warehouse ROS Mongo
- Pilz Industrial Motion Planner
- ROS-Industrial Core
- MongoDB (required for MoveIt warehouse)
- hiwin_robot_client_library (built and installed)
- hiwin_ros (cloned & built)