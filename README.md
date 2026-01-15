# ubuntu-lab-bootstrap

## What this does
- Miniconda
- lab conda env (JupyterLab)
- Apptainer
- RStudio Server (amd64 only)
- user-level JupyterLab service (optional)

## Requirements
- Ubuntu 24.04
- sudo available
- outbound HTTPS

## How to use (production)
git clone ...
cd ubuntu-lab-bootstrap
edit config.sh
bash install.sh

## Access
JupyterLab:
  ssh -L 8888:127.0.0.1:8888 user@server
  http://localhost:8888

RStudio:
  ssh -L 8787:127.0.0.1:8787 user@server
  http://localhost:8787

## Rollback
bash uninstall.sh
