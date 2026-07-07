variable "region" {
  description = "Region the CUR delivery S3 bucket lives in. The export/budget control-plane resources always use the us_east_1 provider alias regardless of this value -- Billing/Cost Management APIs are us-east-1 only."
  type        = string
}

variable "cur_bucket_name" {
  description = "Globally-unique S3 bucket name for Cost and Usage Report (Data Export) delivery."
  type        = string
}

variable "monthly_budget_amount" {
  description = "Overall account monthly budget in USD, across all environments."
  type        = number
  default     = 50
}

variable "environments" {
  description = "Environment tag values to create individual filtered budgets for, e.g. [\"dev\", \"staging\"]. Relies on the Environment cost allocation tag applied in terraform/environments/*/main.tf."
  type        = list(string)
  default     = ["dev", "staging"]
}

variable "per_environment_budget_amount" {
  description = "Monthly budget in USD for each environment-filtered budget."
  type        = number
  default     = 25
}

variable "alert_email" {
  description = "Email address to notify on budget threshold breaches."
  type        = string
}

variable "cost_allocation_tag_keys" {
  description = "User-defined tag keys to activate as cost allocation tags. Each key must already appear on at least one billed resource before AWS will let you activate it -- see the comment on aws_ce_cost_allocation_tag below if this fails on first apply."
  type        = list(string)
  default     = ["Environment", "Project"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
