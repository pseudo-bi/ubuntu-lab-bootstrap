#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config.sh"

msg() { printf '%s\n' "$*"; }

MINICONDA_DIR="$CONDA_DIR"
ENV_NAME="$CONDA_ENV_NAME"
PY_VER="$CONDA_PYTHON_VERSION"

: "${ENABLE_CONDA_AUTO_ACTIVATE:=0}"   # 0: 作らない, 1: /etc/profile.d/conda-lab.sh を作る

if [ ! -f "$MINICONDA_DIR/etc/profile.d/conda.sh" ]; then
  msg "conda.sh not found: $MINICONDA_DIR/etc/profile.d/conda.sh"
  exit 1
fi

# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"

conda_accept_tos_if_supported() {
  if conda tos --help >/dev/null 2>&1; then
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null 2>&1 || true
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r    >/dev/null 2>&1 || true
  fi
}

install_conda_lab_profile() {
  local dst="/etc/profile.d/conda-lab.sh"
  local tmp
  tmp="$(mktemp)"

  printf "%s\n" \
"# ubuntu-lab-bootstrap: optional auto-activate ${ENV_NAME} for interactive bash" \
"if [ -n \"\${BASH_VERSION-}\" ] && [[ \$- == *i* ]]; then" \
"  _ulb_conda=\"${MINICONDA_DIR}/etc/profile.d/conda.sh\"" \
"  if [ -f \"\$_ulb_conda\" ]; then" \
"    . \"\$_ulb_conda\"" \
"    __ulb_activate_lab_once() {" \
"      if [ -z \"\${__ULB_LAB_DONE-}\" ]; then" \
"        __ULB_LAB_DONE=1" \
"        conda activate \"${ENV_NAME}\" >/dev/null 2>&1 || true" \
"      fi" \
"      case \"\${PROMPT_COMMAND-}\" in" \
"        __ulb_activate_lab_once*) PROMPT_COMMAND=\${PROMPT_COMMAND#__ulb_activate_lab_once; } ;;" \
"      esac" \
"    }" \
"    if [ -n \"\${PROMPT_COMMAND-}\" ]; then" \
"      PROMPT_COMMAND=\"__ulb_activate_lab_once; \$PROMPT_COMMAND\"" \
"    else" \
"      PROMPT_COMMAND=\"__ulb_activate_lab_once\"" \
"    fi" \
"  fi" \
"fi" \
> "$tmp"

  sudo install -m 0644 "$tmp" "$dst"
  rm -f "$tmp"
  msg "profile.d installed: $dst"
}

conda_accept_tos_if_supported

if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  msg "==> conda create: $ENV_NAME (python=$PY_VER)"
  conda create -y -n "$ENV_NAME" python="$PY_VER"
else
  msg "==> conda env exists: $ENV_NAME"
fi

conda_accept_tos_if_supported

msg "==> conda install (conda-forge): jupyterlab + scientific stack"
conda install -y -n "$ENV_NAME" -c conda-forge \
  jupyterlab \
  ipykernel \
  numpy \
  pandas \
  matplotlib \
  scipy

msg "==> install kernelspec system-wide (visible to all users)"
sudo mkdir -p /usr/local/share/jupyter
conda run -n "$ENV_NAME" python -m ipykernel install \
  --prefix=/usr/local \
  --name "$ENV_NAME" \
  --display-name "Python ($ENV_NAME)"

if [ "$ENABLE_CONDA_AUTO_ACTIVATE" = "1" ]; then
  msg "==> install /etc/profile.d/conda-lab.sh (auto-activate enabled)"
  install_conda_lab_profile
else
  msg "==> skip /etc/profile.d/conda-lab.sh (auto-activate disabled)"
fi

msg "env ready: $ENV_NAME"
msg "kernelspec installed under: /usr/local/share/jupyter/kernels/$ENV_NAME"
