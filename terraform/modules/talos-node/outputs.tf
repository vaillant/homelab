output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.talos_node.vm_id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_virtual_environment_vm.talos_node.name
}

output "vm_node" {
  description = "The Proxmox node hosting the VM"
  value       = proxmox_virtual_environment_vm.talos_node.node_name
}
