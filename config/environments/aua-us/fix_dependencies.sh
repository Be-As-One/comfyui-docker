#!/usr/bin/env bash
set -e

# Fix dependencies for aua-us environment
pip3 cache purge

# Fix some incorrect modules
pip3 install numpy==1.26.4
pip3 install onnxruntime-gpu==1.18.1
pip3 install -r requirements.txt