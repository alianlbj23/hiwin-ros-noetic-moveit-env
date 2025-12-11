FROM osrf/ros:noetic-desktop-full

LABEL org.opencontainers.image.title="ros-noetic-moveit-hiwin"
LABEL org.opencontainers.image.description="ROS Noetic + MoveIt + HIWIN Robot Client Library + hiwin_ros"
LABEL maintainer="your_name <you@example.com>"

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F42ED6FBAB17C654 || \
    curl -sSL 'https://raw.githubusercontent.com/ros/rosdistro/master/ros.key' | apt-key add -


RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    python3-rosdep \
    \
    ros-noetic-moveit \
    ros-noetic-warehouse-ros-mongo \
    ros-noetic-pilz-industrial-motion-planner \
    \
    ros-noetic-industrial-core \
    ros-noetic-industrial-robot-client \
    ros-noetic-industrial-robot-status-interface \
    \
    mongodb \
 && rm -rf /var/lib/apt/lists/*

RUN rosdep update || (rosdep init && rosdep update)


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


ENV CATKIN_WS=/root/catkin_ws
RUN mkdir -p $CATKIN_WS/src

WORKDIR $CATKIN_WS/src
RUN git clone -b noetic-devel https://github.com/HIWINCorporation/hiwin_ros.git


WORKDIR $CATKIN_WS
RUN sed -i 's/ros::Time::MIN/ros::Time(0)/g' src/hiwin_ros/passthrough_controllers/src/pass_through_controllers.cpp


WORKDIR $CATKIN_WS
RUN /bin/bash -lc "source /opt/ros/noetic/setup.bash && \
    rosdep install --from-paths src --ignore-src --rosdistro noetic -y \
      --skip-keys 'industrial_robot_status_interface industrial_robot_status_controller hiwin_driver'"


RUN /bin/bash -lc "source /opt/ros/noetic/setup.bash && \
    cd $CATKIN_WS && \
    catkin_make"


RUN echo 'source /opt/ros/noetic/setup.bash' >> /root/.bashrc && \
    echo 'source /root/catkin_ws/devel/setup.bash' >> /root/.bashrc

CMD ["bash"]
