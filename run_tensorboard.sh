# !/bin/bash

# # Path to logs INSIDE the container (must start with /app)
# LOGDIR=blur_gs_opencv_25_13_2500_6000_abs_full_eval/default/MipNeRF/bicycle
# LOGDIR=multi_res_scale_opencv_25_13_2500_6000_abs_tb_full_eval/default/MipNeRF/bicycle
LOGDIR=resgs_2500_6000_abs_full_eval/default/MipNeRF/bicycle

# Port where TensorBoard will be available
PORT=6011


docker run -d --rm --gpus all \
 --env CUDA_VISIBLE_DEVICES=2 \
  -p ${PORT}:6006 \
  -v /home/vaia/ResGS:/app \
  resgs:latest \
  bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
            conda activate resgs && \
            tensorboard --logdir /app/output/${LOGDIR}/tb \
                        --host 0.0.0.0 --port 6006"

echo "[INFO] TensorBoard is running on http://localhost:${PORT}"

