provider "azuread" {
  tenant_id = var.azureTenantId
}

provider "azurerm" {
  features {}
  tenant_id       = var.azureTenantId
  subscription_id = var.azureSubscriptionId
}
