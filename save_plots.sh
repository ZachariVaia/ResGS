#!/bin/bash

# ---- CHECK ARGUMENT ----
if [ -z "$1" ]; then
    echo "Usage: ./save_plots.sh <path_to_run>"
    echo "Example:"
    echo "  ./save_plots.sh /home/vaia/ResGS/output/opencv_25_13_abs_tb_2000_5000/flowers"
    exit 1
fi

RUN_PATH_HOST="$1"
CONTAINER_RUN_PATH="/app/output"

echo ">>> Running plots for: $RUN_PATH_HOST"

docker run --rm -it --gpus all \
    -v /home/vaia/ResGS:/app \
    resgs:latest \
    bash -c "python3 /app/scripts/save_plots.py ${CONTAINER_RUN_PATH}"
