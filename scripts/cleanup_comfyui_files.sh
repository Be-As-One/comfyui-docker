#!/usr/bin/env bash

# ComfyUI file cleanup script
# Cleans up old files from input and output directories across all environments

# Configuration from environment variables
INPUT_MINUTES=${INPUT_CLEANUP_MINUTES:-1}
OUTPUT_MINUTES=${OUTPUT_CLEANUP_MINUTES:-60}

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to clean directory
clean_directory() {
    local dir=$1
    local minutes=$2
    local type=$3
    
    if [ -d "$dir" ]; then
        # Count files before cleanup
        local count_before=$(find "$dir" -type f -mmin +$minutes 2>/dev/null | wc -l)
        
        if [ $count_before -gt 0 ]; then
            # Perform cleanup
            find "$dir" -type f -mmin +$minutes -delete 2>/dev/null
            
            # Extract environment name from path
            local env_name=$(echo "$dir" | grep -oP 'ComfyUI-\K[^/]+')
            
            log_message "Cleaned $count_before files from $type directory (environment: $env_name)"
        fi
    fi
}

# Main cleanup process
log_message "Starting ComfyUI file cleanup"

# Clean input directories (default: 1 minute old files)
for dir in /workspace/ComfyUI-*/input; do
    clean_directory "$dir" "$INPUT_MINUTES" "input"
done

# Clean output directories (default: 60 minutes old files)  
for dir in /workspace/ComfyUI-*/output; do
    clean_directory "$dir" "$OUTPUT_MINUTES" "output"
done

log_message "Cleanup completed"