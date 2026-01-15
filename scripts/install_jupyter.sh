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

if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" python="$PY_VER"
fi

conda install -y -n "$ENV_NAME" -c conda-forge \
  jupyterlab \
  ipykernel \
  numpy \
  pandas \
  matplotlib \
  scipy

conda run -n "$ENV_NAME" python -m ipykernel install --user \
  --name "$ENV_NAME" \
  --display-name "Python ($ENV_NAME)"

echo "env ready: $ENV_NAME"
