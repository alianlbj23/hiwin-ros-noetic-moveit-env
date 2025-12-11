#!/bin/bash

# --- 1. 配置變數 ---
CONTAINER_NAME="hiwin_ros_gui"  # 容器名稱
IMAGE_NAME="ghcr.io/alianlbj23/hiwin-ros-noetic-moveit-env:v0.0.4" # 您的映像名稱和標籤
USER_ID=$(id -u)                # 獲取當前主機用戶ID
GROUP_ID=$(id -g)               # 獲取當前主機用戶組ID
HOME_DIR="/home/rosuser"        # 容器內用戶的家目錄

echo "--- 啟動具有 X11 (GUI) 支援的 Docker 容器 ---"
echo "映像: $IMAGE_NAME"

# --- 2. 處理 X11 轉發設定 ---
# 檢查 X server 是否在運行
if [ -z "$DISPLAY" ]; then
    echo "[錯誤] DISPLAY 環境變數未設定。請確保您在 X 視窗環境下運行此腳本。"
    exit 1
fi

# 這是針對 Linux/WSL2 環境最常見的 X11 轉發設置
# 允許容器存取主機的 X server
XAUTH_FILE="/tmp/.docker.xauth"
touch $XAUTH_FILE
xauth list $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH_FILE merge -

# --- 3. 運行容器 ---
# --rm: 容器退出時自動刪除
# -it: 互動模式
# -e DISPLAY=$DISPLAY: 轉發 DISPLAY 環境變數
# -v /tmp/.X11-unix:/tmp/.X11-unix: 映射 X socket
# -v $XAUTH_FILE:/root/.Xauthority: 映射 X 授權文件（給 root 使用）
# --net=host: 某些情況下 (如 ROS/Gazebo) 需要使用主機網路
# --privileged: 為了 ROS/Gazebo 或硬體存取權限，有時需要高權限
docker run --rm -it \
    --name $CONTAINER_NAME \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $XAUTH_FILE:$HOME_DIR/.Xauthority:rw \
    --net=host \
    --privileged \
    $IMAGE_NAME \
    bash

# --- 4. 清理 ---
rm -f $XAUTH_FILE

echo "--- 容器已停止並清理 ---"