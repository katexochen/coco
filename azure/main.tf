terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.54.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "name_prefix" {
  type = string
}

variable "enable_sgx_pool" {
  type = bool
}

variable "enable_snp_pool" {
  type = bool
}

variable "enable_kata" {
  type = bool
}

locals {
  name = "${var.name_prefix}-aks"
}

resource "azurerm_resource_group" "rg" {
  name     = local.name
  location = "West Europe"
}

#
# Compare aks setup at
# https://github.com/tkubica12/azure-workshops/blob/6fb761a26cc91a72be41e562ccedc140dd1be392/d-data-security/terraform/aks.tf
#

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = local.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = local.name

  identity {
    type = "SystemAssigned"
  }

  confidential_computing {
    sgx_quote_helper_enabled = true
  }

  default_node_pool {
    name                = "defaultpool"
    node_count          = 1
    vm_size             = "Standard_B2ms"
    enable_auto_scaling = false
    type                = "VirtualMachineScaleSets"
  }
}

// Confidential nodepool
resource "azurerm_kubernetes_cluster_node_pool" "confidential_node" {
  count                 = var.enable_snp_pool ? 1 : 0
  name                  = "sevsnp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size               = "Standard_DC2as_v5"
  node_count            = 1
  zones                 = ["2"]

  node_labels = {
    securetype = "sevsnp"
  }
}

// Nodepool supporting SXG confidential containers
resource "azurerm_kubernetes_cluster_node_pool" "confidential_sxg_containers" {
  count                 = var.enable_sgx_pool ? 1 : 0
  name                  = "sgx"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size               = "Standard_DC2s_v3"
  node_count            = 1
  zones                 = ["1"]

  node_labels = {
    securetype = "sgx"
  }
}

// Nodepool supporting nested virtualization kata containers
resource "azurerm_kubernetes_cluster_node_pool" "kata" {
  count                 = var.enable_kata ? 1 : 0
  name                  = "kata"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size               = "Standard_E2s_v3"
  node_count            = 1
  zones                 = ["1"]
  workload_runtime      = "KataMshvVmIsolation"
  os_sku                = "Mariner"

  node_labels = {
    securetype = "kata"
  }
}

resource "local_file" "kubeconfig" {
  depends_on = [azurerm_kubernetes_cluster.cluster]
  filename   = "./kube.conf"
  content    = azurerm_kubernetes_cluster.cluster.kube_config_raw
}
