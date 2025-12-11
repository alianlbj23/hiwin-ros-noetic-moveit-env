FROM gramaziokohler/ros-noetic-moveit:20.12

LABEL org.opencontainers.image.title="ros-noetic-moveit-hiwin"
LABEL org.opencontainers.image.description="ROS Noetic + MoveIt + HIWIN Robot Client Library + hiwin_ros"
LABEL maintainer="your_name <you@example.com>"

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------
# 1. 修復 ROS apt GPG key（2024/2025 必須）
# ----------------------------------------------------
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F42ED6FBAB17C654 || \
    curl -sSL 'https://raw.githubusercontent.com/ros/rosdistro/master/ros.key' | apt-key add -

# ----------------------------------------------------
# 2. 基本工具 & ROS Industrial 依賴
# ----------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    python3-rosdep \
    ros-noetic-industrial-core \
    ros-noetic-industrial-robot-client \
    ros-noetic-industrial-robot-status-interface \
    # === 新增依賴修正 ===
    ros-noetic-warehouse-ros-mongo \
    ros-noetic-pilz-industrial-motion-planner \
    # ====================
 && rm -rf /var/lib/apt/lists/*

# rosdep 初始化
RUN rosdep update || (rosdep init && rosdep update)

# ----------------------------------------------------
# 3. 安裝 hiwin_robot_client_library (CMake)
# ----------------------------------------------------
WORKDIR /opt

RUN git clone https://github.com/HIWINCorporation/hiwin_robot_client_library.git \
 && cd hiwin_robot_client_library \
 && mkdir build && cd build \
 && cmake .. \
 && make -j"$(nproc)" \
 && make install \
 && ldconfig \
 && cd /opt/hiwin_robot_client_library \
 && rm -rf build

# ----------------------------------------------------
# 4. 建 catkin_ws 並 clone hiwin_ros（noetic-devel）
# ----------------------------------------------------
ENV CATKIN_WS=/root/catkin_ws
RUN mkdir -p $CATKIN_WS/src

# 切到 src 底下 clone hiwin_ros（放在 src/hiwin_ros）
WORKDIR $CATKIN_WS/src
RUN git clone -b noetic-devel https://github.com/HIWINCorporation/hiwin_ros.git

# ----------------------------------------------------
# 4.5. 修正 pass_through_controllers.cpp 編譯錯誤
# ----------------------------------------------------
WORKDIR $CATKIN_WS
# 替換錯誤的 ros::Time::MIN 為 ros::Time(0)，以解決 'MIN' is not a member of 'ros::Time' 錯誤
RUN sed -i 's/ros::Time::MIN/ros::Time(0)/g' src/hiwin_ros/passthrough_controllers/src/pass_through_controllers.cpp


# ----------------------------------------------------
# 5. rosdep 安裝依賴
# ----------------------------------------------------
WORKDIR $CATKIN_WS
# 執行 rosdep install，跳過無法解析的 industrial_* 鍵
RUN /bin/bash -lc "source /opt/ros/noetic/setup.bash && \
    rosdep install --from-paths src --ignore-src --rosdistro noetic -y --skip-keys 'industrial_robot_status_interface industrial_robot_status_controller hiwin_driver'"

# ----------------------------------------------------
# 6. catkin_make 編譯
# ----------------------------------------------------
# 拆分成 cmake 和 make 以便於控制日誌輸出
RUN /bin/bash -lc -e "source /opt/ros/noetic/setup.bash && \
    cmake src -DCATKIN_DEVEL_PREFIX=devel -DCMAKE_INSTALL_PREFIX=install -G 'Unix Makefiles' && \
    make -j$(nproc)"

# ----------------------------------------------------
# 7. bash 自動 source ROS + workspace
# ----------------------------------------------------
RUN echo 'source /opt/ros/noetic/setup.bash' >> /root/.bashrc && \
    echo 'source /root/catkin_ws/devel/setup.bash' >> /root/.bashrc

CMD ["bash"]