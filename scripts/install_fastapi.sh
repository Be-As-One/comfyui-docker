#!/usr/bin/env bash
set -e

echo "Installing ComfyUI-FastAPI..."

# Create workspace directory and install FastAPI there
mkdir -p /workspace
cd /workspace
git clone https://github.com/Be-As-One/comfyui-fastapi.git
cd comfyui-fastapi

# Install requirements in the base Python environment
pip3 install -r requirements.txt

echo "ComfyUI-FastAPI installation completed at /workspace/comfyui-fastapi"