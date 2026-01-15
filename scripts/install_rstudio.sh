#!/usr/bin/env bash
set -e

# Step 11: Install RStudio Server (best-effort, idempotent-ish)
# amd64: install via Posit-provided .deb (Ubuntu 24 instructions currently point to jammy/amd64)
# arm64: stable builds are not generally provided; daily builds exist but are experimental -> default skip

ARCH="$(dpkg --print-architecture)"
DEB_URL_AMD64="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2026.01.0-392-amd64.deb"
DEB_FILE="/tmp/rstudio-server-${ARCH}.deb"

if dpkg -s rstudio-server >/dev/null 2>&1; then
  echo "rstudio-server already installed"
  exit 0
fi

sudo apt-get update -y
sudo apt-get install -y gdebi-core

if [ "$ARCH" = "amd64" ]; then
  cd /tmp
  wget -O "$DEB_FILE" "$DEB_URL_AMD64"
  sudo gdebi -n "$DEB_FILE"
  sudo systemctl enable --now rstudio-server
  echo "RStudio Server enabled (port 8787)"
  exit 0
fi

if [ "$ARCH" = "arm64" ]; then
  if [ "${ALLOW_RSTUDIO_DAILY_ARM64:-0}" = "1" ]; then
    echo "arm64 detected. Posit stable builds are not generally available; daily builds are experimental."
    echo "Install manually from the noble-arm64 daily index if you accept the risk."
    echo "https://dailies.rstudio.com/rstudio/kousa-dogwood/server/noble-arm64/"
    exit 2
  fi
  echo "arm64 detected. Skipping RStudio Server install (set ALLOW_RSTUDIO_DAILY_ARM64=1 to allow experimental manual path)."
  exit 0
fi

echo "Unsupported architecture: $ARCH"
exit 1
