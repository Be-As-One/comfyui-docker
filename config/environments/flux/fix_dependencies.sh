#!/usr/bin/env bash
set -e

# Fix dependencies for aua-us environment
echo "Using pip: $(which pip)"
pip cache purge

# Fix some incorrect modules
pip install numpy==1.26.4
pip install onnxruntime-gpu==1.18.1

# Install requirements if exists
if [ -f "requirements.txt" ]; then
    echo "Installing from requirements.txt"
    pip install -r requirements.txt
else
    echo "No requirements.txt found in $(pwd)"
fi