variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "workload_node_group_name" {
  description = "Name of the workload node group to scale (from the eks-node-groups module output)."
  type        = string
}

variable "lambda_function_name" {
  description = "Name for the scheduler Lambda function."
  type        = string
}

variable "scale_up_schedule_expression" {
  description = "EventBridge Scheduler cron expression for scaling up. Default: 8am weekdays."
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "scale_down_schedule_expression" {
  description = "EventBridge Scheduler cron expression for scaling down. Default: 7pm weekdays."
  type        = string
  default     = "cron(0 19 ? * MON-FRI *)"
}

variable "schedule_timezone" {
  description = "IANA timezone the cron expressions above are evaluated in, e.g. \"America/New_York\". Defaults to UTC -- override this in your tfvars to your own local business hours."
  type        = string
  default     = "UTC"
}

variable "business_hours_desired_size" {
  description = "Workload node group desired size during business hours."
  type        = number
  default     = 2
}

variable "business_hours_min_size" {
  description = "Workload node group min size during business hours (usually 0, letting Cluster Autoscaler grow from there)."
  type        = number
  default     = 0
}

variable "workload_max_size" {
  description = "Workload node group max size. Must match the eks-node-groups module's workload_max_size -- passed through here rather than hardcoded so a scheduled update never accidentally shrinks the ceiling Terraform set."
  type        = number
}

variable "alert_email" {
  description = "Optional email address to notify on scheduler Lambda failures. Leave null to skip SNS/alarm setup."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
