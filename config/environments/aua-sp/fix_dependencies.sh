#!/usr/bin/env bash
set -e

# Fix dependencies for aua-sp environment
pip3 cache purge

# Fix some incorrect modules
pip3 install numpy==1.26.4
pip3 install -r requirements.txt