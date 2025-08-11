cat >> ~/.bashrc <<'EOF'
export PV=/workspace
export PIP_CACHE_DIR=$PV/.cache/pip
export HF_HOME=$PV/.cache/huggingface
export TRANSFORMERS_CACHE=$PV/.cache/huggingface/hub
export HF_DATASETS_CACHE=$PV/.cache/datasets
export TORCH_HOME=$PV/.cache/torch
export TMPDIR=$PV/tmp
. $PV/venv/bin/activate
EOF