#!/usr/bin/env bash
set -e

msg() { printf '%s\n' "$*"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

need_sudo() {
  if ! have_cmd sudo; then
    msg "ERROR: sudo not found"
    exit 1
  fi
}

remove_conda_auto_activate() {
  local f
  for f in ~/.bashrc ~/.bash_profile ~/.profile; do
    [ -f "$f" ] || continue

    msg "==> cleaning conda auto-activation in $f"

    # conda activate lab を削除
    sed -i '/conda[[:space:]]\+activate[[:space:]]\+lab/d' "$f"

    # conda initialize ブロックは残す（base auto-activate は別制御）
  done

  if [ -x "$HOME/miniconda3/condabin/conda" ]; then
    msg "==> disable conda auto_activate_base"
    "$HOME/miniconda3/condabin/conda" config --set auto_activate_base false || true
  fi
}

main() {
  need_sudo

  msg "==> stop/disable user jupyterlab.service (if any)"
  if have_cmd systemctl; then
    systemctl --user disable --now jupyterlab.service >/dev/null 2>&1 || true
  fi

  msg "==> stop/disable system jupyterhub.service (if any)"
  sudo systemctl disable --now jupyterhub.service >/dev/null 2>&1 || true

  msg "==> remove systemd unit for jupyterhub"
  sudo rm -f /etc/systemd/system/jupyterhub.service
  sudo systemctl daemon-reload >/dev/null 2>&1 || true

  msg "==> remove jupyterhub config"
  sudo rm -rf /etc/jupyterhub
  sudo rm -f /jupyterhub_cookie_secret

  msg "==> remove jupyterhub venv"
  sudo rm -rf /opt/jupyterhub

  msg "==> clean conda auto-activation (lab)"
  remove_conda_auto_activate

  msg "=== UNINSTALL DONE ==="
  msg "Next: logout/login or run: exec bash -l"
}

main "$@"
