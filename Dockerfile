FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PATH="/opt/conda/bin:${PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget build-essential cmake ninja-build g++ \
    libglew-dev libassimp-dev libboost-all-dev libgtk-3-dev libopencv-dev \
    libglfw3-dev libavdevice-dev libavcodec-dev libeigen3-dev libxxf86vm-dev \
    libembree-dev libtbb-dev libomp-dev ca-certificates ffmpeg curl python3-pip python3-dev \
    libgl1-mesa-glx libegl1-mesa libxrandr2 libxinerama1 libxcursor1 \
    libxi6 libxxf86vm1 libglu1-mesa xvfb mesa-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh

# Set Conda path
ENV PATH="/opt/conda/bin:${PATH}"

# Initialize conda for the shell session
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# Accept Anaconda Terms of Service
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r


# Clone the repository and initialize submodules first
WORKDIR /app
RUN git clone https://github.com/yanzhelyu/ResGS.git --recursive . && \
    git submodule update --init --recursive

# Create Conda Environment Manually and Install Dependencies
RUN conda create -n resgs python=3.9 pip=22.3.1 -y

# Install PyTorch and other dependencies separately
RUN conda install -n resgs pytorch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 pytorch-cuda=11.8 -c pytorch -c nvidia -y

# Install additional Python packages using pip
RUN conda run -n resgs pip install plyfile==0.8.1 tqdm opencv-python lpips colorama matplotlib pandas openpyxl
# Install numpy (version 1.23.x) and other dependencies
RUN conda install -n resgs numpy=1.23.5 -y
# Install TensorBoard
RUN conda run -n resgs pip install tensorboard
# Set the environment to use the conda environment by default
ENV PATH /opt/conda/envs/resgs/bin:$PATH
# Set the CUDA architecture flag
ENV TORCH_CUDA_ARCH_LIST="8.6" 

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cuda-toolkit-11-8 \
    gcc-11 \
    g++-11 \
    && apt-get clean


# Build and install the diff-gaussian-rasterization-abs submodule
WORKDIR /app/submodules/diff-gaussian-rasterization-abs
RUN conda run -n resgs pip install .
WORKDIR /app

# Install simple-knn similarly
WORKDIR /app/submodules/simple-knn
RUN conda run -n resgs pip install .
WORKDIR /app
# Set the shell to activate the conda environment

SHELL ["/bin/bash", "-c"]

RUN echo "source /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
RUN echo "conda activate resgs" >> ~/.bashrc
CMD ["bash"]