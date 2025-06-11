#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
echo "Starting FastAPI service..."

# Ensure logs directory exists
mkdir -p /workspace/logs

# Navigate to FastAPI directory and activate venv
cd /workspace/ComfyUI/comfyui-fastapi
source /workspace/ComfyUI/venv/bin/activate

# Start FastAPI using nohup
nohup python main.py --host 0.0.0.0 --port 8001 > /workspace/logs/fastapi.log 2>&1 &

echo "FastAPI started on port 8001"
echo "FastAPI log file: /workspace/logs/fastapi.log"

deactivate
