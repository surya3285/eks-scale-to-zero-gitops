# This is a separate root module (separate state) from ../, applied second,
# on purpose: the helm/kubernetes provider blocks below need a real cluster
# endpoint to configure against. Referencing a resource created in the SAME
# apply from a provider block is unreliable in Terraform (provider config is
# resolved before the resource graph runs) -- reading it back out of already
# -applied remote state sidesteps that entirely instead of relying on
# -target workarounds.
data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = var.cluster_state_bucket
    key    = var.cluster_state_key
    region = var.region
  }
}

# The exec plugin re-invokes `aws eks get-token` on every API call instead of
# using a single token computed once, so long applies don't hit the ~15min
# token expiry that a static `data.aws_eks_cluster_auth` token would.
locals {
  exec_auth = {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", data.terraform_remote_state.cluster.outputs.cluster_name,
      "--region", var.region,
    ]
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)

  exec {
    api_version = local.exec_auth.api_version
    command     = local.exec_auth.command
    args        = local.exec_auth.args
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)

    exec {
      api_version = local.exec_auth.api_version
      command     = local.exec_auth.command
      args        = local.exec_auth.args
    }
  }
}

module "argocd_bootstrap" {
  source = "../../../modules/argocd-bootstrap"

  argocd_chart_version             = var.argocd_chart_version
  cluster_autoscaler_chart_version = var.cluster_autoscaler_chart_version
  cluster_name                     = data.terraform_remote_state.cluster.outputs.cluster_name
  region                           = var.region
  cluster_autoscaler_role_arn      = data.terraform_remote_state.cluster.outputs.cluster_autoscaler_role_arn
  kubernetes_version               = data.terraform_remote_state.cluster.outputs.cluster_version
}
