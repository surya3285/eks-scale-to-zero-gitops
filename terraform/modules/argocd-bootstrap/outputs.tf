output "argocd_namespace" {
  value = var.argocd_namespace
}

output "argocd_initial_admin_password" {
  description = "Initial admin password for the Argo CD UI/CLI (username: admin). Rotate or disable this account once you've set up your own users."
  value       = data.kubernetes_secret.argocd_initial_admin.data["password"]
  sensitive   = true
}
