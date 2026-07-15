output "nixos_vm_hostnames" {
  description = "Hostnames of NixOS VMs"
  value       = { for k, v in module.nixos_vms : k => v.vm_name }
}

output "lxc_container_hostnames" {
  description = "Hostnames of LXC containers"
  value       = { for k, v in module.lxc_containers : k => v.hostname }
}
