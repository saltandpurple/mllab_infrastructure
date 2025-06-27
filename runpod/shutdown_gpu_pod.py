#!/usr/bin/env python3
import os
import sys
import requests
from typing import Optional

def shutdown_run_pod(pod_id: Optional[str] = None) -> bool:
    """
    Shutdown a RunPod GPU pod by its ID

    Args:
        pod_id: The ID of the pod to shutdown. If not provided, will be taken from command line arguments.

    Returns:
        bool: True if the pod was successfully terminated, False otherwise
    """
    api_key = os.getenv('RUNPOD_API_KEY')
    if not api_key:
        raise ValueError("RUNPOD_API_KEY environment variable is required")

    # Get pod_id from command line if not provided as arg
    if not pod_id:
        if len(sys.argv) > 1:
            pod_id = sys.argv[1]
        else:
            raise ValueError("Pod ID must be provided as an argument or command line parameter")

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
        print("Usage: shutdown_gpu_pod.py <pod_id>")
        sys.exit(1)

if __name__ == "__main__":
    main()