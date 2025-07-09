#!/usr/bin/env bash
set -e

# Fix dependencies for comm environment
pip3 cache purge

# Fix some incorrect modules
pip3 install numpy==1.26.4
pip3 install -r  build/fusionx-image2video/requirements.txt