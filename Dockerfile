ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Workflow-specific build argument
ARG WORKFLOW=comm
ENV WORKFLOW=${WORKFLOW}

# Copy the build scripts for the specific workflow
WORKDIR /
COPY --chmod=755 build/${WORKFLOW}/* ./

# Install ComfyUI
ARG TORCH_VERSION
ARG XFORMERS_VERSION
ARG INDEX_URL
ARG COMFYUI_COMMIT
# RUN mv ./requirements.txt ./ComfyUI/requirements.txt
RUN /install_comfyui.sh


# Install CivitAI Model Downloader
ARG CIVITAI_DOWNLOADER_VERSION
RUN /install_civitai_model_downloader.sh

# Cleanup installation scripts
RUN rm -f /install_*.sh

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the main venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
