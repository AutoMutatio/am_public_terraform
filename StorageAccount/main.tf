resource "azurerm_resource_group" "storageResourceGroup" {
  name     = coalesce(var.resourceGroup, var.storageAccountName)
  location = var.azureLocation
}

resource "azurerm_storage_account" "storageAccount" {
  name                          = var.storageAccountName
  resource_group_name           = azurerm_resource_group.storageResourceGroup.name
  location                      = azurerm_resource_group.storageResourceGroup.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  is_hns_enabled                = true
  public_network_access_enabled = true
  tags = {
    type = "AutoMutatio Storage"
  }
}


resource "azurerm_storage_container" "container" {
  for_each              = toset(var.blobContainers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.storageAccount.name
  container_access_type = "private"
}

resource "azuread_application" "storageAccount" {
  display_name = var.storageAccountName
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "syncPrincipal" {
  client_id                    = azuread_application.storageAccount.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "syncPrincipal" {
  service_principal_id = azuread_service_principal.syncPrincipal.object_id
}

resource "azurerm_role_assignment" "syncPrincipal" {
  scope                = azurerm_storage_account.storageAccount.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = resource.azuread_service_principal.syncPrincipal.id
}

resource "azurerm_role_assignment" "storageBlobDataContributor" {
  for_each = toset(concat(
    data.azuread_users.blobContibutors.object_ids,
    data.azuread_groups.blobContibutors.object_ids,
  ))
  scope                = azurerm_storage_account.storageAccount.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "storageBlobDataReader" {
  for_each = toset(concat(
    data.azuread_users.blobReaders.object_ids,
    data.azuread_groups.blobReaders.object_ids
  ))
  scope                = azurerm_storage_account.storageAccount.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
