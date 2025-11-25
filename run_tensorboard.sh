#!/bin/bash

# Path to logs INSIDE the container (must start with /app)
LOGDIR=/app/output/blurgs_opencv_25_13_2500_6000_abs_tb_full_eval/default/MipNeRF/garden/tb

# Port where TensorBoard will be available
PORT=6059

docker run -it --gpus all \
    -p ${PORT}:6006 \
    -v /home/vaia/ResGS:/app \
    resgs:latest \
    bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
              conda activate resgs && \
              tensorboard --logdir=${LOGDIR} --host=0.0.0.0 --port=6006"

echo "[INFO] TensorBoard is running on http://localhost:${PORT}"
