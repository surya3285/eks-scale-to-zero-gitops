output "argocd_namespace" {
  value = module.argocd_bootstrap.argocd_namespace
}

output "argocd_initial_admin_password" {
  value     = module.argocd_bootstrap.argocd_initial_admin_password
  sensitive = true
}

output "argocd_port_forward_command" {
  value = "kubectl port-forward svc/argocd-server -n ${module.argocd_bootstrap.argocd_namespace} 8080:80"
}
