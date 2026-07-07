variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_state_bucket" {
  description = "S3 bucket holding the dev cluster root module's state (terraform/bootstrap output: state_bucket_name)."
  type        = string
}

variable "cluster_state_key" {
  description = "State key for the dev cluster root module, set in ../backend.hcl."
  type        = string
  default     = "dev/terraform.tfstate"
}

variable "argocd_chart_version" {
  type = string
}

variable "cluster_autoscaler_chart_version" {
  type = string
}
