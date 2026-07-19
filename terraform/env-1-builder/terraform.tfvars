# NixOS builder VM configuration

target_node  = "proxmox1"
storage      = "local"
disk_storage = "local-zfs"

cores   = 4
memory  = 8192
disk_size = 64

bridge     = "vmbr0"
ip_address = "dhcp"
