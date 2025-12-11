#!/bin/bash

SCRIPT_DIR="/root/catkin_ws/scripts"

echo "[INFO] Running script auto-fix..."

if [ -d "$SCRIPT_DIR" ]; then
    for f in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$f" ]; then
            sed -i 's/\r$//' "$f"
            chmod +x "$f"
            echo "[OK] Fixed: $(basename "$f")"
        fi
    done
fi

echo "[INFO] Script auto-fix complete."
