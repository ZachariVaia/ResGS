#!/bin/bash

# Path to logs INSIDE the container (must start with /app)
LOGDIR=/app/output/multi_res_scale_opencv_7_5_abs_tb_2500_6000_until_16000_single_train_grads_599_fixed_thres/bonsai/tb



# Port where TensorBoard will be available
PORT=6089
echo '[INFO] TensorBoard is running on http://localhost:'${PORT}

docker run -it --gpus all \
    -p ${PORT}:6007 \
    -v /home/vaia/ResGS:/app \
    resgs:latest \
    bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
              conda activate resgs && \
              tensorboard --logdir=${LOGDIR} --host=0.0.0.0 --port=6007"


echo '[INFO] TensorBoard session ended.'