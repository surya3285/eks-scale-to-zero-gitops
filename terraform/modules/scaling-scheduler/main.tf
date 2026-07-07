data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  nodegroup_arn_pattern = "arn:aws:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:nodegroup/${var.cluster_name}/${var.workload_node_group_name}/*"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/node-scheduler/handler.py"
  output_path = "${path.module}/build/node-scheduler.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
  tags              = var.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid    = "UpdateNodegroup"
    effect = "Allow"
    actions = [
      "eks:UpdateNodegroupConfig",
      "eks:DescribeNodegroup",
      "eks:DescribeUpdate",
    ]
    resources = [local.nodegroup_arn_pattern]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.lambda_function_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_lambda_function" "node_scheduler" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = "handler.handler"
  runtime       = "python3.13"
  timeout       = 60

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.lambda]

  tags = var.tags
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler_invocation" {
  name               = "${var.lambda_function_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "scheduler_invocation" {
  name = "${var.lambda_function_name}-invoke-policy"
  role = aws_iam_role.scheduler_invocation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.node_scheduler.arn
    }]
  })
}

resource "aws_scheduler_schedule" "scale_up" {
  name       = "${var.lambda_function_name}-scale-up"
  group_name = "default"

  schedule_expression          = var.scale_up_schedule_expression
  schedule_expression_timezone = var.schedule_timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.node_scheduler.arn
    role_arn = aws_iam_role.scheduler_invocation.arn

    input = jsonencode({
      cluster_name   = var.cluster_name
      nodegroup_name = var.workload_node_group_name
      desired_size   = var.business_hours_desired_size
      min_size       = var.business_hours_min_size
      max_size       = var.workload_max_size
    })
  }
}

resource "aws_scheduler_schedule" "scale_down" {
  name       = "${var.lambda_function_name}-scale-down"
  group_name = "default"

  schedule_expression          = var.scale_down_schedule_expression
  schedule_expression_timezone = var.schedule_timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.node_scheduler.arn
    role_arn = aws_iam_role.scheduler_invocation.arn

    input = jsonencode({
      cluster_name   = var.cluster_name
      nodegroup_name = var.workload_node_group_name
      desired_size   = 0
      min_size       = 0
      max_size       = var.workload_max_size
    })
  }
}

resource "aws_sns_topic" "alerts" {
  count = var.alert_email != null ? 1 : 0
  name  = "${var.lambda_function_name}-alerts"
  tags  = var.tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.alert_email != null ? 1 : 0

  alarm_name          = "${var.lambda_function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "The node scheduler Lambda failed to update the workload node group's scaling config."
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    FunctionName = aws_lambda_function.node_scheduler.function_name
  }

  tags = var.tags
}
