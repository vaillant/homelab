# Longhorn — distributed replicated block storage.
#
# Runs on the dedicated 100 GB local-zfs data disk each node mounts at
# /var/lib/longhorn (configured in env-4 via the module fork). Talos enforces
# the `baseline` PodSecurity standard by default, so the namespace must be
# labeled `privileged` or Longhorn's privileged pods are rejected.

resource "kubernetes_namespace" "longhorn_system" {
  metadata {
    name = "longhorn-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.longhorn_version
  namespace  = kubernetes_namespace.longhorn_system.metadata[0].name

  # Wait for the deployment to settle so `apply` fails loudly if it doesn't.
  wait    = true
  timeout = 600

  # Default data path matches the mounted data disk from env-4.
  set {
    name  = "defaultSettings.defaultDataPath"
    value = "/var/lib/longhorn"
  }

  # Not the cluster-default StorageClass — Proxmox CSI is intended as default.
  set {
    name  = "persistence.defaultClass"
    value = "false"
  }

  set {
    name  = "persistence.defaultClassReplicaCount"
    value = "3"
  }
}
