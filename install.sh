#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
msg() { printf '%s\n' "$*"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }
have_dpkg_pkg() { dpkg -s "$1" >/dev/null 2>&1; }

run_step() {
  local name="$1"
  local script="$2"
  local path="$ROOT_DIR/$script"
  if [ -f "$path" ]; then
    msg "==> [RUN] $name"
    bash "$path"
  else
    msg "==> [SKIP] $name (missing: $script)"
  fi
}

skip_step() { msg "==> [SKIP] $1 (already present)"; }

# -----------------------------
# config
# -----------------------------
CONFIG="$ROOT_DIR/config.sh"
if [ -f "$CONFIG" ]; then
  # shellcheck source=./config.sh
  source "$CONFIG"
else
  msg "config.sh not found: $CONFIG"
  exit 1
fi

have_miniconda() {
  [ -d "$CONDA_DIR" ] && [ -f "$CONDA_DIR/etc/profile.d/conda.sh" ]
}

have_conda_env() {
  local envname="$1"
  have_miniconda || return 1
  # shellcheck disable=SC1091
  source "$CONDA_DIR/etc/profile.d/conda.sh"
  conda env list | awk '{print $1}' | grep -qx "$envname"
}

have_jupyterlab_in_env() {
  local envname="$1"
  have_conda_env "$envname" || return 1
  # shellcheck disable=SC1091
  source "$CONDA_DIR/etc/profile.d/conda.sh"
  conda run -n "$envname" jupyter lab --version >/dev/null 2>&1
}

have_user_systemd_unit_enabled_or_running() {
  local unit="$1"
  have_cmd systemctl || return 1
  systemctl --user is-enabled "$unit" >/dev/null 2>&1 && return 0
  systemctl --user is-active  "$unit" >/dev/null 2>&1 && return 0
  return 1
}

# base packages
run_step "base packages" "scripts/install_base.sh"

# apptainer
if have_cmd apptainer; then
  skip_step "apptainer"
else
  run_step "apptainer" "scripts/install_apptainer.sh"
fi

# miniconda
if have_miniconda; then
  skip_step "miniconda"
else
  run_step "miniconda" "scripts/install_miniconda.sh"
fi

# lab env + jupyterlab
if have_jupyterlab_in_env "$CONDA_ENV_NAME"; then
  skip_step "conda env + jupyterlab"
else
  run_step "conda env + jupyterlab" "scripts/install_jupyter.sh"
fi

# jupyterlab service (optional)
if [ "$ENABLE_JUPYTER_SERVICE" = "1" ]; then
  if have_user_systemd_unit_enabled_or_running "jupyterlab.service"; then
    skip_step "jupyterlab service"
  else
    run_step "jupyterlab service" "scripts/install_jupyter_service.sh"
  fi
else
  msg "==> [SKIP] jupyterlab service (disabled by config.sh)"
fi

# rstudio-server (optional)
if [ "$ENABLE_RSTUDIO" = "1" ]; then
  if have_dpkg_pkg "rstudio-server"; then
    skip_step "rstudio-server"
  else
    run_step "rstudio-server" "scripts/install_rstudio.sh"
  fi
else
  msg "==> [SKIP] rstudio-server (disabled by config.sh)"
fi

msg "=== INSTALL DONE ==="
