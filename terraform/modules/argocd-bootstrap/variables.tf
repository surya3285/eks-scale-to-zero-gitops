variable "argocd_namespace" {
  type    = string
  default = "argocd"
}

variable "argocd_chart_version" {
  description = "argo-cd chart version from https://artifacthub.io/packages/helm/argo/argo-cd -- check for the current latest before applying."
  type        = string
}

variable "cluster_autoscaler_namespace" {
  type    = string
  default = "kube-system"
}

variable "cluster_autoscaler_chart_version" {
  description = "cluster-autoscaler chart version from https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler -- check for the current latest before applying."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for the Cluster Autoscaler service account (from the cluster root module's cluster_autoscaler_role_arn output)."
  type        = string
}

variable "kubernetes_version" {
  description = "Used to pick a compatible Cluster Autoscaler image tag (CA images are versioned to match the EKS control plane minor version)."
  type        = string
}
