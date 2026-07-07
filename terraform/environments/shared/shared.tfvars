region = "us-east-1"

# Must be globally unique across all of AWS.
cur_bucket_name = "eks-scale-to-zero-cur-REPLACE-WITH-SOMETHING-UNIQUE"

monthly_budget_amount         = 50
per_environment_budget_amount = 25
environments                  = ["dev", "staging"]

alert_email = "you@example.com"
