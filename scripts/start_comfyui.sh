#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

# Parse command line arguments
INSTANCE_ID=${1:-0}
EXTRA_ARGS=${2:-""}

# Environment configuration (defaults to comm)
COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT:-"comm"}
COMFYUI_DIR="/workspace/ComfyUI-${COMFYUI_ENVIRONMENT}"

# Instance configuration
INSTANCE_PORT=${INSTANCE_PORT:-$((${COMFYUI_BASE_PORT:-3001} + INSTANCE_ID))}
INSTANCE_NAME=${INSTANCE_NAME:-"instance_${INSTANCE_ID}"}

# Calculate instance-specific values
LOG_FILE="/workspace/logs/comfyui_instance_${INSTANCE_ID}.log"

# Ensure logs directory exists
mkdir -p "/workspace/logs"

# Check if environment is installed, install if not
if [[ ! -d "${COMFYUI_DIR}" || ! -f "${COMFYUI_DIR}/main.py" ]]; then
    echo "COMFYUI: Environment ${COMFYUI_ENVIRONMENT} not found. Installing..."
    /install_comfyui_env.py "${COMFYUI_ENVIRONMENT}"
    
    if [[ $? -ne 0 ]]; then
        echo "COMFYUI: ERROR - Failed to install environment ${COMFYUI_ENVIRONMENT}"
        exit 1
    fi
fi

# Verify ComfyUI directory exists after installation
if [[ ! -d "${COMFYUI_DIR}" ]]; then
    echo "COMFYUI: ERROR - ComfyUI directory not found: ${COMFYUI_DIR}"
    exit 1
fi

echo "COMFYUI: Using ComfyUI directory: ${COMFYUI_DIR}"

cd "${COMFYUI_DIR}"
source venv/bin/activate

echo "COMFYUI: Starting ComfyUI Instance '${INSTANCE_NAME}' (ID: ${INSTANCE_ID}) on port ${INSTANCE_PORT}"
echo "COMFYUI: Environment: ${COMFYUI_ENVIRONMENT}"
echo "COMFYUI: Log file: ${LOG_FILE}"

TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Build the command with all arguments
CMD="python3 main.py --listen 0.0.0.0 --port ${INSTANCE_PORT} ${EXTRA_ARGS}"
echo "COMFYUI: Executing: ${CMD}"

# Start ComfyUI instance
eval ${CMD} > "${LOG_FILE}" 2>&1 &
COMFYUI_PID=$!

echo "COMFYUI: ComfyUI Instance '${INSTANCE_NAME}' (ID: ${INSTANCE_ID}) Started (PID: ${COMFYUI_PID})"
echo "${COMFYUI_PID}" > "/workspace/logs/comfyui_instance_${INSTANCE_ID}.pid"

deactivate
