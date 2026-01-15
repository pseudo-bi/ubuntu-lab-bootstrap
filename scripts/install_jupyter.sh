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
  if conda tos --help >/dev/null 2>&1; then
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main >/dev/null 2>&1 || true
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r    >/dev/null 2>&1 || true
  fi
}

install_conda_lab_profile() {
  local dst="/etc/profile.d/conda-lab.sh"
  local tmp
  tmp="$(mktemp)"

  # /etc/profile.d に置くファイルは、環境依存パスを埋め込んだ生成物にする
  printf "%s\n" \
"# ubuntu-lab-bootstrap: auto-activate ${ENV_NAME} once, after shell init (interactive bash)" \
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
}

conda_accept_tos_if_supported

if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" python="$PY_VER"
fi

conda_accept_tos_if_supported

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

install_conda_lab_profile

echo "env ready: $ENV_NAME"
echo "profile.d installed: /etc/profile.d/conda-lab.sh"
