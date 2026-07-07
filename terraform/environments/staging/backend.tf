# Intentionally empty. Backend settings are account/bucket-specific, so they
# are supplied at `terraform init` time instead of hardcoded here:
#
#   cp backend.hcl.example backend.hcl   # then fill in your bucket/table names
#   terraform init -backend-config=backend.hcl
#
# backend.hcl is gitignored -- it's derived from terraform/bootstrap's outputs
# and is specific to your AWS account.
terraform {
  backend "s3" {}
}
