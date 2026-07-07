output "state_bucket_name" {
  description = "S3 bucket holding remote state. Use this in each environment's backend.hcl."
  value       = aws_s3_bucket.tf_state.id
}

output "lock_table_name" {
  description = "DynamoDB table used for state locking. Use this in each environment's backend.hcl."
  value       = aws_dynamodb_table.tf_locks.name
}

output "region" {
  description = "Region the backend resources live in."
  value       = var.region
}
