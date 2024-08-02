output "storageAccountName" {
  value = resource.azurerm_storage_account.storageAccount.name
}

output "blobUrl" {
  value = resource.azurerm_storage_account.storageAccount.primary_blob_endpoint
}

output "blobConnectionString" {
  value = resource.azurerm_storage_account.storageAccount.primary_blob_connection_string
  sensitive = true
}

output "containers" {
  value = {
    for container in resource.azurerm_storage_container.container: container.name=> "${resource.azurerm_storage_account.storageAccount.primary_blob_endpoint}${container.name}"
  }
}

output "clientId" {
  value = resource.azuread_service_principal.syncPrincipal.client_id
  sensitive = true
}

output "clientSecret" {
  value = resource.azuread_service_principal_password.syncPrincipal.value
  sensitive = true
}