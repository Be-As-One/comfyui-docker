ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Workflow-specific build argument
ARG WORKFLOW=comm
ENV WORKFLOW=${WORKFLOW}

# Copy the build scripts for the specific workflow
WORKDIR /
COPY --chmod=755 build/${WORKFLOW}/* ./
# Copy all build scripts to /build/ directory for runtime use
COPY --chmod=755 build/ /build/

# Copy the scripts and config files needed by install scripts
COPY --chmod=755 scripts/* ./
COPY config/ /config/

# Install ComfyUI
ARG TORCH_VERSION
ARG XFORMERS_VERSION
ARG INDEX_URL
ARG COMFYUI_COMMIT
# RUN mv ./requirements.txt ./ComfyUI/requirements.txt
RUN /install.sh

# Install FastAPI (shared across all environments)
RUN /install_fastapi.sh


# Install CivitAI Model Downloader
ARG CIVITAI_DOWNLOADER_VERSION
RUN /install_civitai_model_downloader.sh

# Cleanup installation scripts from root directory only (keep them in /build/)
RUN rm -f /install*.sh /comm-models-download.sh /install_civitai_model_downloader.sh /requirements.txt

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


# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
