#!/bin/bash

# Path to logs INSIDE the container (must start with /app)
LOGDIR=/app/output/Blur_gs_opencv_25_13_abs_tb_2500_6000_single_train_grad_tb/bonsai/tb

# Port where TensorBoard will be available
PORT=6068
echo "[INFO] TensorBoard is running on http://localhost:${PORT}"
docker run -it --gpus all \
    -p ${PORT}:6006 \
    -v /home/vaia/ResGS:/app \
    resgs:latest \
    bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
              conda activate resgs && \
              tensorboard --logdir=${LOGDIR} --host=0.0.0.0 --port=6006"

