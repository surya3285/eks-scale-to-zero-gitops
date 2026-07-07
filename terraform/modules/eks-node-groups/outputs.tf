output "node_role_arn" {
  description = "IAM role ARN shared by both node groups."
  value       = aws_iam_role.node.arn
}

output "system_node_group_name" {
  value = aws_eks_node_group.system.node_group_name
}

output "workload_node_group_name" {
  value = aws_eks_node_group.workload.node_group_name
}

output "cluster_autoscaler_policy_arn" {
  description = "IAM policy ARN to attach to the Cluster Autoscaler's IRSA role (created in the environment root via the irsa module)."
  value       = aws_iam_policy.cluster_autoscaler.arn
}
