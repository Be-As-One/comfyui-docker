#!/usr/bin/env bash

# Enhanced ComfyUI stop script
# Usage: stop_comfyui.sh [port|all|instance <id>|help]

PID_DIR="/workspace/logs"

# Function to stop all instances
stop_all_instances() {
    echo "STOP: Stopping all ComfyUI instances..."
    
    # Stop by PID files
    for pid_file in "${PID_DIR}"/comfyui_instance_*.pid; do
        if [[ -f "${pid_file}" ]]; then
            pid=$(cat "${pid_file}")
            instance_id=$(basename "${pid_file}" .pid | sed 's/comfyui_instance_//')
            
            if kill -0 "${pid}" 2>/dev/null; then
                echo "STOP: Stopping instance ${instance_id} (PID: ${pid})"
                kill "${pid}"
            fi
            rm -f "${pid_file}"
        fi
    done
    
    # Also kill any remaining ComfyUI processes
    pkill -f "main.py.*--listen" 2>/dev/null || true
    echo "STOP: All ComfyUI instances stopped"
}

# Function to stop by port
stop_by_port() {
    local port=$1
    echo "STOP: Stopping ComfyUI on port ${port}..."
    
    # Kill process using the port
    fuser -k "${port}/tcp" 2>/dev/null || true
    
    # Also check PID files for this port
    for pid_file in "${PID_DIR}"/comfyui_instance_*.pid; do
        if [[ -f "${pid_file}" ]]; then
            pid=$(cat "${pid_file}")
            if kill -0 "${pid}" 2>/dev/null; then
                # Check if this process is using the target port
                if lsof -p "${pid}" 2>/dev/null | grep -q ":${port}"; then
                    instance_id=$(basename "${pid_file}" .pid | sed 's/comfyui_instance_//')
                    echo "STOP: Stopping instance ${instance_id} (PID: ${pid}) on port ${port}"
                    kill "${pid}"
                    rm -f "${pid_file}"
                fi
            else
                # Remove stale PID file
                rm -f "${pid_file}"
            fi
        fi
    done
}

# Function to stop by instance ID
stop_by_instance() {
    local instance_id=$1
    local pid_file="${PID_DIR}/comfyui_instance_${instance_id}.pid"
    
    if [[ -f "${pid_file}" ]]; then
        pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            echo "STOP: Stopping instance ${instance_id} (PID: ${pid})"
            kill "${pid}"
        fi
        rm -f "${pid_file}"
        echo "STOP: Instance ${instance_id} stopped"
    else
        echo "STOP: Instance ${instance_id} is not running or PID file not found"
    fi
}

# Function to show status
show_status() {
    echo "STOP: ComfyUI Instance Status:"
    
    found_instances=false
    
    for pid_file in "${PID_DIR}"/comfyui_instance_*.pid; do
        if [[ -f "${pid_file}" ]]; then
            found_instances=true
            pid=$(cat "${pid_file}")
            instance_id=$(basename "${pid_file}" .pid | sed 's/comfyui_instance_//')
            
            if kill -0 "${pid}" 2>/dev/null; then
                # Get port from process
                port=$(lsof -p "${pid}" 2>/dev/null | grep LISTEN | grep -o ':[0-9]*' | head -1 | tr -d ':')
                echo "  Instance ${instance_id}: RUNNING (PID: ${pid}, Port: ${port:-unknown})"
            else
                echo "  Instance ${instance_id}: DEAD (cleaning up PID file)"
                rm -f "${pid_file}"
            fi
        fi
    done
    
    if [[ "${found_instances}" == "false" ]]; then
        echo "  No ComfyUI instances found"
    fi
}

# Handle command line arguments
case "${1:-help}" in
    all)
        stop_all_instances
        ;;
    
    instance)
        if [[ -z "$2" ]]; then
            echo "STOP: ERROR - Instance ID required"
            echo "Usage: $0 instance <instance_id>"
            exit 1
        fi
        stop_by_instance "$2"
        ;;
    
    status)
        show_status
        ;;
    
    help)
        echo "STOP: ComfyUI Stop Script"
        echo ""
        echo "Usage: $0 [port|all|instance <id>|status|help]"
        echo ""
        echo "Commands:"
        echo "  all                      - Stop all running instances"
        echo "  <port>                   - Stop instance running on specific port"
        echo "  instance <id>            - Stop specific instance by ID"
        echo "  status                   - Show status of all instances"
        echo "  help                     - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 all                   # Stop all instances"
        echo "  $0 3001                  # Stop instance on port 3001"
        echo "  $0 instance 0            # Stop instance with ID 0"
        ;;
    
    [0-9]*)
        # Numeric argument treated as port
        stop_by_port "$1"
        ;;
    
    *)
        # Default behavior: stop all instances (backward compatibility)
        stop_all_instances
        ;;
esac
