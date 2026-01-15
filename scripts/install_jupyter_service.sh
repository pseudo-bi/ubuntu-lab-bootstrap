#!/usr/bin/env bash
set -e

MINICONDA_DIR="$HOME/miniconda3"
ENV_NAME="lab"
PORT="8888"
IP="0.0.0.0"

UNIT_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$UNIT_DIR/jupyterlab.service"

mkdir -p "$UNIT_DIR"

printf '%s\n' \
"[Unit]" \
"Description=JupyterLab (conda env: ${ENV_NAME})" \
"After=network.target" \
"" \
"[Service]" \
"Type=simple" \
"WorkingDirectory=%h" \
"Environment=PATH=${MINICONDA_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
"ExecStart=${MINICONDA_DIR}/bin/conda run -n ${ENV_NAME} jupyter lab --no-browser --ip=${IP} --port=${PORT}" \
"Restart=on-failure" \
"RestartSec=2" \
"" \
"[Install]" \
"WantedBy=default.target" \
> "$UNIT_FILE"

systemctl --user daemon-reload
systemctl --user enable --now jupyterlab.service

echo "JupyterLab is running on http://<server>:${PORT}"
systemctl --user --no-pager status jupyterlab.service || true
