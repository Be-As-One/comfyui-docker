#!/usr/bin/env bash
set -e

# Clone the repo
git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI
cd /ComfyUI
# git checkout ${COMFYUI_VERSION}

# Create and activate the venv
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Install torch, xformers and sageattention
pip3 install --no-cache-dir torch=="${TORCH_VERSION}" torchvision torchaudio --index-url ${INDEX_URL}
pip3 install --no-cache-dir xformers=="${XFORMERS_VERSION}" --index-url ${INDEX_URL}

# Install requirements
pip3 install -r requirements.txt
pip3 install accelerate
pip3 install sageattention
pip install setuptools --upgrade

# Install ComfyUI Custom Nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
cd custom_nodes/ComfyUI-Manager
pip3 install -r requirements.txt

# Download additional custom nodes
bash $(dirname $0)/comm-models-download.sh

# Install requirements for specific nodes that need them






# Install ComfyUI-FastAPI
cd /ComfyUI
git clone https://github.com/Be-As-One/comfyui-fastapi.git 
cd /ComfyUI/comfyui-fastapi
pip3 install -r requirements.txt

pip3 cache purge

# Fix some incorrect modules
pip3 install numpy==1.26.4
pip3 install onnxruntime-gpu==1.18.1
cd /ComfyUI
pip3 install -r requirements.txt
deactivate
