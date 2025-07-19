# External API Integration Example

## Overview
This document provides examples for integrating with the ComfyUI multi-instance system via external API calls.

## Container Setup
The ComfyUI container now starts with **no ComfyUI instances running by default**. Only the FastAPI service runs on port 8001. ComfyUI instances are started on-demand via external API calls.

## External API Implementation Examples

### Python FastAPI Example

```python
import subprocess
import json
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# Configuration
CONTAINER_NAME = "your-comfyui-container"
DOCKER_EXEC_CMD = f"docker exec {CONTAINER_NAME}"

class ComfyUIInstance(BaseModel):
    id: int
    port: int
    name: str
    extra_args: Optional[str] = ""
    enabled: Optional[bool] = True

class StartInstancesRequest(BaseModel):
    environment: Optional[str] = "comm"  # Environment type: comm or aua-sp
    instances: List[ComfyUIInstance]

@app.post("/api/comfyui/start-instances")
async def start_comfyui_instances(request: StartInstancesRequest):
    """Start ComfyUI instances using direct environment variable approach"""
    
    results = []
    
    for instance in request.instances:
        if not instance.enabled:
            continue
            
        # Set environment variables and execute
        env_vars = f'COMFYUI_ENVIRONMENT={request.environment} INSTANCE_PORT={instance.port} INSTANCE_NAME={instance.name}'
        cmd = f'{DOCKER_EXEC_CMD} bash -c "{env_vars} /start_comfyui.sh {instance.id} \'{instance.extra_args}\'"'
    
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                results.append({
                    "instance_id": instance.id,
                    "name": instance.name,
                    "port": instance.port,
                    "status": "started",
                    "output": result.stdout
                })
            else:
                results.append({
                    "instance_id": instance.id,
                    "name": instance.name,
                    "port": instance.port,
                    "status": "failed",
                    "error": result.stderr
                })
                
        except subprocess.TimeoutExpired:
            results.append({
                "instance_id": instance.id,
                "name": instance.name,
                "port": instance.port,
                "status": "timeout"
            })
        except Exception as e:
            results.append({
                "instance_id": instance.id,
                "name": instance.name,
                "port": instance.port,
                "status": "error",
                "error": str(e)
            })
    
    return {
        "status": "completed",
        "environment": request.environment,
        "results": results,
        "total_instances": len(request.instances),
        "started_instances": len([r for r in results if r["status"] == "started"])
    }

@app.post("/api/comfyui/stop-all")
async def stop_all_instances():
    """Stop all running ComfyUI instances"""
    
    cmd = f'{DOCKER_EXEC_CMD} /stop_comfyui.sh all'
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return {
            "status": "success",
            "message": "All instances stopped",
            "output": result.stdout
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/comfyui/status")
async def get_instances_status():
    """Get status of all ComfyUI instances"""
    
    cmd = f'{DOCKER_EXEC_CMD} /stop_comfyui.sh status'
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=15)
        return {
            "status": "success",
            "output": result.stdout
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/comfyui/start-single")
async def start_single_instance(instance: ComfyUIInstance, environment: str = "comm"):
    """Start a single ComfyUI instance"""
    
    # Set environment variables and execute
    env_vars = f'COMFYUI_ENVIRONMENT={environment} INSTANCE_PORT={instance.port} INSTANCE_NAME={instance.name}'
    cmd = f'{DOCKER_EXEC_CMD} bash -c "{env_vars} /start_comfyui.sh {instance.id} \'{instance.extra_args}\'"'
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            return {
                "status": "success",
                "message": f"Instance '{instance.name}' started on port {instance.port}",
                "output": result.stdout
            }
        else:
            raise HTTPException(
                status_code=500, 
                detail=f"Failed to start instance: {result.stderr}"
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### Usage Examples

#### 1. Start Multiple Instances
```bash
curl -X POST "http://your-api-host/api/comfyui/start-instances" \
  -H "Content-Type: application/json" \
  -d '{
    "environment": "comm",
    "instances": [
      {
        "id": 0,
        "port": 3001,
        "name": "comfyui-main",
        "extra_args": "",
        "enabled": true
      },
      {
        "id": 1,
        "port": 3005,
        "name": "comfyui-backup",
        "extra_args": "--lowvram",
        "enabled": true
      }
    ]
  }'
```

#### 2. Start Single Instance
```bash
curl -X POST "http://your-api-host/api/comfyui/start-single" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 0,
    "port": 3001,
    "name": "comfyui-quick",
    "extra_args": "",
    "enabled": true
  }'
