variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

terraform {
  backend "s3" {
    bucket         = "moshe-terrarorm"
    key            = "aks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-resource-group"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aksdns"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "null_resource" "copy_files" {
  provisioner "local-exec" {
    command = <<EOT
      sshpass -p "${var.ssh_password}" scp -o StrictHostKeyChecking=no \
        ./app.yaml ./mysql.yaml ./secret.yaml ./configmap.yaml \
        ${var.ssh_user}@${var.remote_host}:/home/${var.ssh_user}/
    EOT
  }
}

variable "ssh_user" {
  description = "Username for SSH"
}

variable "ssh_password" {
  description = "Password for SSH"
  sensitive   = true
}

variable "remote_host" {
  description = "Remote machine hostname or IP"
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig.yaml"
  content  = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
}
variable "client_id" {
  description = "Azure Client ID"
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Client Secret"
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  sensitive   = true
}
