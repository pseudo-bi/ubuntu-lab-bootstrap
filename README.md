# README.md
# ubuntu-lab-bootstrap

## What this does
- Miniconda
- conda env (default: lab)
- JupyterLab (inside the conda env, for kernels and optional single-user use)
- JupyterHub (recommended multi-user, systemd root service)
- Apptainer
- RStudio Server (amd64 only)
- user-level JupyterLab service (optional)

## Requirements
- Ubuntu 24.04
- sudo available
- outbound HTTPS (apt, pip, npm)

## Quick start
1) git clone ...
2) cd ubuntu-lab-bootstrap
3) edit config.sh
4) bash install.sh

## Access
### JupyterHub (recommended)
- http://SERVER_IP:8000
- Login uses OS users (PAM). Access control is by Linux group(s) in `JUPYTERHUB_ALLOWED_GROUPS`.
- Default URL is JupyterLab.

### JupyterLab (single-user, optional)
If you enable user-level service:
- http://SERVER_IP:8888

### RStudio Server (optional)
- http://SERVER_IP:8787

## Rollback
- bash uninstall.sh
