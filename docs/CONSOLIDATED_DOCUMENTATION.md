# ComfyUI Docker: Complete Documentation

## Table of Contents

1. [Overview](#overview)
   - [Key Features](#key-features)
   - [System Architecture](#system-architecture)
   - [Directory Structure](#directory-structure)
2. [Installation & Setup](#installation--setup)
   - [System Requirements](#system-requirements)
   - [Building the Docker Image](#building-the-docker-image)
   - [Running Locally](#running-locally)
3. [Multi-Instance Configuration](#multi-instance-configuration)
   - [Configuration Format](#configuration-format)
   - [Usage Examples](#usage-examples)
   - [Instance Management](#instance-management)
4. [External API Integration](#external-api-integration)
   - [FastAPI Service](#fastapi-service)
   - [API Endpoints](#api-endpoints)
   - [Integration Examples](#integration-examples)
5. [FaceFusion Integration](#facefusion-integration)
   - [Components](#facefusion-components)
   - [Building & Running](#facefusion-building--running)
   - [API Usage](#facefusion-api-usage)
6. [Technical Details](#technical-details)
   - [Build System](#build-system)
   - [Environment Management](#environment-management)
   - [Shared Model Architecture](#shared-model-architecture)
7. [Troubleshooting & Support](#troubleshooting--support)

---

## Overview

<div align="center">

# Multi-Instance ComfyUI Docker: Scalable AI Image Generation Platform

[![GitHub Repo](https://img.shields.io/badge/github-repo-green?logo=github)](https://github.com/ashleykleynhans/comfyui-docker)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/ashleykza/comfyui?logo=docker&label=dockerhub&color=blue)](https://hub.docker.com/repository/docker/ashleykza/comfyui)
[![RunPod.io Template](https://img.shields.io/badge/runpod_template-deploy-9b4ce6?logo=linuxcontainers&logoColor=9b4ce6)](https://runpod.io/console/deploy?template=9eqyhd7vs0&ref=2xxro4sy)

</div>

### Key Features

- **Multi-Instance Support**: Run multiple ComfyUI instances on a single machine with different configurations
- **Smart Environment Management**: Intelligent on-demand installation using build script replication and dynamic path replacement
- **Multi-Workflow Build Support**: Build different workflow-specific images (comm, aua-sp, facefusion) with ARG-based configuration
- **Shared Model Architecture**: All instances share the same model files, dramatically reducing disk usage
- **External API Control**: Start, stop, and manage instances via RESTful API calls
- **Environment Isolation**: Each environment runs in isolated directories with dedicated virtual environments
- **Resource Efficient**: No ComfyUI instances run by default - only FastAPI service for external control
- **Build Script Replication**: Innovative build script copying and path modification for environment-specific installations
- **FaceFusion Integration**: Integrated face swap capabilities using the Be-As-One FaceFusion fork

### System Architecture

#### Build Time vs Runtime Architecture

```mermaid
graph TB
    subgraph "Build Time"
        A1["Dockerfile ARG WORKFLOW"] --> A2["Copy build/WORKFLOW/*"]
        A2 --> A3["Install Workflow-Specific ComfyUI to /ComfyUI"]
        A3 --> A4["Create Base Image with Selected Workflow"]
    end
    
    subgraph "Runtime - Container Startup"
        B1["Container Starts"] --> B2["pre_start.sh: Sync /ComfyUI to /workspace/ComfyUI"]
        B2 --> B3["Start FastAPI Service Only"]
        B3 --> B4["Wait for External API Calls"]
    end
    
    subgraph "Runtime - Instance Creation"
        C1["API Request to Create Instance"] --> C2{"Target Environment Exists?"}
        C2 -->|No| C3["install_comfyui_env.py: Copy & Modify Build Scripts"]
        C3 --> C4["Replace /ComfyUI with /workspace/ComfyUI-env"]
        C4 --> C5["Execute Modified Installation Script"]
        C5 --> C6["Setup Shared Model Links"]
        C2 -->|Yes| C6
        C6 --> C7["Start ComfyUI Instance"]
        C7 --> C8["Instance Running on Specified Port"]
    end
    
    A4 --> B1
    B4 --> C1
```

#### Shared Model Architecture

```mermaid
graph TB
    A[/workspace/shared-models/] --> B[checkpoints/]
    A --> C[loras/]
    A --> D[controlnet/]
    A --> E[vae/]
    
    F[ComfyUI-comm/models/] -.->|symlink| A
    G[ComfyUI-aua-sp/models/] -.->|symlink| A
    
    H[Instance 1: comm] --> F
    I[Instance 2: aua-sp] --> G
    J[Instance 3: comm] --> F
    
    style A fill:#e1f5fe
    style F fill:#f3e5f5
    style G fill:#f3e5f5
```

### Directory Structure

```
/workspace/
├── shared-models/              # Shared model storage (all instances)
│   ├── checkpoints/
│   ├── loras/
│   ├── controlnet/
│   └── vae/
├── ComfyUI-comm/               # Common environment
│   ├── models/ -> ../shared-models/
│   ├── custom_nodes/
│   └── venv/
├── ComfyUI-aua-sp/             # Specialized environment
│   ├── models/ -> ../shared-models/
│   ├── custom_nodes/
│   └── venv/
├── facefusion/                 # FaceFusion installation
│   └── .conda/                 # Micromamba environment
└── logs/                       # Instance logs
    ├── comfyui_instance_0.log
    ├── comfyui_instance_1.log
    ├── facefusion.log
    └── fastapi.log
```

---

## Installation & Setup

### System Requirements

#### Software Stack
* Ubuntu 22.04 LTS
* CUDA 12.8 / 12.4 (12.8 is default)
* Python 3.12.9 / 3.11.12 (3.12.9 is default)
* Torch 2.7.0 / 2.6.0 (2.7.0 is default)
* xformers 0.0.30 / 0.0.29.post3 (0.0.30 is default)
* [ComfyUI](https://github.com/comfyanonymous/ComfyUI) v0.3.40

#### Included Tools
* [Jupyter Lab](https://github.com/jupyterlab/jupyterlab)
* [code-server](https://github.com/coder/code-server)
* [runpodctl](https://github.com/runpod/runpodctl)
* [OhMyRunPod](https://github.com/kodxana/OhMyRunPod)
* [RunPod File Uploader](https://github.com/kodxana/RunPod-FilleUploader)
* [croc](https://github.com/schollz/croc)
* [rclone](https://rclone.org/)
* [Application Manager](https://github.com/ashleykleynhans/app-manager)
* [CivitAI Downloader](https://github.com/ashleykleynhans/civitai-downloader)

#### ComfyUI Custom Nodes

**Common Environment (`comm`)**
* [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
* [ComfyUI-Advanced-ControlNet](https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet)
* [comfyui_controlnet_aux](https://github.com/Fannovel16/comfyui_controlnet_aux)
* [comfyui-inpaint-nodes](https://github.com/Acly/comfyui-inpaint-nodes)
* [masquerade-nodes-comfyui](https://github.com/BadCafeCode/masquerade-nodes-comfyui)
* [ComfyUI-Florence2](https://github.com/kijai/ComfyUI-Florence2)
* [ComfyUI-segment-anything-2](https://github.com/kijai/ComfyUI-segment-anything-2)
* [ComfyUI_essentials](https://github.com/cubiq/ComfyUI_essentials)
* [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts)
* [ComfyUI_Comfyroll_CustomNodes](https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes)
* [ComfyUI-Gemini_Flash_2.0_Exp](https://github.com/ShmuelRonen/ComfyUI-Gemini_Flash_2.0_Exp)
* [ComfyUI-FastAPI](https://github.com/Be-As-One/comfyui-fastapi)

**Specialized Environment (`aua-sp`)**
Includes all common nodes plus additional specialized models and LoRAs for advanced use cases.

### Building the Docker Image

> **Note**: You will need to edit the `docker-bake.hcl` file and update `REGISTRY_USER`, and `RELEASE`. You can obviously edit the other values too, but these are the most important ones.

> **Important**: In order to cache the models, you will need at least 32GB of CPU/system memory (not VRAM) due to the large size of the models. If you have less than 32GB of system memory, you can comment out or remove the code in the `Dockerfile` that caches the models.

```bash
# Clone the repo
git clone https://github.com/ashleykleynhans/comfyui-docker.git

# Log in to Docker Hub
docker login

# Build the default image (CUDA 12.8 and Python 3.12), tag the image, and push the image to Docker Hub
docker buildx bake -f docker-bake.hcl --push

# OR build a different image (eg. CUDA 12.4 and Python 3.11), tag the image, and push the image to Docker Hub
docker buildx bake -f docker-bake.hcl cu124-py311 --push

# OR build ALL images, tag the images, and push the images to Docker Hub
docker buildx bake -f docker-bake.hcl all --push

# Build FaceFusion images
docker buildx bake -f docker-bake.hcl facefusion --push

# Same as above but customize registry/user/release:
REGISTRY=ghcr.io REGISTRY_USER=myuser RELEASE=my-release docker buildx \
    bake -f docker-bake.hcl --push
```

### Running Locally

#### Install Nvidia CUDA Driver

- [Linux](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)
- [Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html)

#### Start the Docker Container

```bash
docker run -d \
  --gpus all \
  -v /workspace \
  -p 2999:2999 \
  -p 3000-3010:3001-3011 \
  -p 7777:7777 \
  -p 8000:8000 \
  -p 8001:8001 \
  -p 8888:8888 \
  -e JUPYTER_PASSWORD=Jup1t3R! \
  -e DISABLE_AUTOLAUNCH=true \
  ashleykza/comfyui:latest
```

### Ports

| Connect Port | Internal Port | Description                      |
|--------------|---------------|----------------------------------|
| 3000-3010    | 3001-3011     | ComfyUI Instances (multi-port)   |
| 7777         | 7777          | Code Server                      |
| 8000         | 8000          | Application Manager              |
| 8001         | 8001          | FastAPI (Instance Management)    |
| 8888         | 8888          | Jupyter Lab                      |
| 2999         | 2999          | RunPod File Uploader             |

### Environment Variables

| Variable               | Description                                                                                 | Default               |
|------------------------|---------------------------------------------------------------------------------------------|-----------------------|
| JUPYTER_LAB_PASSWORD   | Set a password for Jupyter lab                                                              | not set - no password |
| DISABLE_AUTOLAUNCH     | Disable ComfyUI from launching automatically (recommended for multi-instance)              | true                  |
| SKIP_MODEL_DOWNLOAD    | Skip downloading models during environment installation (faster startup)                   | (not set)             |
| DISABLE_SYNC           | Disable syncing if using a RunPod network volume                                           | (not set)             |
| COMFYUI_ENVIRONMENT    | Default environment to use (comm/aua-sp)                                                   | comm                  |
| COMFYUI_BASE_PORT      | Base port for ComfyUI instances                                                            | 3001                  |
| EXTRA_ARGS             | Specify extra command line arguments for ComfyUI, eg. `--lowvram`, `--disable-xformers`   | (not set)             |

---

## Multi-Instance Configuration

This system supports running multiple ComfyUI instances with flexible port assignment through configuration files. Perfect for GPU environments where you need multiple ComfyUI instances on different ports.

### Configuration Format

The system uses `instances.json` configuration file located in the root directory (`/instances.json`). This file defines all instances with their specific settings.

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

### Usage Examples

#### Basic Commands
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

#### Advanced Commands
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

#### Docker Integration
```bash
# Enable multi-instance mode with configuration file
docker run -e COMFYUI_ENABLE_MULTI_INSTANCE=true your-image

# Mount custom configuration
docker run -v /path/to/instances.json:/instances.json your-image
```

### Instance Management

#### Features
- **Flexible Port Assignment**: Assign any port to any instance
- **Named instances**: Each instance has a human-readable name
- **Enable/Disable**: Control which instances start automatically
- **Individual configuration**: Each instance can have different startup arguments
- **GPU-ready**: Designed for GPU environments with simple configuration

#### Configuration Properties
- `id`: Unique identifier for the instance
- `port`: Port number for the instance
- `name`: Human-readable name
- `description`: Optional description
- `extra_args`: Additional ComfyUI arguments (e.g., "--lowvram")
- `enabled`: Whether this instance should start automatically

#### Log and PID Files
- **Log files**: `/workspace/logs/comfyui_instance_<id>.log`
- **PID files**: `/workspace/logs/comfyui_instance_<id>.pid`

### Migrating from Environment Variables

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

---

## External API Integration

The container exposes a FastAPI service on port 8001 for managing ComfyUI instances externally. The ComfyUI container starts with **no ComfyUI instances running by default**. Only the FastAPI service runs on port 8001. ComfyUI instances are started on-demand via external API calls.

### FastAPI Service

#### Task Workflow System

The FastAPI service includes an intelligent task routing system that automatically distributes tasks to the appropriate ComfyUI environment based on workflow type:

##### Task Structure
When fetching a task via `/comfyui-fetch-task`, the system returns:
```json
{
    "taskId": "task_xxx",
    "workflow_name": "clothes_prompt_changer_with_auto",  // Workflow identifier
    "environment": "aua-us",                              // Target environment (auto-determined)
    "target_port": 3002,                                  // ComfyUI port (auto-determined)
    "params": {
        "input_data": {
            "wf_json": {...}  // Actual workflow JSON content
        }
    },
    "status": "PENDING"
}
```

**Note**: The `environment` and `target_port` fields are automatically determined by the system based on the `workflow_name`. They are output fields that inform the caller which environment and port to use for executing the workflow.

##### Workflow Routing Configuration
The system uses environment configuration files (`/config/environments/{environment}/config.json`) to map workflows to specific environments:
- `clothes_prompt_changer_with_auto` → `aua-us` (port 3002)
- `clothes_prompt_changer_with_mask` → `aua-us` (port 3002)
- Other workflows → Assigned based on configuration

### API Endpoints

#### Task Management
- `GET /comfyui-fetch-task` - Fetch next pending task
- `POST /comfyui-update-task` - Update task status
- `GET /tasks` - List all tasks
- `POST /tasks/create/{workflow_name}` - Create task for specific workflow
- `GET /workflows` - Get available workflows and mappings
- `GET /environments` - Get environment configurations

#### Instance Management
- `POST /api/comfyui/start-single` - Start a single ComfyUI instance
- `POST /api/comfyui/start-instances` - Start multiple ComfyUI instances
- `GET /api/comfyui/status` - Check instance status
- `POST /api/comfyui/stop-all` - Stop all instances

### Integration Examples

#### Python FastAPI Example

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

#### Usage Examples

##### Start Multiple Instances
```bash
curl -X POST "http://localhost:8001/api/comfyui/start-instances" \
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

##### Start Single Instance
```bash
curl -X POST "http://localhost:8001/api/comfyui/start-single" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 0,
    "port": 3001,
    "name": "main-instance",
    "extra_args": "--lowvram",
    "enabled": true
  }' \
  --data-urlencode "environment=comm"
```

##### Check Status
```bash
curl -X GET "http://localhost:8001/api/comfyui/status"
```

##### Stop All Instances
```bash
curl -X POST "http://localhost:8001/api/comfyui/stop-all"
```

#### Direct Container Commands

```bash
# Start instance directly
docker exec your-container bash -c \
  'COMFYUI_ENVIRONMENT=comm INSTANCE_PORT=3001 INSTANCE_NAME=main /start_comfyui.sh 0'

# Check status
docker exec your-container /stop_comfyui.sh status

# Stop all instances
docker exec your-container /stop_comfyui.sh all

# Stop specific instance
docker exec your-container /stop_comfyui.sh instance 0
```

#### Node.js Express Example

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

### Configuration Notes

#### JSON Configuration Format
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

#### Environment Types
- **comm**: Standard ComfyUI environment with common models and nodes
- **aua-sp**: Specialized environment with additional features and models

---

## FaceFusion Integration

The FaceFusion integration allows running face swap services using the Be-As-One fork of FaceFusion within the ComfyUI Docker environment.

### FaceFusion Components

#### 1. Installation Script
**Location:** `build/facefusion/install_comfyui.sh`
- Installs FaceFusion from `git@github.com:Be-As-One/facefusion.git`
- Sets up micromamba environment with Python 3.12
- Installs PyTorch and FaceFusion dependencies

#### 2. Startup Script
**Location:** `scripts/start_facefusion.sh`
- Manages FaceFusion service lifecycle
- Integrates with external FastAPI handler at `/Users/hzy/Code/zhuilai/video-faceswap/fastapi_handler.py`
- Handles environment activation and logging

#### 3. Environment Configuration
**Location:** `config/environments/facefusion/config.json`
- Service runs on port 3005
- Configured for face swap workflows
- Specifies external FastAPI handler integration

#### 4. Docker Build Configuration
**Location:** `docker-bake.hcl`
- Added `facefusion` group with CUDA 12.4 and 12.8 targets
- Includes FaceFusion-specific build arguments
- Supports both `facefusion-cu124-py312` and `facefusion-cu128-py312` targets

### FaceFusion Building & Running

#### Building FaceFusion Docker Image

```bash
# Build FaceFusion images for all CUDA versions
docker buildx bake facefusion

# Build specific CUDA version
docker buildx bake facefusion-cu128-py312
```

#### Running FaceFusion Container

```bash
# Run with external FastAPI handler mounted
docker run -d \
  --name comfyui-facefusion \
  --gpus all \
  -p 3005:3005 \
  -v /Users/hzy/Code/zhuilai/video-faceswap:/external/video-faceswap \
  your-registry/comfyui:facefusion-cu128-py312-latest

# Start FaceFusion service inside container
docker exec comfyui-facefusion /start_facefusion.sh
```

#### Service Management

```bash
# Check FaceFusion service status
docker exec comfyui-facefusion /start_facefusion.sh status

# View service logs
docker exec comfyui-facefusion tail -f /workspace/logs/facefusion.log

# Stop service (if needed)
docker exec comfyui-facefusion pkill -f fastapi_handler.py
```

### FaceFusion API Usage

Once running, FaceFusion service exposes API endpoints on port 3005:

```bash
# Health check
curl http://localhost:3005/health

# Face swap processing
curl -X POST http://localhost:3005/process \
  -H "Content-Type: application/json" \
  -d '{
    "source_url": "https://example.com/source.jpg",
    "target_url": "https://example.com/target.jpg",
    "resolution": "1024x1024",
    "model": "inswapper_128_fp16"
  }'
```

### FaceFusion Requirements

#### External Dependencies
- **FaceFusion FastAPI Handler**: `/Users/hzy/Code/zhuilai/video-faceswap/fastapi_handler.py`
- **Video FaceSwap Repository**: Must be available at runtime for volume mounting

#### System Requirements
- NVIDIA GPU with CUDA support
- Docker with BuildKit support
- Sufficient disk space for FaceFusion models

### FaceFusion Troubleshooting

#### Common Issues

1. **External FastAPI Handler Not Found**
   - Ensure `/Users/hzy/Code/zhuilai/video-faceswap/fastapi_handler.py` exists
   - Check volume mount in Docker run command

2. **FaceFusion Installation Fails**
   - Verify SSH access to GitHub for `git@github.com:Be-As-One/facefusion.git`
   - Check build logs for dependency issues

3. **Service Won't Start**
   - Check micromamba environment activation
   - Verify Python dependencies are installed
   - Review logs at `/workspace/logs/facefusion.log`

#### Debug Commands

```bash
# Check micromamba environments
docker exec comfyui-facefusion micromamba env list

# Test FaceFusion installation
docker exec comfyui-facefusion ls -la /facefusion

# Check Python environment
docker exec comfyui-facefusion micromamba activate facefusion && python -c "import facefusion; print('OK')"
```

#### Version Information

- **FaceFusion Version**: 3.0.0 (configurable via `FACEFUSION_VERSION` build arg)
- **Python Version**: 3.12
- **CUDA Support**: 12.4 and 12.8
- **PyTorch Version**: 2.6.0+ (CUDA 12.4) / 2.7.0+ (CUDA 12.8)

---

## Technical Details

### Build System

#### Docker Buildx Bake Configuration

The project uses Docker Buildx Bake for multi-platform and multi-variant builds. The configuration has been validated with the following results:

##### Available Build Targets
- **Individual targets**: `cu124-py311`, `cu124-py312`, `cu128-py311`, `cu128-py312`
- **Default group**: `cu128-py312`, `cu124-py312`
- **All group**: Includes all 4 targets
- **FaceFusion group**: `facefusion-cu124-py312`, `facefusion-cu128-py312`

##### Build Commands
```bash
# Build default targets
docker buildx bake -f docker-bake.hcl --push

# Build specific target
docker buildx bake -f docker-bake.hcl cu124-py312 --push

# Build all targets
docker buildx bake -f docker-bake.hcl all --push

# Print configuration (for debugging)
docker buildx bake -f docker-bake.hcl --print cu124-py312
```

##### Target Configuration Example (cu124-py312)
- **Base Image**: `ashleykza/runpod-base:2.4.2-python3.12-cuda12.4.1-torch2.6.0`
- **Tag**: `docker.io/useless1234567/comfyui:cu124-py312-v0.3.40-fastapi-v0.0.4`
- **Platform**: `linux/amd64`
- **Workflow**: `comm`

### Environment Management

#### Smart Environment Installation Flow

```mermaid
sequenceDiagram
    participant Client as External Client
    participant API as FastAPI Service
    participant StartScript as start_comfyui.sh
    participant Installer as install_comfyui_env.py
    participant BuildScripts as /build/{env}/
    participant ComfyUI as ComfyUI Instance
    
    Client->>API: POST /api/comfyui/start-instance
    API->>StartScript: Execute with environment parameter
    StartScript->>StartScript: Check if /workspace/ComfyUI-{env} exists
    
    alt Environment Not Found
        StartScript->>Installer: Call install_comfyui_env.py {env}
        Installer->>BuildScripts: Copy build scripts to temp directory
        Installer->>Installer: Replace /ComfyUI with /workspace/ComfyUI-{env}
        Installer->>Installer: Execute modified install_comfyui.sh
        Installer->>Installer: Setup shared models symlinks
        Installer->>StartScript: Installation complete
    end
    
    StartScript->>ComfyUI: Launch instance in environment directory
    ComfyUI->>API: Instance started successfully
    API->>Client: Instance Information
```

#### Build Script Replication Technology

The system uses a sophisticated build script replication mechanism:

1. **Template Preparation**: Build scripts are prepared for each workflow type (`comm`, `aua-sp`) in `/build/{workflow}/`
2. **Dynamic Copy & Modify**: When a new environment is needed, `install_comfyui_env.py` copies the build scripts to a temporary directory
3. **Path Transformation**: All paths in the scripts are dynamically replaced from `/ComfyUI` to `/workspace/ComfyUI-{environment}`
4. **Isolated Execution**: Modified scripts run in isolation, creating environment-specific installations

#### Multi-Workflow Build System

```mermaid
graph LR
    A[docker buildx bake] --> B{ARG WORKFLOW}
    B -->|comm| C[build/comm/install_comfyui.sh]
    B -->|aua-sp| D[build/aua-sp/install_comfyui.sh]
    B -->|facefusion| E[build/facefusion/install_comfyui.sh]
    C --> F[ComfyUI Image: comm variant]
    D --> G[ComfyUI Image: aua-sp variant]
    E --> H[ComfyUI Image: facefusion variant]
```

#### Environment Installation Process

When `start_comfyui.sh` detects a missing environment:

```bash
# Environment check in start_comfyui.sh
if [[ ! -d "${COMFYUI_DIR}" || ! -f "${COMFYUI_DIR}/main.py" ]]; then
    echo "COMFYUI: Environment ${COMFYUI_ENVIRONMENT} not found. Installing..."
    /install_comfyui_env.py "${COMFYUI_ENVIRONMENT}"
fi
```

The installer performs these steps:
1. **Validation**: Checks if the requested environment is valid (`comm`, `aua-us`, `aua-sp`)
2. **Build Script Discovery**: Locates the appropriate build scripts in `/build/{environment}/`
3. **Template Copy**: Copies build scripts to a temporary working directory
4. **Path Replacement**: Replaces all `/ComfyUI` references with `/workspace/ComfyUI-{environment}`
5. **Execution**: Runs the modified installation script with environment variables
6. **Shared Model Setup**: Creates symbolic links to the shared model directory
7. **Custom Node Installation**: Downloads and installs environment-specific custom nodes
8. **Dependency Fixes**: Runs environment-specific dependency fix scripts (`fix_dependencies.sh`)
9. **Verification**: Validates the installation completed successfully

#### Environment-Specific Configuration

Each environment has its own configuration directory structure:

```
/config/environments/
├── comm/
│   ├── config.json          # Environment configuration (nodes, models, workflows)
│   └── fix_dependencies.sh  # Environment-specific dependency fixes
├── aua-us/
│   ├── config.json
│   └── fix_dependencies.sh
├── aua-sp/
│   ├── config.json
│   └── fix_dependencies.sh
└── facefusion/
    ├── config.json
    └── fix_dependencies.sh
```

This modular approach allows for:
- **Environment-Specific Dependencies**: Each environment can have different dependency requirements
- **Isolated Configuration**: Changes to one environment don't affect others
- **Maintainable Updates**: Easy to update specific environment configurations

### Shared Model Architecture

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

---

## Troubleshooting & Support

### Logs

ComfyUI creates separate log files for each component:

| Application         | Log file                               |
|---------------------|----------------------------------------|
| ComfyUI Instance 0  | /workspace/logs/comfyui_instance_0.log |
| ComfyUI Instance 1  | /workspace/logs/comfyui_instance_1.log |
| ComfyUI Instance N  | /workspace/logs/comfyui_instance_N.log |
| FastAPI             | /workspace/logs/fastapi.log            |
| FaceFusion          | /workspace/logs/facefusion.log         |

You can tail individual instance logs:
```bash
tail -f /workspace/logs/comfyui_instance_0.log
```

### Benefits of This Architecture

#### Technical Innovation
- **Build Script Replication**: Sophisticated build script copying and path transformation technology
- **Dynamic Path Replacement**: Automatic path modification from `/ComfyUI` to environment-specific paths
- **Multi-Workflow Build**: Single Dockerfile supports multiple workflow variants via ARG parameters
- **Template-Based Installation**: Reusable installation templates for consistent environment creation

#### Resource Efficiency
- **Shared Models**: All instances share the same model files, saving GB of disk space
- **On-Demand Installation**: Environments are only installed when needed
- **No Idle Resources**: Container starts with minimal services running
- **Optimized Build Process**: Single base image supports multiple environment types

#### Scalability
- **Multiple Instances**: Run different ComfyUI configurations simultaneously
- **Load Distribution**: Distribute workload across multiple instances
- **Environment Isolation**: Each environment has its own dependencies and custom nodes
- **Horizontal Scaling**: Easy replication of successful environment configurations

#### Management Simplicity
- **External API Control**: Complete instance lifecycle management via REST API
- **Unified Logging**: Separate logs for each instance with consistent naming
- **Status Monitoring**: Real-time instance status and port information
- **Intelligent Environment Detection**: Automatic environment installation when needed

#### Flexibility
- **Multi-Environment**: Support for different ComfyUI setups (comm, aua-sp, facefusion)
- **Dynamic Configuration**: Each instance can have different startup parameters
- **Easy Integration**: Simple API integration with orchestration systems
- **Extensible Architecture**: Simple to add new workflow types and environments

### Available on RunPod

This image is designed to work on [RunPod](https://runpod.io?ref=2xxro4sy).
You can use the custom [RunPod template](https://runpod.io/console/deploy?template=9eqyhd7vs0&ref=2xxro4sy) to launch it on RunPod.

### Community and Contributing

Pull requests and issues on [GitHub](https://github.com/ashleykleynhans/comfyui-docker) are welcome. Bug fixes and new features are encouraged.

---

*Multi-Instance ComfyUI Docker v0.3.40 | Complete Documentation | Last Updated: 2025-07-19*