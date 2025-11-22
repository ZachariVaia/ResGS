#!/usr/bin/env bash
set -euo pipefail

# Set ownership and permissions for output directory
sudo mkdir -p /home/vaia/ResGS/output
sudo chown -R vaia:vaia /home/vaia/ResGS/output
sudo chmod -R u+rwX /home/vaia/ResGS/output

# ====== PATHS ======
DATASET_PATH="${DATASET_PATH:-/home/vaia/ResGS/data}"
SAVE_PATH="${SAVE_PATH:-/home/vaia/ResGS/output/opencv_13_7}"

# ====== Docker Command ======
docker run -it --rm --gpus all --entrypoint bash \
  -v /home/vaia/ResGS:/app \
  -v /home/vaia/ResGS/data:/app/data \
  -v /home/vaia/ResGS/output:/app/output \
  resgs:latest \
  -lc "python -u /app/scripts/excel_metrics_with_ngs.py --eval_dir /app/output/opencv_37_13_3dgs"

