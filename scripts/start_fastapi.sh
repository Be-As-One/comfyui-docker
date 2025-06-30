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

# Use the centralized FastAPI code
FASTAPI_DIR="/workspace/comfyui-fastapi"

# Check if FastAPI code is available
if [ ! -d "${FASTAPI_DIR}" ]; then
    echo "FASTAPI: FastAPI code not found at ${FASTAPI_DIR}"
    echo "FASTAPI: Skipping FastAPI startup"
    exit 0
fi

cd "${FASTAPI_DIR}"

# Check if venv exists
if [ -f "${COMFYUI_DIR}/venv/bin/activate" ]; then
    source "${COMFYUI_DIR}/venv/bin/activate"
    
    # Set environment variables for multi-environment support
    export DEFAULT_ENV=${COMFYUI_ENVIRONMENT}
    export COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT}
    
    echo "FASTAPI: Starting FastAPI for environment: ${COMFYUI_ENVIRONMENT}"
    python main.py > /workspace/logs/fastapi-${COMFYUI_ENVIRONMENT}.log 2>&1 &
    echo "FASTAPI: FastAPI Started for environment: ${COMFYUI_ENVIRONMENT}"
    deactivate
else
    echo "FASTAPI: Virtual environment not found at ${COMFYUI_DIR}/venv"
    echo "FASTAPI: Skipping FastAPI startup"
fi
