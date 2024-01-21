FROM ubuntu:20.04

ARG COPPELIASIM_DOWNLOAD_LINK=https://downloads.coppeliarobotics.com/V4_1_0/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz
ARG XMEM_MODEL_LINK=https://github.com/hkchengrex/XMem/releases/download/v1.0/XMem.pth
ARG OWLV2_DOWNLOAD_REPO=https://huggingface.co/google/owlv2-large-patch14-ensemble
ARG SAM_VAE_DOWNLOAD_REPO=https://huggingface.co/facebook/sam-vit-huge
ARG RESNET18_MODEL_LINK=https://download.pytorch.org/models/resnet18-f37072fd.pth
ARG RESNET50_MODEL_LINK=https://download.pytorch.org/models/resnet50-0676ba61.pth

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
	apt-get update && \
	export DEBIAN_FRONTEND=noninteractive && \
    	apt-get update && \
    	apt-get install -y --no-install-recommends \
        wget vim gcc bash tar xz-utils git git-lfs \
        libx11-6 libxcb1 libxau6 libgl1-mesa-dev \
        xvfb dbus-x11 x11-utils libxkbcommon-x11-0 \
        libavcodec-dev libavformat-dev libswscale-dev \
        python3.9-full python3.9-dev build-essential libssl-dev libffi-dev python3-pip libraw1394-11 libmpfr6 \
        libusb-1.0-0 && \
    	apt-get autoclean -y && apt-get autoremove -y && apt-get clean && \
    	rm -rf /var/lib/apt/lists/* && \
    	ln -s /bin/python3.9 /bin/python && \
     	git lfs install

RUN mkdir -p /shared /opt /root/workspace /models /models/owlv2 /models/sam

# download CoppeliaSim and extract it to /opt

RUN wget -O /opt/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz $COPPELIASIM_DOWNLOAD_LINK && \
	tar -xf /opt/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz -C /opt && \
    	rm /opt/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz

ENV COPPELIASIM_ROOT=/opt/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$COPPELIASIM_ROOT
ENV QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT
ENV PATH=$COPPELIASIM_ROOT:$PATH

# clone the huggingface models repo
RUN git clone --depth 1 OWLV2_DOWNLOAD_REPO /models/owlv2 && \
    git clone --depth 1 SAN_VAE_DOWNLOAD_REPO /models/sam
# download xmem model, resnet18 and resnet50
RUN wget -O /models/xmem.pth $XMEM_MODEL_LINK && \
    wget -O /models/resnet18.pth $RESNET18_MODEL_LINK && \
    wget -O /models/resnet50.pth $RESNET50_MODEL_LINK

# set up python environment
# set pip mirror to Tsinghua University and upgrade pip
RUN python -m pip install --no-cache-dir --upgrade pip && python -m pip --no-cache-dir install open3d torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu113
# install other packages
RUN python -m pip --no-cache-dir install jupyter openai plotly transforms3d pyzmq cbor accelerate opencv-python-headless progressbar2 gdown gitpython git+https://github.com/cheind/py-thin-plate-spline hickle tensorboard transformers
# install PyRep and RLBench
RUN git clone https://github.com/stepjam/PyRep.git --depth 1 && cd PyRep && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    python -m pip install --no-cache-dir . && \
    cd .. && rm -rf PyRep
RUN git clone https://github.com/stepjam/RLBench.git --depth 1 && cd RLBench && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    python -m pip install --no-cache-dir . && \
    cd .. && rm -rf RLBench

WORKDIR /root/workspace

# RUN echo '#!/bin/bash\ncd $COPPELIASIM_ROOT_DIR\n/usr/bin/xvfb-run --server-args "-ac -screen 0, 1024x1024x24" coppeliaSim "$@"' > /entrypoint && chmod a+x /entrypoint

# Use following instead to open an application window via an X server:
# RUN echo '#!/bin/bash\ncd $COPPELIASIM_ROOT_DIR\n./coppeliaSim "$@"' > /entrypoint && chmod a+x /entrypoint

EXPOSE 23000-23500 80
# ENTRYPOINT ["/entrypoint"]
CMD [ "/bin/bash" ]
