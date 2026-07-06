# Outputs for VMs
output "vms" {
  description = "Information about created VMs"
  value = {
    for k, v in module.nixos_vms : k => {
      id   = v.vm_id
      name = v.vm_name
      ip   = v.vm_ip
      node = v.vm_node
    }
  }
}

# Outputs for LXC containers
output "lxc_containers" {
  description = "Information about created LXC containers"
  value = {
    for k, v in module.lxc_containers : k => {
      id       = v.container_id
      hostname = v.container_hostname
      node     = v.container_node
    }
  }
}
