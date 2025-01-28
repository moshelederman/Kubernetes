provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
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
terraform {
  backend "s3" {
    bucket         = "moshe-terrarorm"
    key            = "aks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
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
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig.yaml"
  content  = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
}