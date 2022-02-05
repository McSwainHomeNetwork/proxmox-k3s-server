variable "proxmox_url" {
  type        = string
  sensitive   = true
  description = "The API URL for Proxmox, ending with `/api2/json`"
}

variable "proxmox_tls_insecure" {
  type    = bool
  default = true
}

variable "server_friendly_name" {
  type    = string
  default = "gorilla"
}

variable "proxmox_target_node" {
  type    = string
  default = "pve"
}

variable "k3os_version" {
  type    = string
  default = "v0.21.5-k3s2r0"
}

variable "ipxe_host" {
  type = string
}

variable "ipxe_username" {
  type = string
}

variable "ipxe_password" {
  type = string
}

variable "dns_server" {
  type      = string
  sensitive = true
}

variable "etcd_s3_backup_endpoint" {
  type      = string
  sensitive = true
}

variable "etcd_s3_backup_access_key" {
  type      = string
  sensitive = true
}

variable "etcd_s3_backup_secret_key" {
  type      = string
  sensitive = true
}

variable "etcd_s3_backup_bucket" {
  type      = string
  default   = "etcd-backups"
  sensitive = true
}

variable "k8s_server_url" {
  type      = string
  sensitive = true
}

variable "k8s_server_host" {
  type      = string
  sensitive = true
}