output "node_token" {
  value       = data.local_file.node_token.content
  sensitive   = true
  description = "The node join token"
}

output "kubeconfig" {
  value       = data.local_file.kubeconfig.content
  sensitive   = true
  description = "The default kubeconfig for bootstrapping. Use this to create proper roles, then never use again."
}