```

#### 3. Check Status
```bash
curl -X GET "http://your-api-host/api/comfyui/status"
```

#### 4. Stop All Instances
```bash
curl -X POST "http://your-api-host/api/comfyui/stop-all"
```

### Direct Container Commands

You can also interact directly with the container:

```bash
# Start single instance with environment variables
docker exec your-container bash -c \
  'COMFYUI_ENVIRONMENT=comm INSTANCE_PORT=3001 INSTANCE_NAME=main /start_comfyui.sh 0'

# Start multiple instances
docker exec your-container bash -c \
  'COMFYUI_ENVIRONMENT=comm INSTANCE_PORT=3001 INSTANCE_NAME=main /start_comfyui.sh 0'
docker exec your-container bash -c \
  'COMFYUI_ENVIRONMENT=aua-sp INSTANCE_PORT=3002 INSTANCE_NAME=backup /start_comfyui.sh 1'

# Check status
docker exec your-container /stop_comfyui.sh status

# Stop all instances
docker exec your-container /stop_comfyui.sh all

# Stop specific instance
docker exec your-container /stop_comfyui.sh instance 0
```

### Node.js Express Example

```javascript
const express = require('express');
const { exec } = require('child_process');
const app = express();

app.use(express.json());

const CONTAINER_NAME = 'your-comfyui-container';

app.post('/api/comfyui/start-instances', (req, res) => {
    const { instances } = req.body;
    
    if (!instances || !Array.isArray(instances)) {
        return res.status(400).json({ error: 'Invalid instances array' });
    }
    
    const jsonConfig = JSON.stringify({ instances });
    const cmd = `docker exec ${CONTAINER_NAME} /start_comfyui_multi.sh json '${jsonConfig}'`;
    
    exec(cmd, { timeout: 60000 }, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: error.message, stderr });
        }
        
        res.json({
            status: 'success',
            message: 'Instances started',
            output: stdout,
            instances_count: instances.length
        });
    });
});

app.listen(3000, () => {
    console.log('ComfyUI API server running on port 3000');
});
```

## Configuration Notes

### JSON Configuration Format
```json
{
  "environment": "comm",     // Environment type: "comm" or "aua-sp"
  "instances": [
    {
      "id": 0,               // Unique instance ID
      "port": 3001,          // Port for this instance
      "name": "main",        // Human-readable name
      "extra_args": "",      // Additional ComfyUI arguments
      "enabled": true        // Whether to start this instance
    }
  ]
}
```

### Environment Variables
- `DISABLE_AUTOLAUNCH=true` (default) - ComfyUI won't start automatically
- `DISABLE_AUTOLAUNCH=false` - Enable automatic startup using instances.json

### Port Management
- ComfyUI instances: 3001+ (configurable)
- FastAPI service: 8001 (always running)
- Choose ports that don't conflict with other services

### Environment Types
- **comm**: Standard ComfyUI environment with common models and nodes
- **aua-sp**: Specialized environment with additional features and models

### Shared Models Architecture
The system uses a shared model storage to optimize disk space and startup time:

```
/workspace/
├── shared-models/              # Shared model storage (soft-linked)
│   ├── checkpoints/
│   ├── loras/
│   ├── controlnet/
│   └── vae/
│
├── ComfyUI-comm/               # comm environment
│   ├── models/                 # symlink -> /workspace/shared-models/
│   ├── custom_nodes/           # environment-specific nodes
│   └── venv/                   # environment-specific Python env
│
└── ComfyUI-aua-sp/             # aua-sp environment
    ├── models/                 # symlink -> /workspace/shared-models/
    ├── custom_nodes/           # environment-specific nodes
    └── venv/                   # environment-specific Python env
```

**Benefits**:
- Models are stored only once, saving GB of disk space
- Fast environment switching without re-downloading models
- Each environment has isolated custom nodes and dependencies

## Benefits of This Approach

1. **Resource Efficiency**: No ComfyUI instances running until needed
2. **Dynamic Configuration**: Each startup can use different settings
3. **External Control**: Complete management via API calls
4. **Scalability**: Easy to integrate with orchestration systems
5. **Flexibility**: Support both file-based and API-driven configuration
6. **Space Optimization**: Shared model storage reduces disk usage
7. **Multi-Environment**: Support different ComfyUI configurations simultaneously