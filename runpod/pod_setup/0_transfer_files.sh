#!/bin/bash

# transfer scripts
scp -r . runpod-scp:/workspace/
# transfer repo
rsync -avz --exclude='.git' ~/dev/projects/personal/mllab/mapping-llm-censorship/ runpod-scp:/workspace/mapping-llm-censorship/