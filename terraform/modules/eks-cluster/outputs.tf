output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "ID of the cluster's primary security group (created by EKS)."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_version" {
  description = "Running Kubernetes version."
  value       = aws_eks_cluster.this.version
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider, for use as an irsa module input."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL without the https:// scheme, for use as an irsa module input."
  value       = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}
