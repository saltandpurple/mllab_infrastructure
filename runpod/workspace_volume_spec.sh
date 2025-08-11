#!/usr/bin/sh
# 1) Configure pv and setup venv
export PV=/workspace

python3 -m venv $PV/venv
. $PV/venv/bin/activate
python -m pip install -U pip setuptools wheel

# 2) Redirect all caches/tmp to the volume
mkdir -p $PV/.cache/{pip,huggingface,datasets,torch} $PV/tmp
export PIP_CACHE_DIR=$PV/.cache/pip
export HF_HOME=$PV/.cache/huggingface
export TRANSFORMERS_CACHE=$PV/.cache/huggingface/hub
export HF_DATASETS_CACHE=$PV/.cache/datasets
export TORCH_HOME=$PV/.cache/torch
export TMPDIR=$PV/tmp

# 3) (optional) Symlink default cache locations to the volume
mkdir -p ~/.cache
rm -rf ~/.cache/{pip,huggingface,torch} 2>/dev/null
ln -s $PV/.cache/pip        ~/.cache/pip
ln -s $PV/.cache/huggingface ~/.cache/huggingface
ln -s $PV/.cache/torch      ~/.cache/torch

# 4) Install
pip install -r mapping-llm-censorship/requirements.txt

# 5) Clean up container space
pip cache purge
rm -rf ~/.cache/* /root/.cache/* $HOME/.huggingface/* 2>/dev/null
