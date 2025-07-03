#!/usr/bin/env bash
set -e

# Fix dependencies for comm environment
pip3 cache purge

pip3 install omegaconf
pip install  diffusers
# Fix some incorrect modules
pip3 install -r /build/tts/requirements.txt