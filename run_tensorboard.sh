# #!/bin/bash

# Path to logs INSIDE the container (must start with /app)
LOGDIR=/app/output/resgs_2500_6000_abss_full_eval/default/MipNeRF/flowers/tb
# LOGDIR=/app/output/blur_gs_2500_6000_abss_full_eval/default/MipNeRF/flowers/tb
# LOGDIR=/app/output/multires_2500_6000_abss_full_eval/default/MipNeRF/flowers/tb


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


# LOGDIR_A=/app/output/resgs_2500_6000_abss_full_eval/default/MipNeRF/flowers/tb
# LOGDIR_B=/app/output/blurgs_2500_6000_abss_full_eval/default/MipNeRF/flowers/tb
# LOGDIR_C=/app/output/multires_2500_6000_abss_full_eval/default/MipNeRF/flowers/tb
# PORT=6080

# docker run -it --gpus all \
#   -p ${PORT}:6006 \
#   -v /home/vaia/ResGS:/app \
#   resgs:latest \
#   bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
#             conda activate resgs && \
#             tensorboard \
#             --logdir=resgs:${LOGDIR_A},blurgs:${LOGDIR_B},multires:${LOGDIR_C} \
#             --host=0.0.0.0 \
#             --port=6006"

# echo '[INFO] TensorBoard is running on http://localhost:'${PORT}
