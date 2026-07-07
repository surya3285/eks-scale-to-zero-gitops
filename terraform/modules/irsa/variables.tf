variable "role_name" {
  description = "Name of the IAM role to create."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (from the eks-cluster module output)."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without the https:// scheme, e.g. oidc.eks.us-east-1.amazonaws.com/id/XXXX (from the eks-cluster module output)."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account this role is bound to."
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name this role is bound to."
  type        = string
}

variable "policy_arns" {
  description = "IAM policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the role."
  type        = map(string)
  default     = {}
}
