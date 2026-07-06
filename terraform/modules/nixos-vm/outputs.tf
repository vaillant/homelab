output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_vm_qemu.nixos_vm.id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_vm_qemu.nixos_vm.name
}

output "vm_ip" {
  description = "The IP address of the VM"
  value       = proxmox_vm_qemu.nixos_vm.default_ipv4_address
}

output "vm_node" {
  description = "The Proxmox node hosting the VM"
  value       = proxmox_vm_qemu.nixos_vm.target_node
}
