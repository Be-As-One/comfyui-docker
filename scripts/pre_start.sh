#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="ComfyUI"

TEMPLATE_NAME="comfyui"
COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT:-"comm"}
TEMPLATE_VERSION_FILE="/workspace/${APP}-${COMFYUI_ENVIRONMENT}/template.json"

echo "TEMPLATE NAME: ${TEMPLATE_NAME}"
echo "TEMPLATE VERSION: ${TEMPLATE_VERSION}"
echo "VENV PATH: /workspace/${APP}/venv"

if [[ -e ${TEMPLATE_VERSION_FILE} ]]; then
    EXISTING_TEMPLATE_NAME=$(jq -r '.template_name // empty' "$TEMPLATE_VERSION_FILE")

    if [[ -n "${EXISTING_TEMPLATE_NAME}" ]]; then
        if [[ "${EXISTING_TEMPLATE_NAME}" != "${TEMPLATE_NAME}" ]]; then
            EXISTING_VERSION="0.0.0"
        else
            EXISTING_VERSION=$(jq -r '.template_version // empty' "$TEMPLATE_VERSION_FILE")
        fi
    else
        EXISTING_VERSION="0.0.0"
    fi
else
    EXISTING_VERSION="0.0.0"
fi

save_template_json() {
    cat << EOF > ${TEMPLATE_VERSION_FILE}
{
    "template_name": "${TEMPLATE_NAME}",
    "template_version": "${TEMPLATE_VERSION}"
}
EOF
}

sync_directory() {
    local src_dir="$1"
    local dst_dir="$2"
    local use_compression=${3:-false}

    echo "SYNC: Syncing from ${src_dir} to ${dst_dir}, please wait (this can take a few minutes)..."
    echo "SYNC: Note - existing files will NOT be overwritten"

    # 确保目标目录存在
    mkdir -p "${dst_dir}"

    # 检查 /workspace 所在的文件系统类型
    local workspace_fs=$(df -T /workspace | awk 'NR==2 {print $2}')
    echo "SYNC: File system type: ${workspace_fs}"

    # 使用 tar 进行同步（主要用于 fuse 文件系统，例如 RunPod 上挂载的网络卷）
    if [ "${workspace_fs}" = "fuse" ]; then
        if [ "$use_compression" = true ]; then
            echo "SYNC: Using tar with zstd compression for sync (skip existing files)"
        else
            echo "SYNC: Using tar without compression for sync (skip existing files)"
        fi

        # 计算源目录总大小（用于进度条显示）
        local total_size=$(du -sb "${src_dir}" | cut -f1)

        # 构建 tar 命令（排除临时文件、日志和venv）
        local tar_cmd="tar --create \
            --file=- \
            --directory="${src_dir}" \
            --exclude='*.pyc' \
            --exclude='__pycache__' \
            --exclude='*.log' \
            --exclude='venv' \
            --blocking-factor=64 \
            --record-size=64K \
            --sparse \
            ."

        # 构建 tar 解压命令（添加 --skip-old-files 参数不覆盖已存在的文件）
        local tar_extract_cmd="tar --extract \
            --file=- \
            --directory="${dst_dir}" \
            --blocking-factor=64 \
            --record-size=64K \
            --sparse \
            --skip-old-files"

        if [ "$use_compression" = true ]; then
            $tar_cmd | zstd -T0 -1 | pv -s ${total_size} | zstd -d -T0 | $tar_extract_cmd
        else
            $tar_cmd | pv -s ${total_size} | $tar_extract_cmd
        fi

    # 使用 rsync 进行同步（更常见的 overlay / xfs 文件系统）
    elif [ "${workspace_fs}" = "overlay" ] || [ "${workspace_fs}" = "xfs" ]; then
        echo "SYNC: Using rsync for sync (skip existing files)"
        rsync -rlptDu \
            --ignore-existing \
            --exclude='venv' \
            "${src_dir}/" "${dst_dir}/"
    else
        echo "SYNC: Unknown filesystem type (${workspace_fs}) for /workspace, defaulting to rsync (skip existing files)"
        rsync -rlptDu \
            --ignore-existing \
            --exclude='venv' \
            "${src_dir}/" "${dst_dir}/"
    fi
}


sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        echo "SYNC: Syncing to persistent storage started"

        # Start the timer
        start_time=$(date +%s)

        echo "SYNC: Sync 1 of 1"
        # Get the current environment (defaults to comm)
        COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT:-"comm"}
        sync_directory "/${APP}" "/workspace/${APP}-${COMFYUI_ENVIRONMENT}"
        save_template_json
        echo "${VENV_PATH}" > "/workspace/${APP}-${COMFYUI_ENVIRONMENT}/venv_path"
        
        # Create venv in workspace if it doesn't exist
        WORKSPACE_VENV_PATH="/workspace/${APP}-${COMFYUI_ENVIRONMENT}/venv"
        if [ ! -d "${WORKSPACE_VENV_PATH}" ]; then
            echo "SYNC: Creating Python virtual environment in workspace..."
            cd "/workspace/${APP}-${COMFYUI_ENVIRONMENT}"
            
            # Copy venv from container
            echo "SYNC: Copying venv from container..."
            cp -r "/${APP}/venv" "${WORKSPACE_VENV_PATH}"
            
            echo "SYNC: Virtual environment created successfully"
        else
            echo "SYNC: Virtual environment already exists in workspace"
        fi

        # End the timer and calculate the duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        # Convert duration to minutes and seconds
        minutes=$((duration / 60))
        seconds=$((duration % 60))

        echo "SYNC: Syncing COMPLETE!"
        printf "SYNC: Time taken: %d minutes, %d seconds\n" ${minutes} ${seconds}
    fi
}


if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        # Only proceed with sync if DISABLE_SYNC is not set
        if [ -z "${DISABLE_SYNC}" ]; then
            # 强制删除现有的 venv 以确保完全重新同步
            echo "SYNC: Removing existing venv to ensure clean sync..."
            COMFYUI_ENVIRONMENT=${COMFYUI_ENVIRONMENT:-"comm"}
            rm -rf /workspace/ComfyUI-${COMFYUI_ENVIRONMENT}/venv

            sync_apps

            # Create logs directory
            mkdir -p /workspace/logs
        else
            echo "SYNC: Sync disabled by DISABLE_SYNC environment variable"
        fi
    else
        echo "SYNC: Existing version is the same as the template version, no syncing required."
    fi
else
    echo "SYNC: Existing version is newer than the template version, not syncing!"
fi

# Start application manager
# cd /app-manager
# npm start > /workspace/logs/app-manager.log 2>&1 &

# Start FastAPI service
/start_fastapi.sh

# ComfyUI auto-launch enabled by default to provide fallback FastAPI service
DISABLE_AUTOLAUNCH=${DISABLE_AUTOLAUNCH:-false}

if [[ ${DISABLE_AUTOLAUNCH} == "true" ]]
then
    echo "ComfyUI auto-launch is disabled (default behavior)"
    echo "ComfyUI instances can be started via external API calls or manually using:"
    echo "   /start_comfyui.sh <instance_id>"
else
    echo "Starting ComfyUI automatically..."
    /start_comfyui.sh 0
fi

echo "Pre-start initialization completed"
