output "container_id" {
  description = "The ID of the created container"
  value       = proxmox_virtual_environment_container.container.vm_id
}

output "container_hostname" {
  description = "The hostname of the created container"
  value       = var.hostname
}

output "container_node" {
  description = "The Proxmox node hosting the container"
  value       = proxmox_virtual_environment_container.container.node_name
}

output "container_ipv4" {
  description = "The IPv4 address of the container (first interface)"
  value       = try(proxmox_virtual_environment_container.container.ipv4["eth0"], null)
}
