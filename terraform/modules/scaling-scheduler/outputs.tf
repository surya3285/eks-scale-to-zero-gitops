output "lambda_function_name" {
  value = aws_lambda_function.node_scheduler.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.node_scheduler.arn
}

output "scale_up_schedule_arn" {
  value = aws_scheduler_schedule.scale_up.arn
}

output "scale_down_schedule_arn" {
  value = aws_scheduler_schedule.scale_down.arn
}
