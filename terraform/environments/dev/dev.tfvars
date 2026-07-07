region       = "us-east-1"
environment  = "dev"
cluster_name = "eks-scale-to-zero-dev"

# Verify this is inside EKS's standard support window before applying --
# https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
# A version past standard support bills an extra $0.60/hr/cluster.
kubernetes_version = "1.31"

vpc_cidr             = "10.0.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
single_nat_gateway   = true

# Restrict this to your own IP before applying, e.g. ["203.0.113.4/32"].
# Find yours with: curl -s ifconfig.me
public_access_cidrs = ["0.0.0.0/0"]

system_instance_types   = ["t3.medium"]
workload_instance_types = ["t3.medium"]
workload_capacity_type  = "ON_DEMAND"
workload_max_size       = 2

# Change to your own timezone -- schedules are evaluated in this zone.
schedule_timezone              = "America/New_York"
scale_up_schedule_expression   = "cron(0 8 ? * MON-FRI *)"
scale_down_schedule_expression = "cron(0 19 ? * MON-FRI *)"
business_hours_desired_size    = 1

# Set to your email to get notified if the scheduler Lambda fails.
alert_email = null

tags = {
  Owner = "your-name"
}
