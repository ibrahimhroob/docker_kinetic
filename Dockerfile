FROM nvidia/cudagl:11.2.2-base-ubuntu16.04

# Config
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV ROS_DISTRO kinetic

# Minimal setup
RUN apt-get update && apt-get install -y locales lsb-release
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg-reconfigure locales

# Install ROS
RUN rm /etc/apt/sources.list.d/* && \
    DEBIAN_FRONTEND=noninteractive apt update --no-install-recommends && \
    DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common lsb-release curl wget apt-transport-https git tmux nano htop net-tools --no-install-recommends
RUN rm -rf /var/lib/apt/lists/* && \
    echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y ros-${ROS_DISTRO}-catkin ros-${ROS_DISTRO}-desktop-full ros-${ROS_DISTRO}-vision-msgs ros-${ROS_DISTRO}-cv-bridge python3-catkin-tools python-pip python-rosdep python-rosinstall --no-install-recommends && \
    rosdep init && rosdep update
RUN echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc

# install some missing libraries 
RUN apt-get update && apt-get install -y libgl1-mesa-glx
RUN apt-get install -y libglew-dev
RUN apt-get install -y autotools-dev
RUN apt-get install -y autoconf
RUN apt-get install -y libtool
RUN apt-get install -y build-essential pkg-config

# ros libraries 
RUN apt-get install -y ros-kinetic-octomap*

ARG UNAME=baseline
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
RUN echo 'baseline:baseline' | chpasswd
RUN adduser $UNAME sudo
WORKDIR /home/$UNAME
#RUN cp -r /ros_ws /home/lcastor
#RUN chown -R $UNAME:$UNAME /home/lcastor/ros_ws
#RUN chmod 755 /home/lcastor/ros_ws
#RUN echo "source /home/lcastor/ros_ws/devel/setup.bash" >> /home/lcastor/.bashrc
USER $UNAME
#RUN cd /home/lcastor/ros_ws; . /opt/ros/${ROS_DISTRO}/setup.sh; catkin build

# Create entrypoint for image
COPY entrypoint.sh .
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

#update gcc and cmake 
RUN echo "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu xenial main" >> /etc/apt/sources.list.d/ppa-test.list
RUN echo "deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu xenial main" >> /etc/apt/sources.list.d/ppa-test.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F
RUN apt-get -qq update && apt-get install -y --no-install-recommends gcc-7 g++-7
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7
RUN update-alternatives --config gcc
RUN gcc --version

#cmake
RUN cd /home
RUN wget https://cmake.org/files/v3.13/cmake-3.13.0-Linux-x86_64.tar.gz
RUN tar -xzvf cmake-3.13.0-Linux-x86_64.tar.gz
RUN rm cmake-3.13.0-Linux-x86_64.tar.gz
RUN mv cmake-3.13.0-Linux-x86_64 /opt/cmake-3.13.0
RUN ln -sf /opt/cmake-3.13.0/bin/*  /usr/bin/
RUN cmake --version

#gtest
RUN cd /home && \
    git clone https://github.com/google/googletest.git -b release-1.10.0 && \
    cd googletest && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install


# Abseil
RUN cd /home && \
    git clone https://github.com/abseil/abseil-cpp.git && \
    cd abseil-cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install


# libnabo
RUN cd /home && \
    git clone https://github.com/ethz-asl/libnabo && \
    cd libnabo && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make && \
    make install

# long-term localization package 
RUN cd /home && \
    git clone https://github.com/HITSZ-NRSL/long-term-localization.git && \
    cd long-term-localization/src && \
    git clone https://github.com/lisilin013/third_parities.git && \
    cd .. && \
    catkin build
