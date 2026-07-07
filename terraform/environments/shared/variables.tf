variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cur_bucket_name" {
  description = "Globally-unique S3 bucket name for Cost and Usage Report delivery."
  type        = string
}

variable "monthly_budget_amount" {
  type    = number
  default = 50
}

variable "per_environment_budget_amount" {
  type    = number
  default = 25
}

variable "environments" {
  type    = list(string)
  default = ["dev", "staging"]
}

variable "alert_email" {
  description = "Where budget threshold alerts get sent."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
