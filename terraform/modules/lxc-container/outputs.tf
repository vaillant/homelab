output "container_id" {
  description = "The ID of the created container"
  value       = proxmox_lxc.container.id
}

output "container_hostname" {
  description = "The hostname of the created container"
  value       = proxmox_lxc.container.hostname
}

output "container_node" {
  description = "The Proxmox node hosting the container"
  value       = proxmox_lxc.container.target_node
}
