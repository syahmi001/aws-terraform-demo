resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}

  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID
}

resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-rg"
  location = "Southeast Asia"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "standard_ds2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.ARM_CLIENT_ID
    client_secret = var.ARM_CLIENT_SECRET
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}