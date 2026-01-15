#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=../config.sh
source "$ROOT_DIR/config.sh"

msg() { printf '%s\n' "$*"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

need_sudo() {
  if ! have_cmd sudo; then
    msg "ERROR: sudo not found"
    exit 1
  fi
}

is_systemd_unit_active() {
  local unit="$1"
  sudo systemctl is-active "$unit" >/dev/null 2>&1
}

is_systemd_unit_enabled() {
  local unit="$1"
  sudo systemctl is-enabled "$unit" >/dev/null 2>&1
}

write_if_changed() {
  # usage: write_if_changed <dest> <mode> <content...>
  local dest="$1"
  local mode="$2"
  shift 2
  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "$@" > "$tmp"

  if sudo test -f "$dest"; then
    if sudo cmp -s "$tmp" "$dest"; then
      rm -f "$tmp"
      return 0
    fi
    sudo cp -a "$dest" "$dest.bak.$(date +%F_%H%M%S)"
  fi

  sudo mkdir -p "$(dirname "$dest")"
  sudo install -m "$mode" "$tmp" "$dest"
  rm -f "$tmp"
}

main() {
  need_sudo

  : "${ENABLE_JUPYTERHUB:=1}"
  : "${JUPYTERHUB_BIND_IP:=0.0.0.0}"
  : "${JUPYTERHUB_PORT:=8000}"
  : "${JUPYTERHUB_VENV:=/opt/jupyterhub}"
  : "${JUPYTERHUB_CONFIG:=/etc/jupyterhub/jupyterhub_config.py}"
  : "${JUPYTERHUB_SERVICE:=/etc/systemd/system/jupyterhub.service}"

  if [ "$ENABLE_JUPYTERHUB" != "1" ]; then
    msg "JupyterHub disabled by config (ENABLE_JUPYTERHUB=$ENABLE_JUPYTERHUB)."
    exit 0
  fi

  msg "==> install deps (python3-venv, nodejs, npm)"
  sudo apt-get update
  sudo apt-get install -y python3-venv nodejs npm

  msg "==> install configurable-http-proxy (npm global)"
  if have_cmd configurable-http-proxy; then
    msg "    already present: configurable-http-proxy"
  else
    sudo npm install -g configurable-http-proxy
  fi

  msg "==> setup venv: $JUPYTERHUB_VENV"
  if sudo test -x "$JUPYTERHUB_VENV/bin/python"; then
    msg "    already present: $JUPYTERHUB_VENV"
  else
    sudo mkdir -p "$JUPYTERHUB_VENV"
    sudo python3 -m venv "$JUPYTERHUB_VENV"
  fi

  msg "==> install jupyterhub + jupyterlab into venv"
  sudo "$JUPYTERHUB_VENV/bin/pip" install --upgrade pip
  sudo "$JUPYTERHUB_VENV/bin/pip" install --upgrade jupyterhub jupyterlab

  msg "==> write config: $JUPYTERHUB_CONFIG"
  write_if_changed "$JUPYTERHUB_CONFIG" 0644 \
"c = get_config()" \
"" \
"c.JupyterHub.bind_url = \"http://${JUPYTERHUB_BIND_IP}:${JUPYTERHUB_PORT}\"" \
"c.JupyterHub.authenticator_class = \"jupyterhub.auth.PAMAuthenticator\"" \
"c.Spawner.default_url = \"/lab\"" \
"" \
"# keep default spawner (LocalProcessSpawner) and PAM auth (OS users)" \
"# notebook working dir is each user's home by default"

  msg "==> write systemd unit: $JUPYTERHUB_SERVICE"
  write_if_changed "$JUPYTERHUB_SERVICE" 0644 \
"[Unit]" \
"Description=JupyterHub" \
"After=network.target" \
"" \
"[Service]" \
"Type=simple" \
"ExecStart=${JUPYTERHUB_VENV}/bin/jupyterhub -f ${JUPYTERHUB_CONFIG}" \
"Restart=always" \
"User=root" \
"" \
"[Install]" \
"WantedBy=multi-user.target"

  msg "==> systemd daemon-reload"
  sudo systemctl daemon-reload

  msg "==> enable + start jupyterhub"
  sudo systemctl enable jupyterhub.service >/dev/null 2>&1 || true
  sudo systemctl restart jupyterhub.service

  if is_systemd_unit_active "jupyterhub.service"; then
    msg "==> JupyterHub is running on http://${JUPYTERHUB_BIND_IP}:${JUPYTERHUB_PORT}"
  else
    msg "ERROR: jupyterhub.service not active. Check:"
    msg "  sudo systemctl status -l --no-pager jupyterhub.service"
    msg "  sudo journalctl -u jupyterhub.service -b --no-pager | tail -n 200"
    exit 1
  fi
}

main "$@"
