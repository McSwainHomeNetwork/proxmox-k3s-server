terraform {
  backend "s3" {
    bucket                      = "terraform-states-mcswainhomenetwork"
    key                         = "terraform-proxmox-k3s-server.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://192.168.1.135:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    proxmox = {
      source  = "McSwainHomeNetwork/proxmox"
      version = "2.9.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

resource "local_file" "k3os_config" {
  content  = local.k3os_config
  filename = "${path.module}/config-${var.server_friendly_name}.yaml"
}

locals {
  k3os_config = templatefile("${path.module}/config.yaml.tpl", {
    server_name               = var.server_friendly_name,
    dns_servers               = var.dns_servers,
    s3_endpoint               = var.etcd_s3_backup_endpoint,
    s3_access_key             = var.etcd_s3_backup_access_key,
    s3_secret_key             = var.etcd_s3_backup_secret_key,
    s3_folder                 = "k8s-${var.server_friendly_name}",
    s3_bucket                 = var.etcd_s3_backup_bucket,
    node_password             = random_string.node_password.result,
    token                     = random_string.token.result,
    aescbc_encryption_key_b64 = length(var.encryption_key_base64) > 0 ? var.encryption_key_base64 : random_id.encryption_key[0].b64_std,
    ssh_keys                  = concat([tls_private_key.provision_key.public_key_openssh], var.additional_ssh_keys)
  })
}

resource "random_string" "node_password" {
  length  = 32
  special = false
}

resource "random_string" "token" {
  length  = 32
  special = false
}

resource "tls_private_key" "provision_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "null_resource" "ipxe_k3os_config" {
  triggers = {
    force_recreate_on_change_of = local.k3os_config
  }
  provisioner "file" {
    source      = local_file.k3os_config.filename
    destination = "/mnt/storage/netboot.xyz/assets/${var.server_friendly_name}.yaml"
    connection {
      type     = "ssh"
      user     = var.ipxe_username
      password = var.ipxe_password
      host     = var.ipxe_host
    }
  }
}

module "pxe-vm" {
  source  = "app.terraform.io/McSwainHomeNetwork/pxe-vm/proxmox"
  version = "0.0.10"

  name = "k3s-server-${var.server_friendly_name}"

  proxmox_url          = var.proxmox_url
  proxmox_target_node  = var.proxmox_target_node
  proxmox_tls_insecure = var.proxmox_tls_insecure

  ipxe_initrd_name     = "k3os-initrd-amd64"
  ipxe_kernel_name     = "k3os-vmlinuz-amd64"
  ipxe_media_root      = "https://github.com/rancher/k3os/releases/download/${var.k3os_version}/"
  ipxe_server_host     = var.ipxe_host
  ipxe_server_username = var.ipxe_username
  ipxe_server_password = var.ipxe_password
  ipxe_cmdline_args    = "k3os.mode=install k3os.install.device=/dev/vda k3os.install.silent=true k3os.install.config_url=http://${var.ipxe_host}/${var.server_friendly_name}.yaml k3os.install.iso_url=$${media_root}/k3os-amd64.iso mcswain.id=${null_resource.ipxe_k3os_config.id}"
  ipxe_menu_path       = "/mnt/storage/netboot.xyz/config/menus"

  mac_address = "00005e862519"

  cpu_cores = 8
  memory    = 16384

  disks = [{
    size    = "16G"
    storage = "local-lvm"
    type    = "virtio"
  }]
}

resource "random_id" "encryption_key" {
  byte_length = 32
  count       = length(var.encryption_key_base64) > 0 ? 0 : 1
}

resource "null_resource" "k3os_provision" {
  triggers = {
    force_recreate_on_change_of = local.k3os_config
  }

  # Remove provision key after provisioning
  provisioner "remote-exec" {
    inline = [
      "sudo mount -o rw,remount /k3os/system",
      "sudo grep -v '${tls_private_key.provision_key.public_key_openssh}' /k3os/system/config.yaml > tmpfile && sudo mv tmpfile /k3os/system/config.yaml",
      "sudo chmod 0600 /k3os/system/config.yaml",
      "sudo /sbin/reboot -d 10"
    ]
    connection {
      type        = "ssh"
      user        = "rancher"
      host        = module.pxe-vm.ssh_host
      private_key = tls_private_key.provision_key.private_key_pem
      script_path = "/home/rancher/terraform_provisioners_%RAND%.sh"
    }
  }
}
