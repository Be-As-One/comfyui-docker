#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

# Check if first argument is 'status'
if [[ "$1" == "status" ]]; then
    echo "=== ComfyUI Instance Status ==="
    echo ""
    found=0
    for i in {0..9}; do
        PID_FILE="/workspace/logs/comfyui_instance_${i}.pid"
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                PORT=$((3001 + i))
                # Get environment from process
                ENV_DIR=$(ps -p "$PID" -o args= | grep -oP '/workspace/ComfyUI-\K[^/]+' || echo "unknown")
                echo "Instance $i: Running (PID: $PID, Port: $PORT, Environment: $ENV_DIR)"
                found=1
            fi
        fi
    done
    if [ $found -eq 0 ]; then
        echo "No ComfyUI instances are currently running."
    fi
    exit 0
fi

# Parse command line arguments
INSTANCE_ID=${1:-0}
EXTRA_ARGS=${2:-""}

# Environment configuration (defaults to comm)
COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT:-"comm"}
COMFYUI_DIR="/workspace/ComfyUI-${COMFYUI_ENVIRONMENT}"

# Instance configuration
# Read port from environment configuration file
ENV_CONFIG="/config/environments/${COMFYUI_ENVIRONMENT}.json"
if [ -f "${ENV_CONFIG}" ]; then
    BASE_PORT=$(python3 -c "import json; print(json.load(open('${ENV_CONFIG}'))['port'])")
    echo "Using port ${BASE_PORT} from environment config: ${COMFYUI_ENVIRONMENT}"
else
    # Fallback to default port
    BASE_PORT=${COMFYUI_BASE_PORT:-3001}
    echo "Environment config not found, using default port: ${BASE_PORT}"
fi

INSTANCE_PORT=${INSTANCE_PORT:-$((BASE_PORT + INSTANCE_ID))}
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
