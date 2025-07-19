#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

# Check if first argument is 'status'
if [[ "$1" == "status" ]]; then
    echo "=== FaceFusion Instance Status ==="
    echo ""
    PID_FILE="/workspace/logs/facefusion.pid"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            PORT=3005  # Default FaceFusion port
            echo "FaceFusion: Running (PID: $PID, Port: $PORT)"
        else
            echo "FaceFusion: Not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "FaceFusion: Not running"
    fi
    exit 0
fi

# Environment configuration
FACEFUSION_ENVIRONMENT="${FACEFUSION_ENVIRONMENT:-facefusion}"

# Instance configuration
ENV_CONFIG="/config/environments/${FACEFUSION_ENVIRONMENT}/config.json"
if [ -f "${ENV_CONFIG}" ]; then
    FACEFUSION_PORT=$(python3 -c "import json; print(json.load(open('${ENV_CONFIG}'))['port'])")
    echo "Using port ${FACEFUSION_PORT} from environment config: ${FACEFUSION_ENVIRONMENT}"
else
    # Fallback to default port
    FACEFUSION_PORT=3005
    echo "Environment config not found, using default port: ${FACEFUSION_PORT}"
fi

# Log file configuration
LOG_FILE="/workspace/logs/facefusion.log"

# Ensure logs directory exists
mkdir -p "/workspace/logs"

# Check if FaceFusion is properly installed
if [[ ! -d "/facefusion" ]]; then
    echo "FACEFUSION: ERROR - FaceFusion not found at /facefusion"
    echo "FACEFUSION: Please ensure FaceFusion is properly installed during Docker build"
    exit 1
fi

# Check if micromamba environment exists
if ! micromamba env list | grep -q "^facefusion "; then
    echo "FACEFUSION: ERROR - Micromamba environment 'facefusion' not found"
    echo "FACEFUSION: Please ensure the FaceFusion environment is created during Docker build"
    exit 1
fi

echo "FACEFUSION: FaceFusion installation verified"

# Check if the FastAPI handler exists in FaceFusion directory
FASTAPI_HANDLER="/facefusion/fastapi_handler.py"
if [[ ! -f "${FASTAPI_HANDLER}" ]]; then
    echo "FACEFUSION: ERROR - FastAPI handler not found: ${FASTAPI_HANDLER}"
    echo "FACEFUSION: Please ensure FaceFusion is properly installed with FastAPI handler"
    exit 1
fi

echo "FACEFUSION: Using FastAPI handler: ${FASTAPI_HANDLER}"
echo "FACEFUSION: Starting FaceFusion service on port ${FACEFUSION_PORT}"
echo "FACEFUSION: Log file: ${LOG_FILE}"

# Activate the micromamba environment for FaceFusion
eval "$(micromamba shell hook --shell bash)"
micromamba activate facefusion

# Set environment variables for FaceFusion
export FACEFUSION_PORT=${FACEFUSION_PORT}
export FACEFUSION_HOST="0.0.0.0"

# Change to the FaceFusion directory to run the handler
cd "/facefusion"

# Start FaceFusion FastAPI service
CMD="python3 ${FASTAPI_HANDLER}"
echo "FACEFUSION: Executing: ${CMD}"

# Start FaceFusion instance
eval ${CMD} > "${LOG_FILE}" 2>&1 &
FACEFUSION_PID=$!

echo "FACEFUSION: FaceFusion service started (PID: ${FACEFUSION_PID})"
echo "${FACEFUSION_PID}" > "/workspace/logs/facefusion.pid"

# Deactivate micromamba environment
micromamba deactivate