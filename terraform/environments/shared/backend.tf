# Same pattern as the other roots -- filled in at init time.
#   cp backend.hcl.example backend.hcl
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {}
}
