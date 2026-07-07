variable "region" {
  description = "AWS region to create the state backend resources in. All environment state files live in this region regardless of where their workloads run."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform remote state. Must be unique across all of AWS, not just your account."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Bucket name must be a valid S3 bucket name: lowercase letters, numbers, dots, hyphens."
  }
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking across all environments."
  type        = string
  default     = "eks-scale-to-zero-tf-locks"
}

variable "tags" {
  description = "Tags applied to every resource this stack creates."
  type        = map(string)
  default = {
    Project   = "eks-scale-to-zero"
    ManagedBy = "terraform"
    Layer     = "bootstrap"
  }
}
