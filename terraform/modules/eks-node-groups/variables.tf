variable "cluster_name" {
  description = "Name of the EKS cluster these node groups join."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs nodes launch into."
  type        = list(string)
}

variable "system_instance_types" {
  description = "Instance types for the always-on system node group (kube-system + ArgoCD control-plane components). See docs/architecture.md for why a small always-on EC2 node group was chosen over Fargate for this tier."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_desired_size" {
  description = "Desired size of the system node group. Kept fixed (no schedule, no CA) since this tier must always be available."
  type        = number
  default     = 1
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
  description = "Instance types for the workload node group that scales to zero outside business hours."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "workload_capacity_type" {
  description = "ON_DEMAND or SPOT. SPOT is cheaper but risks interruption; ON_DEMAND is recommended if you'll be demoing this live."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.workload_capacity_type)
    error_message = "workload_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "workload_desired_size" {
  description = "Initial desired size of the workload node group at apply time. The scaling-scheduler module takes over from here on the configured schedule."
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

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
