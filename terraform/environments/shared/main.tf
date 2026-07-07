provider "aws" {
  region = var.region
}

# Billing/Cost Management APIs (Budgets, Data Exports/CUR) only have a
# us-east-1 endpoint, regardless of where the rest of your infrastructure
# lives -- same reason terraform/bootstrap's CUR note in Phase 1 flagged this.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  common_tags = merge(var.tags, {
    Project   = "eks-scale-to-zero"
    ManagedBy = "terraform"
    Layer     = "shared"
  })
}

module "cost_visibility" {
  source = "../../modules/cost-visibility"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  region                        = var.region
  cur_bucket_name               = var.cur_bucket_name
  monthly_budget_amount         = var.monthly_budget_amount
  per_environment_budget_amount = var.per_environment_budget_amount
  environments                  = var.environments
  alert_email                   = var.alert_email
  tags                          = local.common_tags
}
