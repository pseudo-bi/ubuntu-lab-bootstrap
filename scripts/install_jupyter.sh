#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config.sh"

MINICONDA_DIR="$CONDA_DIR"
ENV_NAME="$CONDA_ENV_NAME"
PY_VER="$CONDA_PYTHON_VERSION"

if [ ! -f "$MINICONDA_DIR/etc/profile.d/conda.sh" ]; then
  echo "conda.sh not found: $MINICONDA_DIR/etc/profile.d/conda.sh"
  exit 1
fi

# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"

conda_accept_tos_if_supported() {
  # conda 24.x 以降などで ToS が必須になった場合に備える
  if conda tos --help >/dev/null 2>&1; then
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null 2>&1 || true
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r    >/dev/null 2>&1 || true
  fi
}

conda_accept_tos_if_supported

# env 作成（無ければ）
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" python="$PY_VER"
fi

conda_accept_tos_if_supported

# JupyterLab 等を導入（conda-forge）
conda install -y -n "$ENV_NAME" -c conda-forge \
  jupyterlab \
  ipykernel \
  numpy \
  pandas \
  matplotlib \
  scipy

# kernel 登録（ユーザー領域）
conda run -n "$ENV_NAME" python -m ipykernel install --user \
  --name "$ENV_NAME" \
  --display-name "Python ($ENV_NAME)"

echo "env ready: $ENV_NAME"
