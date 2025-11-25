#!/usr/bin/env bash
set -euo pipefail

# ====== FIX PERMISSIONS OUTSIDE ======
sudo mkdir -p /home/vaia/ResGS/output
sudo chown -R vaia:vaia /home/vaia/ResGS/output
sudo chmod -R u+rwX /home/vaia/ResGS/output

# ====== PATHS ======
DATASET_PATH="${DATASET_PATH:-/home/vaia/ResGS/data}"
SAVE_PATH="${SAVE_PATH:-/home/vaia/ResGS/output/resgs_2500_6000_3dgs_full_eval_last}"

# ====== RUN DOCKER ======
docker run -it --rm --gpus all \
 --env CUDA_VISIBLE_DEVICES=1 \
  -v /home/vaia/ResGS:/app \
  -v /home/vaia/ResGS/data:/app/data \
  -v /home/vaia/ResGS/output:/app/output \
  resgs:latest \
  bash -lc "
      echo '[INFO] Running RESGS...'
      python -u /app/script.py \
        --eval \
        --dataset_path /app/data \
        --save_path /app/output/resgs_2500_6000_3dgs_full_eval_last ;

      # ===== FIX PERMISSIONS INSIDE CONTAINER =====
      chown -R 1000:1000 /app/output
  "
