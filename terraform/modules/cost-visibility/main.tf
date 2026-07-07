data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cur" {
  bucket = var.cur_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cur" {
  bucket = aws_s3_bucket.cur.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket = aws_s3_bucket.cur.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cur_bucket" {
  statement {
    sid    = "EnableDataExportsToWriteAndCheckPolicy"
    effect = "Allow"

    principals {
      type = "Service"
      # billingreports.amazonaws.com covers legacy CUR tooling that still
      # reads the same bucket policy shape; bcm-data-exports.amazonaws.com
      # is the CUR 2.0 / Data Exports service actually used below.
      identifiers = ["billingreports.amazonaws.com", "bcm-data-exports.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
      "s3:GetBucketPolicy",
    ]

    resources = [
      aws_s3_bucket.cur.arn,
      "${aws_s3_bucket.cur.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*",
        "arn:aws:bcm-data-exports:us-east-1:${data.aws_caller_identity.current.account_id}:export/*",
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "cur" {
  bucket = aws_s3_bucket.cur.id
  policy = data.aws_iam_policy_document.cur_bucket.json
}

# Lets Cost Explorer/Budgets break spend down by our Environment/Project
# tags. AWS only allows activating a tag key once it has appeared on at
# least one billed resource -- on a genuinely fresh account this can 404 on
# the very first apply if the tagged cluster resources haven't shown up in
# billing data yet (takes up to ~24h). If that happens, apply everything
# else first and re-apply this resource the next day.
resource "aws_ce_cost_allocation_tag" "this" {
  for_each = toset(var.cost_allocation_tag_keys)

  tag_key = each.value
  status  = "Active"
}

resource "aws_bcmdataexports_export" "cur" {
  provider = aws.us_east_1

  export {
    name = "eks-scale-to-zero-cur"

    data_query {
      query_statement = "SELECT * FROM COST_AND_USAGE_REPORT"

      table_configurations = {
        COST_AND_USAGE_REPORT = {
          TIME_GRANULARITY                      = "HOURLY" # hourly is what actually shows the scale-to-zero cost drop
          INCLUDE_RESOURCES                     = "TRUE"   # resource-level detail (e.g. which NAT gateway, which instance)
          INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE"
          INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE"
        }
      }
    }

    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.cur.id
        s3_prefix = "cur"
        s3_region = var.region

        s3_output_configurations {
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
          overwrite   = "OVERWRITE_REPORT"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }

  depends_on = [aws_s3_bucket_policy.cur]
}

resource "aws_budgets_budget" "overall" {
  provider = aws.us_east_1

  name         = "eks-scale-to-zero-overall"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

resource "aws_budgets_budget" "per_environment" {
  for_each = toset(var.environments)
  provider = aws.us_east_1

  name         = "eks-scale-to-zero-${each.value}"
  budget_type  = "COST"
  limit_amount = tostring(var.per_environment_budget_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name = "TagKeyValue"
    # format() avoids Terraform's "$${" literal-brace escape rule kicking in
    # if this were written as a plain interpolated string with a literal $.
    values = [format("user:Environment$%s", each.value)]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  depends_on = [aws_ce_cost_allocation_tag.this]
}
