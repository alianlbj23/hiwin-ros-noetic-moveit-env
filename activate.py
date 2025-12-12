#!/usr/bin/env python3
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

CONTAINER_NAME = "hiwin_ros_gui"
IMAGE_NAME = "ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4"
HOME_DIR = "/root"
XAUTH_FILE = "/tmp/.docker.xauth"

def run(cmd, check=True, capture_output=False):
    return subprocess.run(cmd, check=check, capture_output=capture_output, text=True)

def host_os() -> str:
    # "Windows", "Linux", "Darwin"
    return platform.system()

def is_windows() -> bool:
    return host_os() == "Windows"

def is_linux() -> bool:
    return host_os() == "Linux"

def is_macos() -> bool:
    return host_os() == "Darwin"

def is_wsl() -> bool:
    if not is_linux():
        return False
    try:
        version = Path("/proc/version").read_text(errors="ignore")
        if re.search(r"(microsoft|wsl)", version, re.IGNORECASE):
            return True
    except Exception:
        pass
    return bool(os.environ.get("WSL_DISTRO_NAME"))

def is_ubuntu_like() -> bool:
    if not is_linux():
        return False
    p = Path("/etc/os-release")
    if not p.exists():
        return False
    kv = {}
    for line in p.read_text(errors="ignore").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            kv[k.strip()] = v.strip().strip('"')
    _id = kv.get("ID", "")
    id_like = kv.get("ID_LIKE", "")
    return (_id == "ubuntu") or ("ubuntu" in id_like.split())

def need_xauth() -> bool:
    # Only meaningful on Linux/macOS/WSL.
    return is_macos() or is_wsl() or (is_linux() and (not is_ubuntu_like()))

def require_cmd(name: str, hint: str):
    if shutil.which(name) is None:
        print(f"[ERROR] {name} not found on host. Install it:")
        print(f"        {hint}")
        sys.exit(1)

def default_display_for_windows() -> str:
    # Most common for Docker Desktop + VcXsrv/Xming
    return "host.docker.internal:0.0"

def main():
    print("--- Starting Docker container with GUI support ---")
    print(f"Image: {IMAGE_NAME}")
    print(f"Host OS: {host_os()}")

    # --- DISPLAY handling ---
    display = os.environ.get("DISPLAY", "")

    if is_windows():
        # On Windows, if DISPLAY isn't set, auto-fill a sane default.
        if not display:
            display = default_display_for_windows()
            os.environ["DISPLAY"] = display
            print(f"[INFO] DISPLAY not set. Using default: {display}")
        else:
            print(f"[INFO] DISPLAY from env: {display}")
    else:
        if not display:
            print("[ERROR] DISPLAY is not set. Are you running inside a GUI/X11 session?")
            print("        On Ubuntu desktop it is usually :0")
            sys.exit(1)

    print(f"DISPLAY={display}")

    scripts_dir = Path.cwd() / "scripts"
    scripts_mount = f"{str(scripts_dir)}:/root/catkin_ws/scripts:rw"

    # --- docker base args ---
    docker_args = [
        "docker", "run", "--rm", "-it",
        "--name", CONTAINER_NAME,
        "-e", f"DISPLAY={display}",
        "-v", scripts_mount,
        "--net=host",
        "--privileged",
        "-p", "11311:11311",
        "-p", "1503:1503",
        "-p", "1504:1504",
        "-p", "1505:1505",
        IMAGE_NAME,
        "bash",
    ]

    if is_windows():
        # Windows PS + Docker Desktop:
        # Do NOT mount /tmp/.X11-unix, and no xhost/xauth.
        print("[INFO] Mode: Windows (Docker Desktop + VcXsrv/Xming)")
        run(docker_args, check=True)
        print("--- Container stopped ---")
        return

    # Linux/macOS path
    if need_xauth():
        print("[INFO] Mode: XAUTH (non-Ubuntu / macOS / WSL / remote X11)")
        require_cmd("xauth", "Ubuntu/Debian: sudo apt-get install -y xauth")

        # Create xauth file
        try:
            Path(XAUTH_FILE).unlink(missing_ok=True)  # py3.8+
        except TypeError:
            if Path(XAUTH_FILE).exists():
                Path(XAUTH_FILE).unlink()
        Path(XAUTH_FILE).touch()

        # Merge DISPLAY cookie into docker xauth
        try:
            p1 = subprocess.Popen(["xauth", "list", display], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
            p2 = subprocess.Popen(["sed", "-e", "s/^..../ffff/"], stdin=p1.stdout, stdout=subprocess.PIPE, text=True)
            p1.stdout.close()
            p3 = subprocess.Popen(["xauth", "-f", XAUTH_FILE, "merge", "-"], stdin=p2.stdout,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
            p2.stdout.close()
            p3.wait()
        except Exception:
            pass

        docker_args = [
            "docker", "run", "--rm", "-it",
            "--name", CONTAINER_NAME,
            "-e", f"DISPLAY={display}",
            "-v", "/tmp/.X11-unix:/tmp/.X11-unix:rw",
            "-v", f"{XAUTH_FILE}:{HOME_DIR}/.Xauthority:rw",
            "-v", scripts_mount,
            "--net=host",
            "--privileged",
            "-p", "11311:11311",
            "-p", "1503:1503",
            "-p", "1504:1504",
            "-p", "1505:1505",
            IMAGE_NAME,
            "bash",
        ]

        try:
            run(docker_args, check=True)
        finally:
            try:
                Path(XAUTH_FILE).unlink(missing_ok=True)
            except TypeError:
                if Path(XAUTH_FILE).exists():
                    Path(XAUTH_FILE).unlink()

    else:
        print("[INFO] Mode: Ubuntu simplified (xhost + /tmp/.X11-unix)")
        require_cmd("xhost", "sudo apt-get install -y x11-xserver-utils")

        run(["xhost", "+local:docker"], check=True, capture_output=True)

        docker_args = [
            "docker", "run", "--rm", "-it",
            "--name", CONTAINER_NAME,
            "-e", f"DISPLAY={display}",
            "-v", "/tmp/.X11-unix:/tmp/.X11-unix:rw",
            "-v", scripts_mount,
            "--net=host",
            "--privileged",
            "-p", "11311:11311",
            "-p", "1503:1503",
            "-p", "1504:1504",
            "-p", "1505:1505",
            IMAGE_NAME,
            "bash",
        ]

        run(docker_args, check=True)

    print("--- Container stopped ---")

if __name__ == "__main__":
    main()
