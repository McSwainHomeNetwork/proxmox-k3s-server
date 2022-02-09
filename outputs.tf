output "node_token" {
  value       = data.local_file.node_token.content
  sensitive   = true
  description = "The node join token"
}
