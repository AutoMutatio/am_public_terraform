This [Terraform](https://developer.hashicorp.com/terraform/docs) module will create an
Azure Storage Account and a service principal to use for syncing files from file
systems to the AutoMutatio application.

Terraform is an Infrastructure as Code tool that automates updating resources using
configuration files that can be managed in a source code control system (e.g. GitHub).
Terraform maintains a state file of the previous resources created. This is then
used to detect changes and only require incremental updates ro resources.

To use this module you will need an Azure Active Directory account and an Azure
subscription. The account must have permission to create new resources in the
subscription and to be able to grant roles to those resources.

# Required Tools

The [Azure Cloud Shell](http://shell.azure.com/) [Docs](https://learn.microsoft.com/en-us/azure/cloud-shell/overview)
provides all the required tools and automatically logs you into your azure account in the shell.

You will need to install rclone into Azure Cloud Shell (update to latest version).

```
mkdir ~/bin
cd ~/bin
$RCLONE_VERSION="1.63.1"
curl -O "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip"
unzip rclone*.zip
rm rclone*.zip
mv "rclone-v${RCLONE_VERSION}-linux-amd64/rclone" .
rm -r "rclone-v${RCLONE_VERSION}-linux-amd64"
```

Alterantively install the following tools on your machine or in [Terraform Cloud](https://www.terraform.io/).

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- [rclone](https://rclone.org/downloads/)
- [Visual Studio Code](https://code.visualstudio.com/download) - Optional development environment

# Configuration

NOTE: We recommend using groups rather than users to assign roles to.

1. Copy the template_terraform.tfvars.json to terraform.tfvars.json. This is a [Terraform Variables JSON file](https://developer.hashicorp.com/terraform/language/values/variables).
2. Edit the terraform.tfvars.json using the parameters

| Name                 | Type         | Description                                                                                                                                                                                      |
| -------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| storageAccountName   | string       | The name of the storage account to create. Recommended to start with the am prefix and a random character suffix for obscurity. Rules: 3-24 length, numbers and lowercase letters only.          |
| azureTenantId        | string       | The UUID of the Azure tenant for resources and the security users.                                                                                                                               |
| azureSubscriptionId  | string       | The UUID of the Azure subscription to create the stroage account in.                                                                                                                             |
| resourceGroup        | string       | The resource group to create the storage account in. If ommitted the storageAccountName will be used.                                                                                            |
| azureLocation        | string       | The azure region to use for all the resources. List of locations (e.g. uksouth) can be obtained using the command `az account list-locations -o tsv`                                             |
| blobReaderUsers      | list(string) | List of users (User Principal Names) to grant the Storage Blob Data Reader role.                                                                                                                 |
| blobContibutorUsers  | list(string) | List of users (User Principal Names) to grant the Storage Blob Data Contributor role.                                                                                                            |
| blobReaderGroups     | list(string) | List of groups (Display Names) to grant the Storage Blob Data Reader role.                                                                                                                       |
| blobContibutorGroups | list(string) | List of groups (Display Names) to grant the Storage Blob Data Contributor role.                                                                                                                  |
| blobContainers       | list(string) | The names of the blob containers to create. These are the virtual "drives" to store files in. Use one container per source file system. Rules: 3-63 length, numbers and lower case letters only. |

# Creating or updating the storage account

Run the following to create the storage account or update it if the configuration (e.g. users, groups) change.

1. Open a terminal (e.g. PowerShell or sh/bash) and change directory to the folder containing this file.
2. If not using the Azure Cloud Shell then Login to the Azure using an account with the
   required permissions. This will open a web browser window to complete the login.

```bash
az login
```

3. Run Terraform [Init](https://developer.hashicorp.com/terraform/cli/commands/init) to
   initialize the Terraform environment. This is only required the first time or if the
   providers or backend changes.

```bash
terraform init
```

4. Run Terraform [Plan](https://developer.hashicorp.com/terraform/cli/commands/plan) to verify
   your configuration see what resources would be create, modified, or deleted.

```bash
terraform plan
```

5. Run Terraform [Apply](https://developer.hashicorp.com/terraform/cli/commands/apply) to apply.
   The proposed changes (same as plan) will be shown. If correct then type yes to continue or no to cancel.

```bash
terraform apply
```

6. You may choose to logout of azure

```
az logout
```

# Sync files to the Storage Account

The following shows the basic sequence of commands to copy files to azure storage.
For automated processing you will want to create a script in PowerShell or sh/bash.

1. Get the tenantId from the azureTenantId in the terraform.tfvars.json.
2. Get the clientId by running the following command in this directory.

```
terraform output -raw clientId
```

3. Get the clientSecret by running the following command in this directory.
   Treat this as securely as you would a password.

```
terraform output -raw clientSecret
```

4. Login to azcopy using the service principal, replace [variable] with the appropriate values.

```
$env:AZCOPY_SPA_CLIENT_SECRET="[clientSecret]"; azcopy login --service-principal --application-id [clientId]  --tenant-id [tenantId]
```

5. Use the following command to get the URL to the containers.
   (e.g. https://amupload45547dfdfhjd.blob.core.windows.net/files)

```
terraform output containers
```

6. Use the [rclone sync](https://rclone.org/commands/rclone_sync/) [Azure Storage Backend](https://rclone.org/azureblob/)
   command to synchronize across files and folders, replace [variable] with the appropriate values.
   This command will delete any files no longer on the source. The copy command can be used instead to not delete files.
   See the documentation for more flags such as exclusions.

```
rclone sync "[localPath]" -M ":azureblob,env_auth,account=[storageAccountName]:[blobContainerName]"
```

# Create AutoMutatio Feed

1. Using a web browser login using an AutoMutatio admin account to the require project.
2. Click the Feed icon in the menu bar.
3. Click the Add Feed icon in the toolbar.
4. Click the Microsoft Azure Storage Blob button.
5. Enter the name for the feed. This could be anything that describes the source of the feed data.
6. Run the following command in this directory to get the secure connection string from the storage account. Treat this as securely as you would a password.

```
terraform output -raw blobConnectionString
```

7. Copy and paste the output of that command into the Blob Connection String field
8. Type the container name to sync into the Container/Folder Path Field.
9. Click OK to create the feed and start syncing.

# Further Reading

- Terraform Module [azuread_users](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/users) - Get Azure Active Directory Users by User Principal Names
- Terraform Module [azuread_groups](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/groups) - Get Azure Active Directory Groups by Display Names
- Terraform Module [azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) - Create an [Azure Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- Terraform Module [azurerm_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) - Create an [Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- Terraform Module [azurerm_storage_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) - Create a [Blob Container](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) to store files in an storage account
- Terraform Module [azurerm_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) - Assign an [Azure Role](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) on the storage account to a user or group
- Terraform Module [azuread_service_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) - Create a service principal for scripted sync of data
