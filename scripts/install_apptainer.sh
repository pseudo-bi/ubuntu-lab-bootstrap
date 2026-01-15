#!/usr/bin/env bash
set -e

# Apptainer install for Ubuntu 24.04+
# Intel/AMD = amd64, ARM = arm64 (apt が自動選択)

sudo apt update
sudo apt install -y software-properties-common

sudo add-apt-repository -y ppa:apptainer/ppa
sudo apt update
sudo apt install -y apptainer

apptainer version
