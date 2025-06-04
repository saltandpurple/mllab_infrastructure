output "master_names" {
  value = [for m in proxmox_vm_qemu.master : m.name]
}

output "worker_names" {
  value = [for w in proxmox_vm_qemu.worker : w.name]
}