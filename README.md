# k3s on Proxmox

This repository contains an example setup for running a small k3s Kubernetes cluster on a single Proxmox server.
Terraform is used with the Telmate `proxmox` provider to create the virtual machines and Ansible provisions k3s on them.

## Directory Layout

- `terraform/` – Terraform configuration that clones VMs from a cloud-init template.
- `ansible/` – Ansible playbook and inventory to install k3s.

## Prerequisites

- Proxmox server with a cloud-init template ready.
- Terraform and Ansible installed on your workstation.
- SSH key pair for accessing the VMs.

## Usage

### Terraform
1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and edit the variables for your environment.
2. Run `terraform init` and then `terraform apply` in the `terraform` directory. This will create one master and two worker VMs.

### Ansible
1. Update `ansible/inventory.ini` with the IP addresses you used in `terraform.tfvars`.
2. Run the playbook to install k3s:

```bash
ansible-playbook -i inventory.ini site.yml
```

After the playbook completes you will have a functional k3s cluster running on the VMs provisioned by Terraform.
