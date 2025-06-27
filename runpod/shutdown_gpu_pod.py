#!/usr/bin/env python3
import os
import sys
import requests
from typing import Optional, Dict, List, Any

def get_pods() -> List[Dict[str, Any]]:
    api_key = os.getenv('RUNPOD_API_KEY')
    if not api_key:
        raise ValueError("RUNPOD_API_KEY environment variable is required")

    url = "https://rest.runpod.io/v1/pods"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()

        result = response.json()
        return result.get('pods', [])

    except requests.exceptions.RequestException as e:
        print(f"Error retrieving pods: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        return []

def find_pod_by_name(name: str = "vllm-gpu-pod") -> Optional[str]:
    pods = get_pods()

    for pod in pods:
        if pod.get('name') == name:
            return pod.get('id')

    return None

def shutdown_run_pod(pod_id: Optional[str] = None, pod_name: Optional[str] = None) -> bool:
    api_key = os.getenv('RUNPOD_API_KEY')
    if not api_key:
        raise ValueError("RUNPOD_API_KEY environment variable is required")

    if not pod_id:
        # If command line argument is provided, use it as pod_id
        if len(sys.argv) > 1:
            pod_id = sys.argv[1]
        # Otherwise, try to find pod by name
        else:
            if not pod_name:
                pod_name = "vllm-gpu-pod"

            print(f"Finding pod with name: {pod_name}...")
            pod_id = find_pod_by_name(pod_name)

            if not pod_id:
                print(f"No pod found with name: {pod_name}")
                return False

    url = f"https://rest.runpod.io/v1/pods/{pod_id}/terminate"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    print(f"Shutting down RunPod GPU pod with ID: {pod_id}...")

    try:
        response = requests.post(url, headers=headers)
        response.raise_for_status()

        result = response.json()
        if result.get('success', False):
            print(f"Pod terminated successfully.")
            return True
        else:
            print(f"Failed to terminate pod: {result.get('message', 'Unknown error')}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"Error terminating pod: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        return False

def main():
    try:
        success = shutdown_run_pod()
        sys.exit(0 if success else 1)
    except ValueError as e:
        print(f"Error: {e}")
        print("Usage: shutdown_gpu_pod.py [pod_id]")
        sys.exit(1)

if __name__ == "__main__":
    main()