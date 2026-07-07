variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "staging"

  validation {
    condition     = contains(["dev", "staging"], var.environment)
    error_message = "environment must be \"dev\" or \"staging\"."
  }
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  description = "See terraform/modules/eks-cluster/variables.tf for the extended-support cost warning. Check the current EKS release calendar before setting this."
  type        = string
}

# --- Networking ---

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_interface_endpoints" {
  type    = bool
  default = false
}

# --- Cluster ---

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  description = "Restrict this to your own IP in staging.tfvars, e.g. [\"203.0.113.4/32\"]."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  type    = list(string)
  default = []
}

# --- Node groups ---

variable "system_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "system_desired_size" {
  type    = number
  default = 1
}

variable "system_min_size" {
  type    = number
  default = 1
}

variable "system_max_size" {
  type    = number
  default = 2
}

variable "workload_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "workload_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "workload_desired_size" {
  description = "Initial size at apply time. The scaling-scheduler module owns this afterward."
  type        = number
  default     = 0
}

variable "workload_min_size" {
  type    = number
  default = 0
}

variable "workload_max_size" {
  type    = number
  default = 3
}

# --- Scaling schedule ---

variable "scale_up_schedule_expression" {
  type    = string
  default = "cron(0 8 ? * MON-FRI *)"
}

variable "scale_down_schedule_expression" {
  type    = string
  default = "cron(0 19 ? * MON-FRI *)"
}

variable "schedule_timezone" {
  description = "IANA timezone, e.g. \"America/New_York\". Set this to your own timezone."
  type        = string
  default     = "UTC"
}

variable "business_hours_desired_size" {
  type    = number
  default = 2
}

variable "business_hours_min_size" {
  type    = number
  default = 0
}

variable "alert_email" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
