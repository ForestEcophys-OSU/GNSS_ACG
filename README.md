# GNSS-ACG
A repository for the analysis of the GNSS data from Horizontes Forestry Station in ACG

## Python environment

This repository primarily contains Jupyter notebooks that use common scientific Python libraries. To create a reproducible Python environment you can either use a virtual environment (venv) or conda. Two example environment files are provided: `requirements.txt` (pip) and `environment.yml` (conda).

Recommended quick start (venv + pip):

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Optional: create a conda environment (requires conda/miniconda/Anaconda):

```bash
conda env create -f environment.yml
conda activate gnss_acg
```

Quick smoke test after installing:

```bash
python -c "import numpy, pandas, xarray, matplotlib, statsmodels; print('basic imports OK')"
```

Notes:
- Some imports in notebooks are commented out (e.g. `georinex`, `qgrid`) — install them only if you need those features.
