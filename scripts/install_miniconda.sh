#!/usr/bin/env bash
set -euo pipefail

PREFIX="${HOME}/miniconda3"
INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
URL="https://repo.anaconda.com/miniconda/${INSTALLER}"

if [ -d "${PREFIX}" ]; then
  echo "Miniconda already exists at ${PREFIX}"
  echo "To reinstall cleanly:"
  echo "  rm -rf \"${PREFIX}\""
  exit 1
fi

cd "${HOME}"

if command -v curl >/dev/null 2>&1; then
  curl -fsSLO "${URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -q "${URL}" -O "${INSTALLER}"
else
  echo "Neither curl nor wget is available."
  exit 1
fi

bash "${INSTALLER}" -b -p "${PREFIX}"
rm -f "${INSTALLER}"

"${PREFIX}/bin/conda" --version

cat <<'EOF'

Miniconda installation finished.

To use conda in this shell:
  . "$HOME/miniconda3/etc/profile.d/conda.sh"

To activate base environment:
  conda activate base

Notes:
- This script does not run "conda init"
- No shell config files were modified
- Removal:
    rm -rf ~/miniconda3

EOF
