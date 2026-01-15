#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

msg() { printf '%s\n' "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

have_dpkg_pkg() {
  dpkg -s "$1" >/dev/null 2>&1
}

have_miniconda() {
  [ -d "$HOME/miniconda3" ] && [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]
}

have_conda_env() {
  # usage: have_conda_env <envname>
  local envname="$1"
  have_miniconda || return 1
  # shellcheck disable=SC1090
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
  conda env list | awk '{print $1}' | grep -qx "$envname"
}

have_jupyterlab_in_env() {
  # usage: have_jupyterlab_in_env <envname>
  local envname="$1"
  have_conda_env "$envname" || return 1
  # shellcheck disable=SC1090
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
  conda run -n "$envname" jupyter lab --version >/dev/null 2>&1
}

have_user_systemd_unit_enabled_or_running() {
  # usage: have_user_systemd_unit_enabled_or_running <unit>
  local unit="$1"
  if ! have_cmd systemctl; then
    return 1
  fi
  # systemd user session が無い環境でも落ちないよう best-effort
  systemctl --user is-enabled "$unit" >/dev/null 2>&1 && return 0
  systemctl --user is-active  "$unit" >/dev/null 2>&1 && return 0
  return 1
}

run_step() {
  # usage: run_step "name" "script_path"
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

skip_step() {
  msg "==> [SKIP] $1 (already present)"
}

# -----------------------------
# base packages
# ここは厳密検出が難しいので毎回走らせてもよい（apt は冪等に近い）
# 「base を毎回回したくない」場合は、マーカー方式にもできます
# -----------------------------
run_step "base packages" "scripts/install_base.sh"

# -----------------------------
# Apptainer
# -----------------------------
if have_cmd apptainer; then
  skip_step "apptainer"
else
  run_step "apptainer" "scripts/install_apptainer.sh"
fi

# -----------------------------
# Miniconda + bashrc (lab auto-activate)
# -----------------------------
if have_miniconda; then
  skip_step "miniconda"
else
  run_step "miniconda" "scripts/install_miniconda.sh"
fi

# -----------------------------
# lab env + jupyterlab
# -----------------------------
if have_jupyterlab_in_env "lab"; then
  skip_step "lab env + jupyterlab"
else
  run_step "lab env + jupyterlab" "scripts/install_jupyter.sh"
fi

# -----------------------------
# JupyterLab user service
# -----------------------------
# 1) unit が有効化 or 稼働中ならスキップ
# 2) それ以外は作成・有効化
if have_user_systemd_unit_enabled_or_running "jupyterlab.service"; then
  skip_step "jupyterlab service"
else
  run_step "jupyterlab service" "scripts/install_jupyter_service.sh"
fi

# -----------------------------
# RStudio Server
# -----------------------------
# rstudio-server は dpkg 名で検出（導入方式に依存しづらい）
if have_dpkg_pkg "rstudio-server"; then
  skip_step "rstudio-server"
else
  run_step "rstudio-server" "scripts/install_rstudio.sh"
fi

msg "=== INSTALL DONE ==="
