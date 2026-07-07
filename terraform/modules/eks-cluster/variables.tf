variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version, e.g. \"1.31\". No default on purpose: check the EKS Kubernetes release calendar before you set this. A version outside AWS's standard support window bills an extra $0.60/hr/cluster (\"extended support\") on top of the normal $0.10/hr control plane charge."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must look like \"1.31\"."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane's cross-account ENIs. Use private subnets."
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint access from inside the VPC."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint access (needed for kubectl/helm/terraform from your laptop unless you set up a VPN/bastion into the VPC)."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint. Defaults to open; for a personal project you should restrict this to your own IP (e.g. [\"203.0.113.4/32\"]) in your tfvars."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types to ship to CloudWatch Logs (api, audit, authenticator, controllerManager, scheduler). Each enabled type adds CloudWatch ingestion + storage cost. Defaults to none for a cost-conscious portfolio cluster; turn on [\"api\", \"audit\"] temporarily if you need to debug access issues."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
