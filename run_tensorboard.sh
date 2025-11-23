#!/bin/bash

# Path to logs INSIDE the container (must start with /app)
LOGDIR=/app/output//resgs_abs_tb_single_train/flowers/tb

# Port where TensorBoard will be available
PORT=6010

docker run -it --gpus all \
    -p ${PORT}:6006 \
    -v /home/vaia/ResGS:/app \
    resgs:latest \
    bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
              conda activate resgs && \
              tensorboard --logdir=${LOGDIR} --host=0.0.0.0 --port=6006"

echo "[INFO] TensorBoard is running on http://localhost:${PORT}"
