# Same pattern as ../backend.tf -- filled in at init time, not hardcoded.
#   cp backend.hcl.example backend.hcl
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {}
}
