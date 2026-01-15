#!/usr/bin/env bash
set -e

# Uninstaller / rollback for this bootstrap repo
# Targets (best-effort):
# - JupyterLab user service
# - conda env "lab"
# - miniconda at ~/miniconda3 (optional)
# - RStudio Server
# - Apptainer
#
# Notes:
# - This script is intentionally conservative.
# - It removes what we installed, but will not remove unrelated user data.

MINICONDA_DIR="$HOME/miniconda3"
ENV_NAME="lab"

echo "== Stop/disable JupyterLab user service (if exists) =="
if systemctl --user list-unit-files 2>/dev/null | awk '{print $1}' | grep -qx "jupyterlab.service"; then
  systemctl --user disable --now jupyterlab.service || true
  systemctl --user daemon-reload || true
fi

UNIT_FILE="$HOME/.config/systemd/user/jupyterlab.service"
if [ -f "$UNIT_FILE" ]; then
  rm -f "$UNIT_FILE"
  systemctl --user daemon-reload || true
fi

echo "== Remove conda env: ${ENV_NAME} (if conda exists) =="
if [ -f "$MINICONDA_DIR/etc/profile.d/conda.sh" ]; then
  # shellcheck disable=SC1090
  source "$MINICONDA_DIR/etc/profile.d/conda.sh"
  if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    conda env remove -y -n "$ENV_NAME" || true
  fi
fi

echo "== Remove Jupyter kernel spec for ${ENV_NAME} (best-effort) =="
KERNEL_DIR="$HOME/.local/share/jupyter/kernels/${ENV_NAME}"
if [ -d "$KERNEL_DIR" ]; then
  rm -rf "$KERNEL_DIR"
fi

echo "== Uninstall RStudio Server (if installed) =="
if dpkg -l 2>/dev/null | awk '{print $2}' | grep -qx "rstudio-server"; then
  sudo systemctl disable --now rstudio-server || true
  sudo apt remove -y rstudio-server || true
  sudo apt autoremove -y || true
fi

echo "== Uninstall Apptainer (if installed via apt) =="
if dpkg -l 2>/dev/null | awk '{print $2}' | grep -qx "apptainer"; then
  sudo apt remove -y apptainer || true
  sudo apt autoremove -y || true
fi

echo "== Optionally remove Miniconda directory =="
echo "   If you want to delete ${MINICONDA_DIR}, run:"
echo "     rm -rf \"${MINICONDA_DIR}\""
echo "   (Not deleting automatically to avoid data loss.)"

echo "== Note about ~/.bashrc changes =="
echo "   This repo added small conda-related blocks to ~/.bashrc."
echo "   They are not removed automatically. If needed, remove lines containing:"
echo "     miniconda3/etc/profile.d/conda.sh"
echo "     auto-activate lab conda env"

echo "== DONE =="
