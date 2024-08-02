This [tofu](https://developer.hashicorp.com/tofu/docs) module will create an
Azure Storage Account and a service principal to use for syncing files from file
systems to the AutoMutatio application.

tofu is an Infrastructure as Code tool that automates updating resources using
configuration files that can be managed in a source code control system (e.g. GitHub).
tofu maintains a state file of the previous resources created. This is then
used to detect changes and only require incremental updates ro resources.

To use this module you will need an Azure Active Directory account and an Azure
subscription. The account must have permission to create new resources in the
subscription and to be able to grant roles to those resources.

# Required Tools

Install the required tools.

- [tofu CLI](https://developer.hashicorp.com/tofu/downloads)
- [rclone](https://rclone.org/downloads/)
- [Visual Studio Code](https://code.visualstudio.com/download) - Optional development environment

# Configuration

NOTE: We recommend using groups rather than users to assign roles to.

1. Copy the template_tofu.tfvars.json to tofu.tfvars.json. This is a [tofu Variables JSON file](https://developer.hashicorp.com/tofu/language/values/variables).
2. Edit the tofu.tfvars.json using the parameters

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

3. Run tofu [Init](https://developer.hashicorp.com/tofu/cli/commands/init) to
   initialize the tofu environment. This is only required the first time or if the
   providers or backend changes.

```bash
tofu init
```

4. Run tofu [Plan](https://developer.hashicorp.com/tofu/cli/commands/plan) to verify
   your configuration see what resources would be create, modified, or deleted.

```bash
tofu plan
```

5. Run tofu [Apply](https://developer.hashicorp.com/tofu/cli/commands/apply) to apply.
   The proposed changes (same as plan) will be shown. If correct then type yes to continue or no to cancel.

```bash
tofu apply
```

6. You may choose to logout of azure

```
az logout
```

# Sync files to the Storage Account

The following shows the basic sequence of commands to copy files to azure storage.
For automated processing you will want to create a script in PowerShell or sh/bash.

1. Get the tenantId from the azureTenantId in the tofu.tfvars.json.
2. Get the clientId by running the following command in this directory.

```
tofu output -raw clientId
```

3. Get the clientSecret by running the following command in this directory.
   Treat this as securely as you would a password.

```
tofu output -raw clientSecret
```

4. Set environment vairables for rclone to connect using the service principal, replace [variable] with the appropriate values.

If using powershell

```
$Env:AZURE_TENANT_ID=$(tofu output -raw tenantId)
$Env:AZURE_CLIENT_ID=$(tofu output -raw clientId)
$Env:AZURE_CLIENT_SECRET=$(tofu output -raw clientSecret)
```

If using a unix shell

```sh
AZURE_TENANT_ID=`tofu output -raw tenantId`
AZURE_CLIENT_ID=`tofu output -raw clientId`
AZURE_CLIENT_SECRET=`tofu output -raw clientSecret`
```

5. Use the following command to get the URL to the containers.
   (e.g. https://amupload45547dfdfhjd.blob.core.windows.net/files)

```
tofu output containers
```

6. Use the [rclone sync](https://rclone.org/commands/rclone_sync/) [Azure Storage Backend](https://rclone.org/azureblob/)
   command to synchronize across files and folders.
   This command will delete any files no longer on the source. The copy command can be used instead to not delete files.
   See the [rclone documentation](https://rclone.org/commands/rclone_sync/) for more flags such as exclusions.

   1. If not already installed [Download and Install rclone](https://rclone.org/downloads/). And add it to your path.
   2. Open a terminal (e.g. PowerShell, Command Prompt, bash) on the computer with access to the files to upload.
   3. Login using step 4 above must be completed first.
   4. Use the following command template to upload the files and folders. Replace [variable] with the appropriate values.

```
rclone sync "[localPath]" ":azureblob,env_auth,account=[storageAccountName]:[blobContainerName]" -M
```

# Create AutoMutatio Feed

1. Using a web browser login using an AutoMutatio admin account to the require project.
2. Click the Feed icon in the menu bar.
3. Click the Add Feed icon in the toolbar.
4. Click the Microsoft Azure Storage Blob button.
5. Enter the name for the feed. This could be anything that describes the source of the feed data.
6. Run the following command in this directory to get the secure connection string from the storage account. Treat this as securely as you would a password.

```
tofu output -raw blobConnectionString
```

7. Copy and paste the output of that command into the Blob Connection String field
8. Type the container name to sync into the Container/Folder Path Field (e.g. container1/folderA).
9. Click OK to create the feed and start syncing.

# Further Reading

- tofu Module [azuread_users](https://registry.tofu.io/providers/hashicorp/azuread/latest/docs/data-sources/users) - Get Azure Active Directory Users by User Principal Names
- tofu Module [azuread_groups](https://registry.tofu.io/providers/hashicorp/azuread/latest/docs/data-sources/groups) - Get Azure Active Directory Groups by Display Names
- tofu Module [azurerm_resource_group](https://registry.tofu.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) - Create an [Azure Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- tofu Module [azurerm_storage_account](https://registry.tofu.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) - Create an [Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- tofu Module [azurerm_storage_container](https://registry.tofu.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) - Create a [Blob Container](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) to store files in an storage account
- tofu Module [azurerm_role_assignment](https://registry.tofu.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) - Assign an [Azure Role](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) on the storage account to a user or group
- tofu Module [azuread_service_principal](https://registry.tofu.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) - Create a service principal for scripted sync of data
