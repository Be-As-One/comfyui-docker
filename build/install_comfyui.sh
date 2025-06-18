#!/usr/bin/env bash
set -e

# Clone the repo
git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI
cd /ComfyUI
git checkout ${COMFYUI_VERSION}

# Create and activate the venv
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Install torch, xformers and sageattention
pip3 install --no-cache-dir torch=="${TORCH_VERSION}" torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip3 install --no-cache-dir xformers=="${XFORMERS_VERSION}" --index-url https://download.pytorch.org/whl/cu121

# Install requirements
pip3 install -r requirements.txt
pip3 install accelerate
pip3 install sageattention
pip install setuptools --upgrade

# Install ComfyUI Custom Nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
cd custom_nodes/ComfyUI-Manager
pip3 install -r requirements.txt

# ComfyUI-Advanced-ControlNet
git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git \
  /ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet


# comfyui_controlnet_aux
git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git \
  /ComfyUI/custom_nodes/comfyui_controlnet_aux

cd /ComfyUI/custom_nodes/comfyui_controlnet_aux
pip3 install -r requirements.txt

 # comfyui-inpaint-nodes
git clone https://github.com/Acly/comfyui-inpaint-nodes.git \
  /ComfyUI/custom_nodes/comfyui-inpaint-nodes

# masquerade-nodes-comfyui
git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui.git \
  /ComfyUI/custom_nodes/masquerade-nodes-comfyui

# ComfyUI-Florence2
git clone https://github.com/kijai/ComfyUI-Florence2.git \
  /ComfyUI/custom_nodes/ComfyUI-Florence2

cd /ComfyUI/custom_nodes/ComfyUI-Florence2
pip3 install -r requirements.txt

# ComfyUI-segment-anything-2
git clone https://github.com/kijai/ComfyUI-segment-anything-2.git \
  /ComfyUI/custom_nodes/ComfyUI-segment-anything-2

# ComfyUI_essentials
git clone https://github.com/cubiq/ComfyUI_essentials.git \
  /ComfyUI/custom_nodes/ComfyUI_essentials

cd /ComfyUI/custom_nodes/ComfyUI_essentials
pip3 install -r requirements.txt

# Install ComfyUI-FastAPI
cd /ComfyUI
git clone https://github.com/hzeyuan/comfyui-fastapi.git 
cd /ComfyUI/comfyui-fastapi
pip3 install -r requirements.txt

pip3 cache purge

# Fix some incorrect modules
pip3 install numpy==1.26.4
cd /ComfyUI
pip3 install -r requirements.txt
deactivate
