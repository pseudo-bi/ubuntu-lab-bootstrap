#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$ROOT_DIR/scripts/install_base.sh"
bash "$ROOT_DIR/scripts/install_apptainer.sh"

echo "OK: base + apptainer finished"
