# 下载模型
huggingface-cli download ByteDance/Hyper-SD Hyper-SD15-8steps-lora.safetensors --local-dir /workspace/ComfyUI/models/loras

huggingface-cli download comfyanonymous/ControlNet-v1-1_fp16_safetensors \
  control_v11p_sd15_openpose_fp16.safetensors \
  --local-dir /workspace/ComfyUI/models/controlnet


huggingface-cli download dputilov/exp \
  epicrealism_v10-inpainting.safetensors \
  --repo-type dataset \
  --local-dir /workspace/ComfyUI/models/checkpoints


huggingface-cli download Comfy-Org/stable-diffusion-v1-5-archive \
  v1-5-pruned-emaonly-fp16.safetensors \
  --local-dir /workspace/ComfyUI/models/checkpoints

# 下载custom_nodes

git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git \
  /workspace/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet


git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git \
  /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux


git clone https://github.com/Acly/comfyui-inpaint-nodes.git \
  /workspace/ComfyUI/custom_nodes/comfyui-inpaint-nodes


git clone https://github.com/BadCafeCode/masquerade-nodes-comfyui.git \
  /workspace/ComfyUI/custom_nodes/masquerade-nodes-comfyui


git clone https://github.com/kijai/ComfyUI-Florence2.git \
  /workspace/ComfyUI/custom_nodes/ComfyUI-Florence2

git clone https://github.com/kijai/ComfyUI-segment-anything-2.git \
  /workspace/ComfyUI/custom_nodes/ComfyUI-segment-anything-2

git clone https://github.com/cubiq/ComfyUI_essentials.git \
  /workspace/ComfyUI/custom_nodes/ComfyUI_essentials