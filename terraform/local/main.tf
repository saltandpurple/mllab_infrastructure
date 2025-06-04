resource "proxmox_vm_qemu" "master" {
  count        = var.master_count
  vmid         = 900 + count.index
  name         = "k3s-master-${count.index + 1}"
  target_node  = var.target_node
  clone        = var.template
  agent        = 1
  cores        = var.master_cores
  memory       = var.master_memory
  boot         = "order=scsi0"
  scsihw       = "virtio-scsi-single"
  ciuser       = var.ciuser
  cipassword   = var.cipassword
  ipconfig0    = "ip=${var.master_ips[count.index]}/24,gw=${var.gateway}"
  sshkeys      = file(var.ssh_public_key)

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = var.disk_size
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  network {
    id     = 0
    bridge = var.bridge
    model  = "virtio"
  }
}

resource "proxmox_vm_qemu" "worker" {
  count        = var.worker_count
  vmid         = 910 + count.index
  name         = "k3s-worker-${count.index + 1}"
  target_node  = var.target_node
  clone        = var.template
  agent        = 1
  cores        = var.worker_cores
  memory       = var.worker_memory
  boot         = "order=scsi0"
  scsihw       = "virtio-scsi-single"
  ciuser       = var.ciuser
  cipassword   = var.cipassword
  ipconfig0    = "ip=${var.worker_ips[count.index]}/24,gw=${var.gateway}"
  sshkeys      = file(var.ssh_public_key)

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.storage
          size    = var.disk_size
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }

  network {
    id     = 0
    bridge = var.bridge
    model  = "virtio"
  }
}