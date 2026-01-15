#!/usr/bin/env bash
# config.sh

# Conda
CONDA_DIR="${CONDA_DIR:-$HOME/miniconda3}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-lab}"
CONDA_PYTHON_VERSION="${CONDA_PYTHON_VERSION:-3.11}"

# Jupyter
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
JUPYTER_IP="${JUPYTER_IP:-0.0.0.0}"

# RStudio
RSTUDIO_PORT="${RSTUDIO_PORT:-8787}"

# Enable/Disable components (0=skip, 1=install)
ENABLE_RSTUDIO="${ENABLE_RSTUDIO:-1}"
ENABLE_JUPYTER_SERVICE="${ENABLE_JUPYTER_SERVICE:-1}"

# JupyterHub (multi-user, browser access)
ENABLE_JUPYTERHUB=1
JUPYTERHUB_BIND_IP="0.0.0.0"
JUPYTERHUB_PORT=8000
JUPYTERHUB_VENV="/opt/jupyterhub"
JUPYTERHUB_CONFIG="/etc/jupyterhub/jupyterhub_config.py"
JUPYTERHUB_SERVICE="/etc/systemd/system/jupyterhub.service"

