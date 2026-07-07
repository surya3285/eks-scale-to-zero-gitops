provider "aws" {
  region = var.region
}

# Intentionally uses local state. This stack creates the remote backend that
# every other root module (terraform/environments/*) depends on, so it can't
# depend on that backend itself. Run this once per AWS account, keep the
# resulting terraform.tfstate somewhere safe, and don't re-run destroy against
# it while any environment still has remote state in the bucket it creates.

resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # no fixed hourly cost; this table sees near-zero traffic
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
