resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true

  values = [yamlencode({
    configs = {
      params = {
        # Plain HTTP behind kubectl port-forward -- avoids self-signed cert
        # friction for a project with no public ingress/domain.
        "server.insecure" = true
      }
    }
    server = {
      replicas = 1
      service = {
        type = "ClusterIP"
      }
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }
    repoServer = {
      replicas = 1
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }
    applicationSet = {
      replicas = 1
    }
    controller = {
      replicas = 1
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }
    redis = {
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "200m", memory = "128Mi" }
      }
    }
    # No external IdP for this project -- use Argo's built-in admin user.
    dex = {
      enabled = false
    }
    notifications = {
      enabled = false
    }
  })]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version
  namespace  = var.cluster_autoscaler_namespace

  values = [yamlencode({
    autoDiscovery = {
      clusterName = var.cluster_name
    }
    awsRegion = var.region
    image = {
      # Best-effort match to the control plane's minor version. If this tag
      # doesn't exist yet, check https://github.com/kubernetes/autoscaler/releases
      # and override via the chart's image.tag value.
      tag = "v${var.kubernetes_version}.0"
    }
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = var.cluster_autoscaler_role_arn
        }
      }
    }
    extraArgs = {
      "balance-similar-node-groups" = true
      "skip-nodes-with-system-pods" = false
    }
    # Cluster Autoscaler itself must never land on the node group it manages.
    nodeSelector = {
      role = "system"
    }
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { cpu = "200m", memory = "256Mi" }
    }
  })]
}

# Convenience output only -- lets `terraform output` hand you a working
# login instead of hunting for the secret yourself after first install.
data "kubernetes_secret" "argocd_initial_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }

  depends_on = [helm_release.argocd]
}
