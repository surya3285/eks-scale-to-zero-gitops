provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    Project     = "eks-scale-to-zero"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "networking" {
  source = "../../modules/networking"

  name                       = var.cluster_name
  cluster_name               = var.cluster_name
  vpc_cidr                   = var.vpc_cidr
  azs                        = var.azs
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_subnet_cidrs       = var.private_subnet_cidrs
  single_nat_gateway         = var.single_nat_gateway
  enable_interface_endpoints = var.enable_interface_endpoints
  tags                       = local.common_tags
}

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name              = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  subnet_ids                = module.networking.private_subnet_ids_list
  endpoint_public_access    = var.endpoint_public_access
  public_access_cidrs       = var.public_access_cidrs
  enabled_cluster_log_types = var.enabled_cluster_log_types
  tags                      = local.common_tags
}

module "eks_node_groups" {
  source = "../../modules/eks-node-groups"

  cluster_name            = module.eks_cluster.cluster_name
  subnet_ids              = module.networking.private_subnet_ids_list
  system_instance_types   = var.system_instance_types
  system_desired_size     = var.system_desired_size
  system_min_size         = var.system_min_size
  system_max_size         = var.system_max_size
  workload_instance_types = var.workload_instance_types
  workload_capacity_type  = var.workload_capacity_type
  workload_desired_size   = var.workload_desired_size
  workload_min_size       = var.workload_min_size
  workload_max_size       = var.workload_max_size
  tags                    = local.common_tags
}

module "irsa_cluster_autoscaler" {
  source = "../../modules/irsa"

  role_name            = "${var.cluster_name}-cluster-autoscaler-irsa"
  oidc_provider_arn    = module.eks_cluster.oidc_provider_arn
  oidc_provider_url    = module.eks_cluster.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "cluster-autoscaler"
  policy_arns          = [module.eks_node_groups.cluster_autoscaler_policy_arn]
  tags                 = local.common_tags
}

module "irsa_ebs_csi" {
  source = "../../modules/irsa"

  role_name            = "${var.cluster_name}-ebs-csi-irsa"
  oidc_provider_arn    = module.eks_cluster.oidc_provider_arn
  oidc_provider_url    = module.eks_cluster.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "ebs-csi-controller-sa"
  policy_arns          = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
  tags                 = local.common_tags
}

# Lives at root, not inside the eks-cluster module: the addon needs the IRSA
# role's ARN, and that role needs the cluster's OIDC provider, so nesting the
# addon inside the same module as the OIDC provider would create a cycle
# between two module calls. This resource sits after both in the graph.
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.eks_cluster.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = module.irsa_ebs_csi.role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [module.eks_node_groups]

  tags = local.common_tags
}

module "scaling_scheduler" {
  source = "../../modules/scaling-scheduler"

  cluster_name                   = module.eks_cluster.cluster_name
  workload_node_group_name       = module.eks_node_groups.workload_node_group_name
  lambda_function_name           = "${var.cluster_name}-node-scheduler"
  scale_up_schedule_expression   = var.scale_up_schedule_expression
  scale_down_schedule_expression = var.scale_down_schedule_expression
  schedule_timezone              = var.schedule_timezone
  business_hours_desired_size    = var.business_hours_desired_size
  business_hours_min_size        = var.business_hours_min_size
  workload_max_size              = var.workload_max_size
  alert_email                    = var.alert_email
  tags                           = local.common_tags
}
