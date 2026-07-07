# See dev/platform/main.tf for why this is a separate root module/state.
data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = var.cluster_state_bucket
    key    = var.cluster_state_key
    region = var.region
  }
}

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
