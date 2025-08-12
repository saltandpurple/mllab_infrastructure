#!/bin/bash

# Optional speed-up (multi-connection downloader)
pip install -U huggingface_hub hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1

hf download --repo-type model "deepseek-ai/DeepSeek-R1-0528-Qwen3-8B" \
  --local-dir "/workspace/models/deepseek-r1-0528-qwen3-8b@gf16"