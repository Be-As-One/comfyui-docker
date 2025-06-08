#!/usr/bin/env bash
export PYTHONUNBUFFERED=1
cd /workspace/ComfyUI/comfyui-fastapi
source /workspace/ComfyUI/venv/bin/activate
echo "FASTAPI: Starting FastAPI"
python -m uvicorn main:app --host 0.0.0.0 --port 8001 > /workspace/logs/fastapi.log 2>&1 &
echo "FASTAPI: FastAPI Started"
deactivate
