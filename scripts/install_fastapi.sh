#!/usr/bin/env bash
set -e

echo "Installing ComfyUI-FastAPI..."

# Install FastAPI in root directory
cd /

# Check if directory already exists
if [ -d "comfyui-fastapi" ]; then
    echo "Directory /comfyui-fastapi already exists. Removing it..."
    rm -rf comfyui-fastapi
fi

# Clone the repository with error handling
if ! git clone https://github.com/Be-As-One/comfyui-fastapi.git; then
    echo "Error: Failed to clone ComfyUI-FastAPI repository"
    exit 1
fi

cd comfyui-fastapi

# Check if requirements.txt exists before installing
if [ ! -f "requirements.txt" ]; then
    echo "Warning: requirements.txt not found in /comfyui-fastapi"
    echo "Skipping pip install step"
else
    # Install requirements in the base Python environment with error handling
    if ! pip3 install -r requirements.txt; then
        echo "Error: Failed to install requirements from requirements.txt"
        exit 1
    fi
fi

echo "ComfyUI-FastAPI installation completed at /comfyui-fastapi"