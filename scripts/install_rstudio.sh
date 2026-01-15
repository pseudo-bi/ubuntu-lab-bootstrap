#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config.sh"

if [ "${ENABLE_RSTUDIO:-1}" -ne 1 ]; then
  echo "RStudio disabled (ENABLE_RSTUDIO=${ENABLE_RSTUDIO})"
  exit 0
fi

need_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "Installing R (if missing)..."
if ! need_cmd R; then
  sudo apt-get update
  sudo apt-get install -y r-base
fi

R_PATH="$(readlink -f "$(command -v R)")"
echo "Detected R: $R_PATH"

echo "Installing rstudio-server (if missing)..."
if ! dpkg -s rstudio-server >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y rstudio-server
fi

echo "Configuring /etc/rstudio/rserver.conf ..."
sudo mkdir -p /etc/rstudio
# 既存設定を壊さず、rsession-which-r だけを確実に入れる
if [ -f /etc/rstudio/rserver.conf ]; then
  sudo sed -i '/^rsession-which-r=/d' /etc/rstudio/rserver.conf
fi
echo "rsession-which-r=$R_PATH" | sudo tee -a /etc/rstudio/rserver.conf >/dev/null

echo "Restarting rstudio-server..."
sudo systemctl enable rstudio-server
sudo systemctl restart rstudio-server || true

if sudo systemctl is-active --quiet rstudio-server; then
  echo "RStudio Server active (port ${RSTUDIO_PORT:-8787})"
else
  echo "RStudio Server failed. Recent logs:"
  sudo journalctl -u rstudio-server.service -b --no-pager | tail -n 80
  exit 1
fi
