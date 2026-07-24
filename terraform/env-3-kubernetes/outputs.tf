output "talosconfig" {
  description = "Talos client configuration (talosconfig)"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes configuration (kubeconfig)"
  value       = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "machine_secrets" {
  description = "Talos machine secrets (for backup/restore)"
  value       = talos_machine_secrets.this.machine_secrets
  sensitive   = true
}

output "node_ips" {
  description = "IP addresses of Talos nodes"
  value       = { for k, v in local.nodes : k => v.ip_address }
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = local.cluster_endpoint
}

output "cluster_name" {
  description = "Cluster name"
  value       = var.cluster_name
}
