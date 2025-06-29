
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

curl_download_safe "https://storage.googleapis.com/model-file/comfy/lustifySDXLNSFW_oltFIXEDTEXTURES.safetensors" \
  "/workspace/shared-models/checkpoints/lustifySDXLNSFW_oltFIXEDTEXTURES.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/Hyper-SDXL-8steps-lora.safetensors" \
  "/workspace/shared-models/loras/Hyper-SDXL-8steps-lora.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/female orgasm-SDXL-V1.safetensors" \
  "/workspace/shared-models/loras/female orgasm-SDXL-V1.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/comfy-diylab/models/instantid/ip-adapter-instantid.bin" \
  "/workspace/shared-models/instantid/ip-adapter-instantid.bin"

curl_download_safe "https://storage.googleapis.com/model-file/comfy-diylab/models/insightface/inswapper_128.onnx" \
  "/workspace/shared-models/insightface/inswapper_128.onnx"

curl_download_safe "https://storage.googleapis.com/model-file/comfy-diylab/models/controlnet/diffusion_pytorch_model.safetensors" \
  "/workspace/shared-models/controlnet/diffusion_pytorch_model.safetensors"

curl_download_safe "https://huggingface.co/moiu2998/mymo/resolve/3c3093fa083909be34a10714c93874ce5c9dabc4/realisticVisionV60B1_v51VAE.safetensors" \
  "/workspace/shared-models/checkpoints/realisticVisionV60B1_v51VAE.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/cumfacial55_v2.safetensors" \
  "/workspace/shared-models/loras/cumfacial55_v2.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/cum_b1.safetensors" \
  "/workspace/shared-models/loras/cum_b1.safetensors"

curl_download_safe "https://huggingface.co/liamhvn/epiCPhotoGasm-ultimate-fidelity/resolve/main/epicphotogasm_ultimateFidelity.safetensors" \
  "/workspace/shared-models/checkpoints/epicphotogasm_ultimateFidelity.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/cuminmouth.safetensors" \
  "/workspace/shared-models/loras/cuminmouth.safetensors"

curl_download_safe "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_openpose_fp16.safetensors" \
  "/workspace/shared-models/controlnet/control_v11p_sd15_openpose_fp16.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/comfy-diylab/models/insightface.zip" \
  "/workspace/shared-models/insightface.zip"

unzip /workspace/shared-models/insightface.zip -d /workspace/shared-models/insightface

rm /workspace/shared-models/insightface.zip

curl_download_safe "https://storage.googleapis.com/model-file/comfy/pornmaster_proSDXLV4VAE-nsfw.safetensors" \
  "/workspace/shared-models/checkpoints/pornmaster_proSDXLV4VAE-nsfw.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/comfy-lite/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" \
  "/workspace/shared-models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"

curl_download_safe "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin" \
  "/workspace/shared-models/ipadapter/ip-adapter-faceid-plusv2_sdxl.bin"

curl_download_safe "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl_lora.safetensors" \
  "/workspace/shared-models/loras/ip-adapter-faceid-plusv2_sdxl_lora.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/gagged-4e.safetensors" \
  "/workspace/shared-models/loras/gagged-4e.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/shibari_v20.safetensors" \
  "/workspace/shared-models/loras/shibari_v20.safetensors"

curl_download_safe "https://huggingface.co/ByteDance/Hyper-SD/resolve/main/Hyper-SD15-8steps-lora.safetensors" \
  "/workspace/shared-models/loras/Hyper-SD15-8steps-lora.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/comfy/cyberrealistic_v80Inpainting.safetensors" \
  "/workspace/shared-models/checkpoints/cyberrealistic_v80Inpainting.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/betterleashes-000012.safetensors" \
  "/workspace/shared-models/loras/betterleashes-000012.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/Wetshirt.safetensors" \
  "/workspace/shared-models/loras/Wetshirt.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/CrotchlessPantsV1A10.safetensors" \
  "/workspace/shared-models/loras/CrotchlessPantsV1A10.safetensors"

curl_download_safe "https://storage.googleapis.com/model-file/lora/1.5/2FingersSDXL_v03.safetensors" \
  "/workspace/shared-models/loras/2FingersSDXL_v03.safetensors"



git_clone_safe "https://github.com/cubiq/ComfyUI_InstantID.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_InstantID"

git_clone_safe "https://github.com/kijai/ComfyUI-KJNodes.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-KJNodes"

git_clone_safe "https://github.com/nullquant/ComfyUI-BrushNet.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-BrushNet"

git_clone_safe "https://github.com/cubiq/ComfyUI_FaceAnalysis.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_FaceAnalysis"

git_clone_safe "https://github.com/vuongminh1907/ComfyUI_ZenID.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_ZenID"

git_clone_safe "https://github.com/WaddingtonHoldings/ComfyUI-InstaSD.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-InstaSD"

git_clone_safe "https://github.com/tsogzark/ComfyUI-load-image-from-url.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-load-image-from-url"

git_clone_safe "https://github.com/papcorns/ComfyUI-Papcorns-Node-LoadImageFromUrl.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-Papcorns-Node-LoadImageFromUrl"

git_clone_safe "https://github.com/jqy-yo/Comfyui-BBoxLowerMask2.git" \
  "/workspace/ComfyUI/custom_nodes/Comfyui-BBoxLowerMask2"

git_clone_safe "https://github.com/yolain/ComfyUI-Easy-Use.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI-Easy-Use"

pip install insightface onnxruntime diffusers

git_clone_safe "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_IPAdapter_plus"

git_clone_safe "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git" \
  "/workspace/ComfyUI/custom_nodes/ComfyUI_Comfyroll_CustomNodes"