output "nix_builder_name" {
  description = "Name of the nix-builder VM"
  value       = proxmox_virtual_environment_vm.nix_builder.name
}

output "nix_builder_vm_id" {
  description = "VM ID of the nix-builder"
  value       = proxmox_virtual_environment_vm.nix_builder.vm_id
}

output "nix_builder_ipv4" {
  description = "IPv4 address of the nix-builder"
  value       = proxmox_virtual_environment_vm.nix_builder.ipv4_addresses
}
