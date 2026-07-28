output "kubeconfig" {
  description = "Kubernetes configuration (kubeconfig)"
  value       = module.talos_cluster.kubeconfig
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration (talosconfig)"
  value       = module.talos_cluster.talos_config
  sensitive   = true
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.talos_cluster.cluster_name
}

output "node_ips" {
  description = "IP addresses per node"
  value       = module.talos_cluster.node_ips
}

output "all_ips" {
  description = "All cluster IP addresses"
  value       = module.talos_cluster.all_ips
}

output "cluster_vip" {
  description = "Kubernetes API virtual IP"
  value       = local.cluster_vip
}
