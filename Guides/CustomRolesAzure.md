# How to manage custom Azure RBAC roles

This guide shows you how to create and manage custom Azure RBAC roles.

---

Table of content

- [How to manage custom Azure RBAC roles](#how-to-manage-custom-azure-rbac-roles)
  - [Overview](#overview)
  - [Prepare a template](#prepare-a-template)
  - [Components of the role definition](#components-of-the-role-definition)
    - [Common attributes](#common-attributes)
    - [Attribute Action and NotAction](#attribute-action-and-notaction)
    - [Attribute DataAction and NotDataAction](#attribute-dataaction-and-notdataaction)
    - [Attribute AssignableScopes](#attribute-assignablescopes)
    - [Sample file](#sample-file)
  - [Managing custom roles](#managing-custom-roles)
    - [Create a custom role](#create-a-custom-role)
    - [Get a custom role](#get-a-custom-role)
    - [Change a custom role](#change-a-custom-role)
    - [Remove a custom role](#remove-a-custom-role)
  - [Create json-file from existing role](#create-json-file-from-existing-role)

## Overview

I will demonstrate how to create a custom Azure role via PowerShell. For that reason a json formatted file is necessary. This file describes not only the permissions bundled into a custom role but also the scope of the partition and more. Let me explain you the structure of that file and later how to use it to create a role. In case of changing your already existing role, you have to customize it and upload it again.

## Prepare a template

The custom role definition is stored in a json-file. Following the scaffolding:

```json
{
  "Name": "<Custom Role Name>",
  "Id": null,
  "IsCustom": true,
  "Description": "<your description>",
  "Actions": [],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": []
}
```

>Hint: A file like this should be prepared to get copies of it for each custom role.

Attributes explained quickly:

| Attribute | Note |
| --- | --- |
| Name | Name of the role |
| Id | Leave it empty, if role is created. A GUID will be generated automatically |
| IsCustom | Must be true for custom roles |
| Description | Short test to indicate the abilities of the role |
| Actions | List of management level permissions (e.g. read, write, delete) |
| NotActions | Explicitly excluded actions |
| DataActions | Data level permissions (e.g. blob read access) |
| NotDataActions | Explicitly excluded data actions |
| AssignableScopes | List of scopes (subscriptions, Resource Groups, resource) a role is available and assignable |

## Components of the role definition

### Common attributes

The ==Name== of the role could be self-chosen and is used in the portal as display name.

The ==Id== is a GUID which is created by Azure at the moment you create the role for the first time. Therefor, ==Id== must be `null` in that situation. Later, if you have to change something for that - now already created role - you have to use the GUID to indicate, which role you would like to change.

The attribute ==IsCustom== must always be `true` (since it is actually a custom role).

Use a short, meaningful ==Description==. It appears also in the portal.

### Attribute Action and NotAction

The attribute ==Action== contains the actions or permission an assignee could perform on the resources of the specified type. The format you have to use is `resourceprovider/resourcetype/permission`. At the moment there are four different permissions

+ read
+ write
+ delete
+ action

`action`is a special permissions and allows you to assign the permission to initiate an action on a resource. This could be e. g. stating a virtual machine. If you use `action` you have also to indicate which action should be allowed. The format now is `resourceprovider/resourcetype/operation/action`. `/action` will always end the allowed operation. `Microsoft.Compute/virtualMachines/start/action` allows to start a virtual machine. `Microsoft.KeyVault/vaults/secrets/delete/action` allows to delete a secret from a key vault and `Microsoft.Network/networkSecurityGroups/join/action` enables an user to associate a NSG to a NIC or subnet.

To get a list of all operations of a provider use

```PowerShell
$AllProviderOperations = Get-AzProviderOperation
$AllProviderOperations | Where-Object { $_.Operation -like 'Microsoft.Storage/*' }
```

To grant all permissions on a resource you could use the `*` as wildcard:

```json
{
  "Name": "<Custom Role Name>",
  "Id": null,
  "IsCustom": true,
  "Description": "<your description>",
  "Actions": [
    "Microsoft.Compute/virtualMachines/*"
    "Microsoft.Storage/storageAccounts/*"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": []
}
```

The attribute ==NotAction== lists all excluded actions. In case of granting all permissions it is possible to exclude a specific. In the following example the role allows to manage a virtual machine except the deletion of it:

```json
{
  "Name": "<Custom Role Name>",
  "Id": null,
  "IsCustom": true,
  "Description": "<your description>",
  "Actions": [
    "Microsoft.Compute/virtualMachines/*"
  ],
  "NotActions": [
    "Microsoft.Compute/virtualMachines/delete"
  ],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": []
}
```

### Attribute DataAction and NotDataAction

A ==DataAction== allows an assignee to perform actions on the data plane of your resource. The storage account's data plane is possibility to access blobs, files, tables and queues. In opposite, the management plane allows you to change settings of the storage account like private endpoint configuration.

To get a list of all data actions of a resource provider use the following cmdlets in a PowerShell session:

```PowerShell
Get-AzProviderOperation Microsoft.KeyVault/* | Where-Object { $_.IsDataAction }
```

The ==NotDataAction== is necessary if you have granted all data actions and you have to exclude a single one e.g.:

```json
{
  "Name": "<Custom Role Name>",
  "Id": null,
  "IsCustom": true,
  "Description": "<your description>",
  "Actions": [],
  "NotActions": [],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*"
  ],
  "NotDataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete"
  ],
  "AssignableScopes": []
}
```

The example above allows an user to perform all the data actions on blob:

+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/deleteBlobVersion/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/permanentDelete/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/filter/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/manageOwnership/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/modifyPermissions/action
+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/runAsSuperUser/action

except deleting a blob since this permissions is mentioned in ==NotDataAction==

+ Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete

>Hint: A ==NotDataAction== is not a *deny*, it's just not granted. If a user has a second role assignment and the second role allows to delete blobs the user is able to delete blobs.

### Attribute AssignableScopes

This attribute is used for declaring where a custom role is available for assignment. This could be

+ a single management group
+ one or more subscriptions
+ one or more resource groups.

>Hint: Follow this [link to the documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-definitions#assignablescopes) to see some examples and further information.

### Sample file

The following is a sample of a custom role definition

```json
{
  "Name": "Junior Administrator",
  "Id": null,
  "IsCustom": true,
  "Description": "Can start/stop virtual machines, read/write blobs, manage messages and associate NSGs to NICs and subnets.",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/deallocate/action",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Network/networkInterfaces/read",
    "Microsoft.Network/networkInterfaces/write",
    "Microsoft.Network/virtualNetworks/subnets/read",
    "Microsoft.Network/virtualNetworks/subnets/write",
    "Microsoft.Network/networkSecurityGroups/join/action"
  ],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
    "Microsoft.Storage/storageAccounts/queueServices/queues/messages/*"
  ],
  "NotActions": [],
  "NotDataActions": [
    "Microsoft.Storage/storageAccounts/queueServices/queues/messages/delete"
  ],
  "AssignableScopes": [
    "/subscriptions/<your-subscription-id>"
  ]
}
```

## Managing custom roles

After a role definition file is created is must be uploaded to use it for assignments. See here how to do that and change custom roles.

### Create a custom role

To create a custom role definition use the following code:

```PowerShell
New-AzRoleDefinition -InputFile <path-to-definition-file>
```

The output shows you the new custom role and could look like this:

```PowerShell
Name             : Junior Administrator
Id               : 10c80c34-3aef-4ef0-9e16-1f5199d8f2d8
IsCustom         : True
Description      : Can start/stop virtual machines, read/write blobs, manage messages and associate NSGs to NICs and subnets.
Actions          : {Microsoft.Compute/virtualMachines/start/action, Microsoft.Compute/virtualMachines/deallocate/action, 
                   Microsoft.Compute/virtualMachines/read, Microsoft.Network/networkInterfaces/read…}
NotActions       : {}
DataActions      : {Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read, 
                   Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write, 
                   Microsoft.Storage/storageAccounts/queueServices/queues/messages/*}
NotDataActions   : {Microsoft.Storage/storageAccounts/queueServices/queues/messages/delete}
AssignableScopes : {/subscriptions/94332174-9d60-4679-a3c7-f2472de99639}
Condition        : 
ConditionVersion : 
```

An important information is the newly created ==Id==. This Id is used later for changing and removing the role.

>Hint: PowerShell would not show you precise information about any failures. Instead, take a look at the *Activity log* of your subscription. To get the activity log in PowerShell use the cmdlet `Get-AzActivityLog`.

>Hint: A demonstration script (New-DISTAzRole.ps1) and role definition file (CustomRoleDemoAzure_Part1.json) could be found [here](./Adds/).

### Get a custom role

To get information of a custom the cmdlet `Get-AzRoleDefinition` must be used. Important parameters are:

| Parameter | Note |
| --- | --- |
| Custom | get only custom roles |
| Name | get a role by name |
| Scope | get roles available at a specific scope |

```PowerShell
Get-AzRoleDefinition -Custom
Get-AzRoleDefinition -Name 'Junior Administrator'
```

### Change a custom role

It's recommended to create another json-file. In this file use the attribute ==Id== to indicate which role should be changed. The remaining attributes must follow the same rule as mentioned above.

Prepare the file and the use the following command:

```PowerShell
Set-AzRoleDefinition -InputFile <path-to-definition-file>
```

>Hint: A demonstration script (Set-DISTAzRole.ps1) and role definition file (CustomRoleDemoAzure_Part2.json) could be found [here](./Adds/).

### Remove a custom role

To remove a role definition use just the Id of the role with the following cmdlet:

```PowerShell
Remove-AzRoleDefinition -Id '61238717-2d62-4c94-af18-bb3d294c2ef9'
```

## Create json-file from existing role

```PowerShell
Get-AzRoleDefinition -Name 'Virtual Machine Contributor' |
  Convertto-Json |
  Out-File -FilePath '<any-valid-path>
```

Open the file in Visual Studio Code (e. g.) to make important changes to use it as definition for a new custom role:

+ replace the Id by `null`.
+ set the attribute IsCustom to `true`.
+ set a new name
+ change all other attributes as necessary.
