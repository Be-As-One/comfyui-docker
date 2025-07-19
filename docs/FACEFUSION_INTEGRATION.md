# FaceFusion Integration Guide

This document describes the FaceFusion face swap integration for the ComfyUI Docker setup.

## Overview

The FaceFusion integration allows running face swap services using the Be-As-One fork of FaceFusion within the ComfyUI Docker environment. The integration includes:

- Custom installation script for the Be-As-One FaceFusion fork
- Dedicated startup script for FaceFusion service
- Integration with external FastAPI handler
- Docker build targets for FaceFusion workflows

## Key Components

### 1. Installation Script
**Location:** `build/facefusion/install.sh`
- Installs FaceFusion from `git@github.com:Be-As-One/facefusion.git`
- Sets up micromamba environment with Python 3.12
- Installs PyTorch and FaceFusion dependencies

### 2. Startup Script
**Location:** `scripts/start_facefusion.sh`
- Manages FaceFusion service lifecycle
- Integrates with external FastAPI handler at `/Users/hzy/Code/zhuilai/video-faceswap/fastapi_handler.py`
- Handles environment activation and logging

### 3. Environment Configuration
**Location:** `config/environments/facefusion/config.json`
- Service runs on port 3005
- Configured for face swap workflows
- Specifies external FastAPI handler integration

### 4. Docker Build Configuration
**Location:** `docker-bake.hcl`
- Added `facefusion` group with CUDA 12.4 and 12.8 targets
- Includes FaceFusion-specific build arguments
- Supports both `facefusion-cu124-py312` and `facefusion-cu128-py312` targets

## Usage

### Building FaceFusion Docker Image

```bash
# Build FaceFusion images for all CUDA versions
docker buildx bake facefusion

# Build specific CUDA version
docker buildx bake facefusion-cu128-py312
```

### Running FaceFusion Container

```bash
# Run with external FastAPI handler mounted
docker run -d \\
  --name comfyui-facefusion \\
  --gpus all \\
  -p 3005:3005 \\
  -v /Users/hzy/Code/zhuilai/video-faceswap:/external/video-faceswap \\
  your-registry/comfyui:facefusion-cu128-py312-latest

# Start FaceFusion service inside container
docker exec comfyui-facefusion /start_facefusion.sh
```

### Service Management

```bash
# Check FaceFusion service status
docker exec comfyui-facefusion /start_facefusion.sh status

# View service logs
docker exec comfyui-facefusion tail -f /workspace/logs/facefusion.log

# Stop service (if needed)
docker exec comfyui-facefusion pkill -f fastapi_handler.py
```

## Requirements

### External Dependencies
- **FaceFusion FastAPI Handler**: `/Users/hzy/Code/zhuilai/video-faceswap/fastapi_handler.py`
- **Video FaceSwap Repository**: Must be available at runtime for volume mounting

### System Requirements
- NVIDIA GPU with CUDA support
- Docker with BuildKit support
- Sufficient disk space for FaceFusion models

## API Endpoints

Once running, FaceFusion service exposes API endpoints on port 3005:

```bash
# Health check
curl http://localhost:3005/health

# Face swap processing
curl -X POST http://localhost:3005/process \\
  -H "Content-Type: application/json" \\
  -d '{
    "source_url": "https://example.com/source.jpg",
    "target_url": "https://example.com/target.jpg",
    "resolution": "1024x1024",
    "model": "inswapper_128_fp16"
  }'
```

## Integration Testing

Run the integration test to verify setup:

```bash
cd /path/to/comfyui-docker
./scripts/test_facefusion_integration.sh
```

## Troubleshooting

### Common Issues

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

### Debug Commands

```bash
# Check micromamba environments
docker exec comfyui-facefusion micromamba env list

# Test FaceFusion installation
docker exec comfyui-facefusion ls -la /facefusion

# Check Python environment
docker exec comfyui-facefusion micromamba activate facefusion && python -c "import facefusion; print('OK')"
```

## Architecture Notes

- FaceFusion runs in isolated micromamba environment (`facefusion`)
- External FastAPI handler provides REST API interface
- Service integrates with existing ComfyUI Docker infrastructure
- Shared model storage architecture reduces disk usage
- Environment configuration allows for future workflow extensions

## Version Information

- **FaceFusion Version**: 3.0.0 (configurable via `FACEFUSION_VERSION` build arg)
- **Python Version**: 3.12
- **CUDA Support**: 12.4 and 12.8
- **PyTorch Version**: 2.6.0+ (CUDA 12.4) / 2.7.0+ (CUDA 12.8)