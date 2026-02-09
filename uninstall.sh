# uninstall.sh
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

main() {
  need_sudo

  msg "==> stop/disable user jupyterlab.service (if any)"
  if have_cmd systemctl; then
    systemctl --user disable --now jupyterlab.service >/dev/null 2>&1 || true
    systemctl --user stop jupyterlab.service >/dev/null 2>&1 || true
  fi

  msg "==> stop/disable system jupyterhub.service (if any)"
  sudo systemctl disable --now jupyterhub.service >/dev/null 2>&1 || true
  sudo systemctl stop jupyterhub.service >/dev/null 2>&1 || true

  msg "==> remove systemd unit for jupyterhub"
  sudo rm -f /etc/systemd/system/jupyterhub.service
  sudo systemctl daemon-reload >/dev/null 2>&1 || true

  msg "==> remove jupyterhub config (backup by hand if needed)"
  sudo rm -rf /etc/jupyterhub
  sudo rm -f /jupyterhub_cookie_secret

  msg "==> remove jupyterhub venv"
  sudo rm -rf /opt/jupyterhub

  msg "==> (optional) keep configurable-http-proxy as-is"
  msg "    If you really want to remove it:"
  msg "      sudo npm remove -g configurable-http-proxy"
  msg "      sudo rm -f /usr/local/bin/configurable-http-proxy"

  msg "=== UNINSTALL DONE ==="
}

main "$@"
