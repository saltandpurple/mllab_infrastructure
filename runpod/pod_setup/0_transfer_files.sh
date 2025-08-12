#!/bin/bash

# transfer scripts
scp -r ../pod_setup/ runpod-scp:/workspace/

# transfer repo
tar -C ~/dev/projects/personal/mllab/ -czf - mapping-llm-censorship | ssh runpod-scp 'tar -xzf - -C /workspace/'

# transfer models
tar -C ~/dev/projects/personal/mllab/models/ -czf - deepseek:deepseek-r1-0528-qwen3-8b@gf16 | ssh runpod-scp 'tar -xzf - -C /workspace/models/'