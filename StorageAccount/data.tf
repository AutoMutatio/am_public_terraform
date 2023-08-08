data "azuread_client_config" "current" {}

data "azuread_users" "blobReaders" {
  user_principal_names = var.blobReaderUsers
}

data "azuread_groups" "blobReaders" {
  display_names = var.blobReaderGroups
}

data "azuread_users" "blobContibutors" {
  user_principal_names = var.blobContibutorUsers
}

data "azuread_groups" "blobContibutors" {
  display_names = var.blobContibutorGroups
}
