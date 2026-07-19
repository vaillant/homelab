output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.nixos_vm.vm_id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_virtual_environment_vm.nixos_vm.name
}

output "vm_node" {
  description = "The Proxmox node hosting the VM"
  value       = proxmox_virtual_environment_vm.nixos_vm.node_name
}
