#!/usr/bin/env python3
import os
import sys
import requests

POD_NAME = "vllm-gpu-pod"
def shutdown_runpod():
    api_key = os.getenv('RUNPOD_API_KEY')
    if not api_key:
        sys.exit("Error: RUNPOD_API_KEY environment variable is required.")

    headers = {"Authorization": f"Bearer {api_key}"}
    pod_id = sys.argv[1] if len(sys.argv) > 1 else None

    try:
        if not pod_id:
            print(f"Searching for pod {POD_NAME}...")
            pods_url = "https://rest.runpod.io/v1/pods"
            resp = requests.get(pods_url, headers=headers)
            resp.raise_for_status()
            pods = resp.json()

            pod = next((p for p in pods if p.get('name') == POD_NAME), None)
            if not pod:
                sys.exit(f"Error: Pod {POD_NAME} not found.")
            pod_id = pod['id']
            print(f"Found pod with ID: {pod_id}")

        print(f"Shutting down pod {pod_id}...")
        terminate_url = f"https://rest.runpod.io/v1/pods/{pod_id}"
        resp = requests.delete(terminate_url, headers=headers)
        resp.raise_for_status()

        if resp.status_code == 200:
            print("Pod terminated successfully.")
        else:
            sys.exit(f"Error: Failed to terminate pod. API Message: {resp.status_code}")

    except requests.exceptions.RequestException as e:
        error = f"API request failed: {e}"
        if e.response is not None:
            error += f" | Response: {e.response.text}"
        sys.exit(error)
    except Exception as e:
        sys.exit(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    shutdown_runpod()