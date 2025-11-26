#!/usr/bin/env bash
set -euo pipefail
# ====== FIX PERMISSIONS OUTSIDE ======
sudo mkdir -p /home/vaia/ResGS/output
sudo chown -R vaia:vaia /home/vaia/ResGS/output
sudo chmod -R u+rwX /home/vaia/ResGS/output
# ====================================================
# CONFIG
# ====================================================
DATASET="/home/vaia/ResGS/data"
OUTPUT="/home/vaia/ResGS/output"
RUN_NAME="resgs_abs_tb_single_train_grads_total_501/bonsai"
RUN_PATH="${OUTPUT}/${RUN_NAME}"
IMAGE_MODE="images_2"

# ====================================================
# CREATE OUTPUT STRUCTURE
# ====================================================
echo "[INFO] Ensuring run directory exists: ${RUN_PATH}"
mkdir -p "${RUN_PATH}"

if [ ! -f "${RUN_PATH}/cfg_args" ]; then
    echo "[INFO] Creating missing cfg_args file."
    touch "${RUN_PATH}/cfg_args"
fi


# ====================================================
# FIND FREE PORT
# ====================================================
find_free_port() {
    for port in $(seq 6000 7000); do
        # 1) check if OS allows it
        if ! lsof -i:"$port" >/dev/null 2>&1; then
            # 2) check if Docker can reserve it
            if docker run --rm -p ${port}:6006 alpine true >/dev/null 2>&1; then
                echo "$port"
                return
            fi
        fi
    done
    return 1
}


TB_PORT=$(find_free_port)

if [ -z "${TB_PORT}" ]; then
    echo "[ERROR] No free ports between 6000–7000!"
    exit 1
fi

# ====================================================
# START TENSORBOARD
# ====================================================
echo "[INFO] Starting TensorBoard on http://localhost:${TB_PORT} ..."

docker run -d --rm --gpus all \
 --env CUDA_VISIBLE_DEVICES=0 \
  -p ${TB_PORT}:6006 \
  -v /home/vaia/ResGS:/app \
  resgs:latest \
  bash -lc "source /opt/conda/etc/profile.d/conda.sh && \
            conda activate resgs && \
            tensorboard --logdir /app/output/${RUN_NAME}/tb \
                        --host 0.0.0.0 --port 6006"

echo "[INFO] TensorBoard running on port ${TB_PORT}"


# ====================================================
# TRAINING
# ====================================================
echo
echo "================ RUNNING TRAINING ================"

docker run -it --rm --gpus all \
 --env CUDA_VISIBLE_DEVICES=0 \
  -v /home/vaia/ResGS:/app \
  resgs:latest \
  bash -lc "python -u /app/train.py \
      --eval \
      --source_path /app/data/MipNeRF/bonsai \
      --images ${IMAGE_MODE} \
      --model_path /app/output/${RUN_NAME}"


# ====================================================
# RENDERING
# ====================================================
echo
echo "================ RUNNING RENDER ================"

docker run -it --rm --gpus all \
 --env CUDA_VISIBLE_DEVICES=0 \
  -v /home/vaia/ResGS:/app \
  resgs:latest \
  bash -lc "python -u /app/render.py \
      --model_path /app/output/${RUN_NAME} \
      --skip_train"


# ====================================================
# METRICS
# ====================================================
echo
echo "================ RUNNING METRICS ================"

docker run -it --rm --gpus all \
 --env CUDA_VISIBLE_DEVICES=0 \
  -v /home/vaia/ResGS:/app \
  resgs:latest \
  bash -lc "python -u /app/metrics.py \
      --model_path /app/output/${RUN_NAME}"


# ====================================================
echo
echo "[DONE] Training + Rendering + Metrics complete."
echo "TensorBoard: http://localhost:${TB_PORT}"
echo "Outputs saved in: ${RUN_PATH}"
