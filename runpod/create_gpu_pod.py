#!/usr/bin/env python3
import os
import json
import requests
from typing import Dict, Any

def create_runpod_gpu_pod() -> Dict[str, Any]:
    """
    Create a RunPod GPU pod with vLLM
    Community cloud, A4000, spot instance, 40GB storage
    """

    api_key = os.getenv('RUNPOD_API_KEY')
    if not api_key:
        raise ValueError("RUNPOD_API_KEY environment variable is required")
    
    url = "https://rest.runpod.io/v1/pods"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    # Pod configuration
    payload = {
        "cloudType": "COMMUNITY",
        "computeType": "GPU",
        "gpuTypeIds": ["NVIDIA RTX A4000"],
        "gpuCount": 1,
        "imageName": "vllm/vllm-openai:latest",
        "containerDiskInGb": 40,
        "interruptible": True,  # Means spot
        "name": "vllm-gpu-pod",
        "ports": "8000/http,22/tcp"
    }
    
    print("Creating RunPod GPU pod with vLLM...")
    print(f"Configuration: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        result = response.json()
        print(f"Pod created successfully.")
        print(f"Pod ID: {result.get('id', 'N/A')}")
        print(f"Status: {result.get('status', 'N/A')}")
        
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"Error creating pod: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        raise

if __name__ == "__main__":
    create_runpod_gpu_pod()