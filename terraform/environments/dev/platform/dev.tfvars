region = "us-east-1"

# Same bucket terraform/bootstrap created; only the state *key* differs from ../dev.tfvars.
cluster_state_bucket = "REPLACE-WITH-YOUR-STATE-BUCKET-NAME"
cluster_state_key    = "dev/terraform.tfstate"

# Verify these are still current before applying:
#   https://artifacthub.io/packages/helm/argo/argo-cd
#   https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler
argocd_chart_version             = "10.1.2"
cluster_autoscaler_chart_version = "9.58.0"
