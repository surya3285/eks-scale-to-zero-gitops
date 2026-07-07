region       = "us-east-1"
environment  = "staging"
cluster_name = "eks-scale-to-zero-staging"

# Verified via `aws eks describe-cluster-versions` on 2026-07-07: 1.31 is
# already in extended support (+$0.60/hr). 1.34 has standard support until
# 2026-12-02 and is old enough that Cluster Autoscaler has a matching image.
kubernetes_version = "1.34"

vpc_cidr             = "10.1.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
single_nat_gateway   = true

# Restrict this to your own IP before applying, e.g. ["203.0.113.4/32"].
# Find yours with: curl -s ifconfig.me
public_access_cidrs = ["0.0.0.0/0"]

system_instance_types   = ["t3.medium"]
workload_instance_types = ["t3.medium"]
workload_capacity_type  = "ON_DEMAND"
workload_max_size       = 3

# Change to your own timezone -- schedules are evaluated in this zone.
schedule_timezone              = "America/New_York"
scale_up_schedule_expression   = "cron(0 8 ? * MON-FRI *)"
scale_down_schedule_expression = "cron(0 19 ? * MON-FRI *)"
business_hours_desired_size    = 2

# Set to your email to get notified if the scheduler Lambda fails.
alert_email = null

tags = {
  Owner = "your-name"
}
