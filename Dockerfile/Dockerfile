FROM gramaziokohler/ros-noetic-moveit:20.12

LABEL org.opencontainers.image.title="ros-noetic-moveit-hiwin"
LABEL org.opencontainers.image.description="ROS Noetic + MoveIt + HIWIN Robot Client Library + hiwin_ros"
LABEL maintainer="your_name <you@example.com>"

ENV DEBIAN_FRONTEND=noninteractive

# 基本工具 & rosdep
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    python3-rosdep \
 && rm -rf /var/lib/apt/lists/*

# rosdep 初始化（如果已經 init 過會失敗，所以用 || 包起來）
RUN rosdep update || (rosdep init && rosdep update)

#--------------------------------------------------
# 1. 安裝 hiwin_robot_client_library (CMake)
#--------------------------------------------------
WORKDIR /opt

RUN git clone https://github.com/HIWINCorporation/hiwin_robot_client_library.git \
 && cd hiwin_robot_client_library \
 && mkdir build && cd build \
 && cmake .. \
 && make -j"$(nproc)" \
 && make install \
 && ldconfig \
 # 可選：刪掉 build 降低 image 大小
 && cd /opt/hiwin_robot_client_library \
 && rm -rf build

#--------------------------------------------------
# 2. 建 catkin_ws 並 clone hiwin_ros（noetic-devel）
#--------------------------------------------------
ENV CATKIN_WS=/root/catkin_ws
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS

# 依 README：noetic 用 noetic-devel 分支:contentReference[oaicite:0]{index=0}
RUN git clone -b noetic-devel https://github.com/HIWINCorporation/hiwin_ros.git src

#--------------------------------------------------
# 3. rosdep 安裝依賴 + catkin_make
#--------------------------------------------------
RUN /bin/bash -lc "source /opt/ros/noetic/setup.bash && \
    cd $CATKIN_WS && \
    rosdep install --from-paths src --ignore-src --rosdistro noetic -y && \
    catkin_make"

#--------------------------------------------------
# 4. 方便使用：開 bash 就自動 source ROS + workspace
#--------------------------------------------------
RUN echo 'source /opt/ros/noetic/setup.bash' >> /root/.bashrc && \
    echo 'source /root/catkin_ws/devel/setup.bash' >> /root/.bashrc

CMD [\"bash\"]
