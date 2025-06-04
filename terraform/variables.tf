variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_user" {
  description = "Proxmox user"
  type        = string
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to create VMs on"
  type        = string
}

variable "template" {
  description = "Name of the cloud-init template"
  type        = string
}

variable "bridge" {
  description = "Bridge to attach VM network interfaces"
  type        = string
  default     = "vmbr0"
}

variable "storage" {
  description = "Proxmox storage for disks"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size for each VM"
  type        = string
  default     = "20G"
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "master_ips" {
  description = "IPv4 addresses for master nodes"
  type        = list(string)
}

variable "worker_ips" {
  description = "IPv4 addresses for worker nodes"
  type        = list(string)
}

variable "gateway" {
  description = "Default gateway for the VMs"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to authorize"
  type        = string
}

variable "ciuser" {
  description = "cloud-init user"
  type        = string
  default     = "root"
}

variable "cipassword" {
  description = "cloud-init password"
  type        = string
  default     = "changeme"
}

variable "master_cores" {
  description = "CPU cores for master nodes"
  type        = number
  default     = 2
}

variable "worker_cores" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 2
}

variable "master_memory" {
  description = "Memory for master nodes"
  type        = number
  default     = 2048
}

variable "worker_memory" {
  description = "Memory for worker nodes"
  type        = number
  default     = 2048
}
