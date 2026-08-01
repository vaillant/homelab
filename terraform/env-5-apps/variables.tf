variable "kubeconfig_path" {
  description = "Path to the cluster kubeconfig (written by 'task cilium:kubeconfig')."
  type        = string
  default     = "~/.kube/config-cilium"
}

variable "longhorn_version" {
  description = "Longhorn Helm chart / app version to install."
  type        = string
  default     = "1.11.3"
}
