# In-cluster app deployments for the env-4 Talos+Cilium cluster.
#
# These providers talk to the cluster via the kubeconfig that
# `task cilium:kubeconfig` writes (default ~/.kube/config-cilium). The cluster
# must be up and that file present before running this stage. This keeps
# cluster provisioning (env-4) separate from app lifecycle (here).

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
