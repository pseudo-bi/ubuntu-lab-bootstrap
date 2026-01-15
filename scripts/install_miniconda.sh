#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/config.sh"

MINICONDA_DIR="$CONDA_DIR"

if [ ! -d "$MINICONDA_DIR" ]; then
  cd /tmp
  case "$(uname -m)" in
    x86_64)  ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac

  INSTALLER="Miniconda3-latest-Linux-${ARCH}.sh"
  curl -fsSLO "https://repo.anaconda.com/miniconda/${INSTALLER}"
  bash "${INSTALLER}" -b -p "$MINICONDA_DIR"
fi

BASHRC="$HOME/.bashrc"
CONDASH_LINE=". \"$MINICONDA_DIR/etc/profile.d/conda.sh\""

if ! grep -q "$CONDASH_LINE" "$BASHRC"; then
  {
    echo ""
    echo "# conda setup"
    echo "$CONDASH_LINE"
  } >> "$BASHRC"
fi

# shellcheck disable=SC2016
LAB_BLOCK="
# auto-activate ${CONDA_ENV_NAME} conda env (interactive shells only)
if [[ \$- == *i* ]]; then
  if [ -f \"\$HOME/miniconda3/etc/profile.d/conda.sh\" ]; then
    . \"\$HOME/miniconda3/etc/profile.d/conda.sh\"
    conda activate ${CONDA_ENV_NAME} >/dev/null 2>&1 || true
  fi
fi
"

if ! grep -q "auto-activate ${CONDA_ENV_NAME} conda env" "$BASHRC"; then
  echo "$LAB_BLOCK" >> "$BASHRC"
fi

echo "miniconda setup finished (${CONDA_ENV_NAME} will auto-activate on login)"
