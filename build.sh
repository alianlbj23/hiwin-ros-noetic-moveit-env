#!/usr/bin/env sh

set -e

# 顯示步驟
step() {
    echo "[步驟 $1] $2"
}

# 顯示錯誤並離開
error() {
    echo "\033[31m[錯誤] $1\033[0m" >&2
    exit 1
}

# 取得腳本所在目錄（專案根目錄）
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

# Dockerfile 路徑（在根目錄下的 Dockerfile 資料夾裡）
DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile/Dockerfile"

if [ ! -f "$DOCKERFILE_PATH" ]; then
    error "找不到 Dockerfile：$DOCKERFILE_PATH"
fi

# 從 Dockerfile 讀取 org.opencontainers.image.title
LABEL_LINE=$(grep -E 'LABEL[[:space:]]+org\.opencontainers\.image\.title' "$DOCKERFILE_PATH" | head -n 1 || true)

if [ -z "$LABEL_LINE" ]; then
    error "Dockerfile 中找不到 org.opencontainers.image.title"
fi

# 解析出容器名稱
CONTAINER_NAME=$(printf '%s\n' "$LABEL_LINE" | sed -E 's/.*org\.opencontainers\.image\.title\s*=\s*"([^"]+)".*/\1/')

if [ -z "$CONTAINER_NAME" ]; then
    error "無法解析容器名稱（org.opencontainers.image.title）"
fi

step 1 "開始建立 Docker 映像：$CONTAINER_NAME"

# build context = 專案根目錄 ($SCRIPT_DIR)
docker buildx build --load \
    -t "${CONTAINER_NAME}:latest" \
    -f "$DOCKERFILE_PATH" \
    "$SCRIPT_DIR"

step 2 "映像建立完成！"
docker images "$CONTAINER_NAME"
