#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

# Environment configuration (defaults to comm)
COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT:-"comm"}
COMFYUI_DIR="/workspace/ComfyUI-${COMFYUI_ENVIRONMENT}"

# Check if ComfyUI directory exists
if [ ! -d "${COMFYUI_DIR}" ]; then
    echo "FASTAPI: ComfyUI directory not found: ${COMFYUI_DIR}"
    echo "FASTAPI: Skipping FastAPI startup"
    exit 0
fi

# Check if FastAPI is installed
if [ ! -d "${COMFYUI_DIR}/comfyui-fastapi" ]; then
    echo "FASTAPI: comfyui-fastapi not found in ${COMFYUI_DIR}"
    echo "FASTAPI: Skipping FastAPI startup"
    exit 0
fi

cd "${COMFYUI_DIR}/comfyui-fastapi"

# Check if venv exists
if [ -f "${COMFYUI_DIR}/venv/bin/activate" ]; then
    source "${COMFYUI_DIR}/venv/bin/activate"
    echo "FASTAPI: Starting FastAPI"
    python main.py > /workspace/logs/fastapi.log 2>&1 &
    echo "FASTAPI: FastAPI Started"
    deactivate
else
    echo "FASTAPI: Virtual environment not found at ${COMFYUI_DIR}/venv"
    echo "FASTAPI: Skipping FastAPI startup"
fi
