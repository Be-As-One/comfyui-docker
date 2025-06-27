# ComfyUI Multi-Instance Usage Guide

## Overview
This system supports running multiple ComfyUI instances with flexible port assignment through configuration files. Perfect for GPU environments where you need multiple ComfyUI instances on different ports.

## Configuration File

The system uses `instances.json` configuration file located in the root directory (`/instances.json`). This file defines all instances with their specific settings.

### Configuration Format
```json
{
  "instances": [
    {
      "id": 0,
      "port": 3001,
      "name": "comfyui-main",
      "description": "Main ComfyUI instance",
      "extra_args": "",
      "enabled": true
    },
    {
      "id": 1,
      "port": 3005,
      "name": "comfyui-backup",
      "description": "Backup ComfyUI instance",
      "extra_args": "",
      "enabled": true
    }
  ],
  "global_settings": {
    "log_directory": "/workspace/logs",
    "pid_directory": "/workspace/logs",
    "default_extra_args": "",
    "startup_delay": 2
  }
}
```

## Environment Variables (Legacy Support)
- `COMFYUI_ENABLE_MULTI_INSTANCE`: Set to "true" to enable multi-instance mode
- `COMFYUI_INSTANCES`: Number of instances (used for backward compatibility)

## Usage Examples

### Basic Commands
```bash
# Start all enabled instances from configuration
/start_comfyui_multi.sh start

# Stop all instances
/start_comfyui_multi.sh stop

# Restart all instances
/start_comfyui_multi.sh restart

# Check status of all instances
/start_comfyui_multi.sh status
```

### Advanced Commands
```bash
# Start specific instance by name
/start_comfyui_multi.sh start-by-name comfyui-main

# Stop specific instance by name
/start_comfyui_multi.sh stop-by-name comfyui-backup

# Start instances in a port range
/start_comfyui_multi.sh start-ports 3001-3005

# Show help and available commands
/start_comfyui_multi.sh help
```

### Docker Integration
```bash
# Enable multi-instance mode with configuration file
docker run -e COMFYUI_ENABLE_MULTI_INSTANCE=true your-image

# Mount custom configuration
docker run -v /path/to/instances.json:/instances.json your-image
```

## Features

### Flexible Port Assignment
Unlike traditional sequential port assignment, you can now assign any port to any instance:
```json
{
  "instances": [
    {"id": 0, "port": 3001, "name": "main"},
    {"id": 1, "port": 8080, "name": "web"},
    {"id": 2, "port": 9000, "name": "test"}
  ]
}
```

### Instance Management
- **Named instances**: Each instance has a human-readable name
- **Enable/Disable**: Control which instances start automatically
- **Individual configuration**: Each instance can have different startup arguments
- **GPU-ready**: Designed for GPU environments with simple configuration

### Log and PID Files
- **Log files**: `/workspace/logs/comfyui_instance_<id>.log`
- **PID files**: `/workspace/logs/comfyui_instance_<id>.pid`

### Configuration Properties
- `id`: Unique identifier for the instance
- `port`: Port number for the instance
- `name`: Human-readable name
- `description`: Optional description
- `extra_args`: Additional ComfyUI arguments (e.g., "--lowvram")
- `enabled`: Whether this instance should start automatically

## Migrating from Environment Variables
If you were using the old environment variable approach:
```bash
# Old way
COMFYUI_INSTANCES=3 COMFYUI_BASE_PORT=3001

# New way - edit instances.json
{
  "instances": [
    {"id": 0, "port": 3001, "name": "instance-0", "enabled": true},
    {"id": 1, "port": 3002, "name": "instance-1", "enabled": true},  
    {"id": 2, "port": 3003, "name": "instance-2", "enabled": true}
  ]
}
```