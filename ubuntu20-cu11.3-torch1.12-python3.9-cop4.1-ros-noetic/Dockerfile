# syntax = docker/dockerfile:1.5
FROM ubuntu:20.04

RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list &&\
    apt-get update && \
	export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget vim gcc bash unzip tar xz-utils git \
        libx11-6 libxcb1 libxau6 libgl1-mesa-dev \
        xvfb dbus-x11 x11-utils libxkbcommon-x11-0 \
        libavcodec-dev libavformat-dev libswscale-dev \
        python3.9-full python3.9-dev build-essential libssl-dev libffi-dev python3-pip libraw1394-11 libmpfr6 \
        libusb-1.0-0 \
        && \
    apt-get autoclean -y && apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2

RUN mkdir -p /shared /opt /root/workspace /models
# download CoppeliaSim and extract it to /opt
ADD download/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz /opt
# copy the huggingface models repo
ADD download/models.tar.gz /models

# set up python environment
# set pip mirror to Tsinghua University and upgrade pip
RUN python -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

ENV COPPELIASIM_ROOT=/opt/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$COPPELIASIM_ROOT
ENV QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT
ENV PATH=$COPPELIASIM_ROOT:$PATH

# install ROS noetic-base
# setup timezone
# RUN echo 'Etc/UTC' > /etc/timezone && \
    # ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
RUN apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ focal main" > /etc/apt/sources.list.d/ros1-latest.list

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ENV ROS_DISTRO noetic
ENV ROSDISTRO_INDEX_URL https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-core=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install --no-install-recommends -y \
    python3-rosdep \
    python3-rosinstall \
    python3-vcstools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# bootstrap rosdep
RUN mkdir -p /etc/ros/rosdep/sources.list.d/ && \
  wget http://mirrors.tuna.tsinghua.edu.cn/github-raw/ros/rosdistro/master/rosdep/sources.list.d/20-default.list -O /etc/ros/rosdep/sources.list.d/20-default.list
ENV SSL_CERT_FILE /usr/lib/ssl/certs/ca-certificates.crt
RUN rosdep update --rosdistro $ROS_DISTRO
# RUN rosdep init && \
#   rosdep update --rosdistro $ROS_DISTRO

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-base=1.5.0-1* \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

RUN --mount=type=cache,target=/root/.cache \
    python -m pip install --upgrade pip && \
    python -m pip install --ignore-installed torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu113 jupyter openai plotly transforms3d open3d pyzmq cbor accelerate opencv-python-headless progressbar2 gdown gitpython git+https://github.com/cheind/py-thin-plate-spline hickle tensorboard transformers

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-image-transport ros-noetic-tf \
    && rm -rf /var/lib/apt/lists/*

# install PyRep and RLBench
RUN --mount=type=cache,target=/root/.cache \
    git clone https://github.com/stepjam/PyRep.git --depth 1 && \
    cd PyRep && \
    python -m pip install -r requirements.txt && \
    python -m pip install . && \
    cd .. && rm -rf PyRep  && \
    git clone https://github.com/stepjam/RLBench.git --depth 1 && \
    cd RLBench && \
    python -m pip install -r requirements.txt && \
    python -m pip install . && \
    cd .. && rm -rf RLBench

WORKDIR /root/workspace

# RUN echo '#!/bin/bash\ncd $COPPELIASIM_ROOT_DIR\n/usr/bin/xvfb-run --server-args "-ac -screen 0, 1024x1024x24" coppeliaSim "$@"' > /entrypoint && chmod a+x /entrypoint

# Use following instead to open an application window via an X server:
# RUN echo '#!/bin/bash\ncd $COPPELIASIM_ROOT_DIR\n./coppeliaSim "$@"' > /entrypoint && chmod a+x /entrypoint

# EXPOSE 23000-23050 80
# ENTRYPOINT ["/entrypoint"]
CMD [ "/bin/bash" ]