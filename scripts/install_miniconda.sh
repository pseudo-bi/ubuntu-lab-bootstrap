#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config.sh"

PREFIX="${CONDA_DIR:-$HOME/miniconda3}"
INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
URL="https://repo.anaconda.com/miniconda/${INSTALLER}"

echo "Installing Miniconda to ${PREFIX}..."

if [ -d "${PREFIX}" ]; then
  echo "Miniconda directory exists at ${PREFIX}"
  echo "Updating existing installation..."
  UPDATE_FLAG="-u"
else
  UPDATE_FLAG=""
fi

cd "${HOME}" || exit 1

if command -v curl >/dev/null 2>&1; then
  curl -fsSLO "${URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -q "${URL}" -O "${INSTALLER}"
else
  echo "Neither curl nor wget is available."
  exit 1
fi

bash "${INSTALLER}" -b $UPDATE_FLAG -p "${PREFIX}"
rm -f "${INSTALLER}"

"${PREFIX}/bin/conda" --version

"${PREFIX}/bin/conda" init bash

cat <<EOF

Miniconda installation finished.
Your .bashrc has been modified to initialize conda.

To use conda in this current shell session, please run:
  source ~/.bashrc

To activate base environment:
  conda activate base

Notes:
- "conda init bash" was run automatically.
- Removal:
    rm -rf "${PREFIX}"
    # and revert changes to ~/.bashrc

EOF
