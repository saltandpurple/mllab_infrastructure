#!/bin/bash

# transfer scripts
scp -r . runpod-scp:/workspace/
# transfer repo
tar -C ~/dev/projects/personal/mllab/ -czf - mapping-llm-censorship | ssh runpod-scp 'tar -xzf - -C /workspace/'
