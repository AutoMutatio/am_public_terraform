variable "storageAccountName" {
  type = string
  description = "The name of the storage account to create"
}

variable "azureTenantId" {
  type = string
  description = "The UUID of the Azure tenant for resources and the security users"
}

variable "azureSubscriptionId" {
  type = string
  description = "The UUID of the Azure subscription to create the stroage account in"
}

variable "resourceGroup" {
  type = string
  description = "The resource group to create the storage account in. If ommitted the storageAccountName will be used"
  default = null
}

variable "azureLocation" {
  type = string
  description = "The azure region to use for all the resources"
  default = "uksouth"
}

variable "blobReaderUsers" {
  type = list(string)
  description = "List of users (User Principal Names) to grant the Storage Blob Data Reader role"
  default = []
}

variable "blobContibutorUsers" {
  type = list(string)
  description = "List of users (User Principal Names) to grant the Storage Blob Data Contributor role"
   default = []
}

variable "blobReaderGroups" {
  type = list(string)
  description = "List of groups (Display Names) to grant the Storage Blob Data Reader role"
  default = []
}

variable "blobContibutorGroups" {
  type = list(string)
  description = "List of groups (Display Names) to grant the Storage Blob Data Contributor role"
   default = []
}

variable "blobContainers" {
  type = list(string)
  description = "The names of the blob containers to create"
}