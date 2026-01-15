#!/usr/bin/env bash
set -e

# Base packages for Ubuntu 24.04
# Marker file is used to avoid re-running on every install.sh execution.
MARKER="/var/local/ubuntu-lab-bootstrap/base.done"

if [ -f "$MARKER" ]; then
  echo "base packages already installed (marker exists: $MARKER)"
  exit 0
fi

sudo apt-get update -y

sudo apt-get install -y \
  ca-certificates \
  curl \
  wget \
  git \
  gnupg \
  lsb-release \
  software-properties-common \
  build-essential \
  pkg-config \
  unzip \
  zip \
  tar \
  jq \
  tree \
  htop \
  tmux \
  openssh-client \
  python3 \
  python3-venv \
  python3-pip

# marker
sudo mkdir -p /var/local/ubuntu-lab-bootstrap
sudo touch "$MARKER"

echo "base packages installed (marker created: $MARKER)"
