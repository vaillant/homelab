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

output "dhcp_ip" {
  description = "DHCP IP address reported by QEMU guest agent (first non-loopback IPv4)"
  value = try(
    [for iface in proxmox_virtual_environment_vm.talos_node.ipv4_addresses :
      [for ip in iface : ip if !startswith(ip, "127.")][0]
    if length([for ip in iface : ip if !startswith(ip, "127.")]) > 0][0],
    null
  )
}

output "mac_address" {
  description = "MAC address of the VM's network interface"
  value       = proxmox_virtual_environment_vm.talos_node.network_device[0].mac_address
}
