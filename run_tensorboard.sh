#!/bin/bash

# Path to logs INSIDE the container (must start with /app)
LOGDIR=/app/output/blur_gs_opencv_25_13_2500_6000_abs_full_eval/default/MipNeRF/flowers/tb



# Port where TensorBoard will be available
PORT=6047
echo '[INFO] TensorBoard is running on http://localhost:'${PORT}

docker run -it --gpus all \
    -p ${PORT}:6007 \
    -v /home/vaia/ResGS:/app \
    resgs:latest \
    bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
              conda activate resgs && \
              tensorboard --logdir=${LOGDIR} --host=0.0.0.0 --port=6007"


echo '[INFO] TensorBoard session ended.'