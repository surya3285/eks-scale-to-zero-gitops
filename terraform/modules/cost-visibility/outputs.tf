output "cur_bucket_name" {
  value = aws_s3_bucket.cur.id
}

output "cur_export_arn" {
  value = aws_bcmdataexports_export.cur.arn
}

output "overall_budget_name" {
  value = aws_budgets_budget.overall.name
}
