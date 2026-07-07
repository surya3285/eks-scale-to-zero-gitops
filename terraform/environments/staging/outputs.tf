output "cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "workload_node_group_name" {
  value = module.eks_node_groups.workload_node_group_name
}

output "oidc_provider_arn" {
  description = "Needed when configuring the Helm/ArgoCD bootstrap in Phase 3."
  value       = module.eks_cluster.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Run this to point kubectl at this cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks_cluster.cluster_name}"
}
