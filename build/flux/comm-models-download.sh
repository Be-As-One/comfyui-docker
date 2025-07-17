
#!/bin/bash

# 辅助函数：安全地克隆仓库
git_clone_safe() {
    local repo_url="$1"
    local target_dir="$2"
    
    if [ -d "$target_dir" ]; then
        echo "✓ Already exists: $(basename "$target_dir")"
    else
        echo "→ Cloning: $(basename "$target_dir")"
        git clone "$repo_url" "$target_dir"
    fi
}

# 辅助函数：安全地下载文件
curl_download_safe() {
    local url="$1"
    local target_file="$2"
    
    # 确保目标目录存在
    mkdir -p "$(dirname "$target_file")"
    
    if [ -f "$target_file" ]; then
        echo "✓ Already exists: $(basename "$target_file")"
    else
        echo "→ Downloading: $(basename "$target_file")"
        curl -L "$url" -o "$target_file"
    fi
}

# 下载custom_nodes

git_clone_safe "https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet"


git_clone_safe "https://github.com/Fannovel16/comfyui_controlnet_aux.git" \
  "/workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux"
cd /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux
pip3 install -r requirements.txt

git_clone_safe "https://github.com/Acly/comfyui-inpaint-nodes.git" \
  "/workspace/ComfyUI/custom_nodes/comfyui-inpaint-nodes"


git_clone_safe "https://github.com/BadCafeCode/masquerade-nodes-comfyui.git" \
  "/workspace/ComfyUI/custom_nodes/masquerade-nodes-comfyui"


git_clone_safe "https://github.com/kijai/ComfyUI-Florence2.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-Florence2"

cd /workspace/ComfyUI/custom_nodes/ComfyUI-Florence2
pip3 install -r requirements.txt

git_clone_safe "https://github.com/kijai/ComfyUI-segment-anything-2.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-segment-anything-2"

git_clone_safe "https://github.com/cubiq/ComfyUI_essentials.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_essentials"
cd /workspace/ComfyUI/custom_nodes/ComfyUI_essentials
pip3 install -r requirements.txt

git_clone_safe "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-Custom-Scripts"

git_clone_safe "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_Comfyroll_CustomNodes"

git_clone_safe "https://github.com/ShmuelRonen/ComfyUI-Gemini_Flash_2.0_Exp.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-Gemini_Flash_2.0_Exp"



git_clone_safe "https://github.com/kijai/ComfyUI-KJNodes.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-KJNodes"
cd  /workspace/ComfyUI/custom_nodes/ComfyUI-KJNodes
pip3 install -r requirements.txt

git_clone_safe "https://github.com/WaddingtonHoldings/ComfyUI-InstaSD.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-InstaSD" 
cd  /workspace/ComfyUI/custom_nodes/ComfyUI-InstaSD 
pip3 install -r requirements.txt



## 下载模型
curl_download_safe "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_openpose_fp16.safetensors" \
  "/workspace/shared-models/controlnet/control_v11p_sd15_openpose_fp16.safetensors"


huggingface-cli download dputilov/exp \
  epicrealism_v10-inpainting.safetensors \
  --repo-type dataset \
  --local-dir /workspace/shared-models/checkpoints



curl_download_safe "https://huggingface.co/ByteDance/Hyper-SD/resolve/main/Hyper-SD15-8steps-lora.safetensors" \
  "/workspace/shared-models/loras/Hyper-SD15-8steps-lora.safetensors"