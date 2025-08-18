# How to manage custom roles in Entra ID

This guide shows you how to create, update and remove custom roles in Entra ID.

---

Table of content

- [How to manage custom roles in Entra ID](#how-to-manage-custom-roles-in-entra-id)
  - [Prerequisites](#prerequisites)
    - [PowerShell Modules](#powershell-modules)
    - [Permissions](#permissions)
  - [Create a custom role](#create-a-custom-role)
  - [Assign a custom role to a user](#assign-a-custom-role-to-a-user)
  - [Unassign a custom role](#unassign-a-custom-role)
  - [Update a custom role](#update-a-custom-role)
  - [Remove a custom role](#remove-a-custom-role)

---

## Prerequisites

### PowerShell Modules

This guides uses the Microsoft Graph PowerShell SDK. At the moment of creating this document, the Microsoft.Entra modules don't support managing custom roles in Entra ID.

```PowerShell
Install-PSResource -Name Microsoft.Graph
```

### Permissions

For all activities of this guide (create, update and remove custom roles) you need the permission `RoleManagement.ReadWrite.All`. For additional activities like reading and creating users, `User.ReadWrite.All` is also required.

To sign in with all permissions use:

```PowerShell
Connect-MgGraph -Scope RoleManagement.ReadWrite.Directory,User.ReadWrite.All
```

## Create a custom role

First, create some variables for the display name, a description and the template ID:

```PowerShell
$displayName = "SC300 User Only Admin"
$description = "This role enables user managment without group management."
$templateId = (New-Guid).Guid
```

Second, create an array of all permissions which should be assigned by the custom role. In the [documentation](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/custom-user-permissions) you could find all roles available.
> Note, that not all existing permissions in Entra ID could be used in custom roles.

```PowerShell
$allowedResourceAction =
@(
"microsoft.directory/applications/basic/update"
"microsoft.directory/applications/credentials/update"
"microsoft.directory/users/appRoleAssignments/read"
"microsoft.directory/users/assignLicense"
"microsoft.directory/users/basic/update"
"microsoft.directory/users/contactInfo/update"
"microsoft.directory/users/deviceForResourceAccount/read"
"microsoft.directory/users/directReports/read"
"microsoft.directory/users/extensionProperties/update"
"microsoft.directory/users/identities/read"
"microsoft.directory/users/jobInfo/update"
"microsoft.directory/users/licenseDetails/read"
"microsoft.directory/users/manager/read"
"microsoft.directory/users/manager/update"
"microsoft.directory/users/memberOf/read"
"microsoft.directory/users/ownedDevices/read"
"microsoft.directory/users/parentalControls/update"
"microsoft.directory/users/passwordPolicies/update"
"microsoft.directory/users/registeredDevices/read"
"microsoft.directory/users/reprocessLicenseAssignment"
"microsoft.directory/users/reprocessLicenseAssignment"
"microsoft.directory/users/scopedRoleMemberOf/read"
"microsoft.directory/users/sponsors/read"
"microsoft.directory/users/sponsors/update"
"microsoft.directory/users/standard/read"
"microsoft.directory/users/usageLocation/update"
)
```

This array must be used in a hash table. The key name is AllowedResourceActions and the array is the value:

```PowerShell
$rolePermissions = @{
      AllowedResourceActions= $allowedResourceAction
    }
```

>Note: In the future, next to AllowedResourceActions an additional array of task should be able to be used: ExcludedResourceActions. But at the moment of creating this document, Microsoft does not support that setting.

Now the custom role could be created:

```PowerShell
$customAdmin = New-MgRoleManagementDirectoryRoleDefinition -RolePermissions $rolePermissions `
                                                           -DisplayName $displayName `
                                                           -IsEnabled `
                                                           -Description $description `
                                                           -TemplateId $templateId
```

For further changes, note the template ID. Otherwise, use the following command to get all roles and filter for the custom role:

```PowerShell
Get-MgRoleManagementDirectroyRoleDefinition

Get-MgRoleManagementDirectoryRoleDefinition | Where-Object { $_.DisplayName -like 'SC300*' }
```

## Assign a custom role to a user

A custom role could be assigned to users or groups. In short, you need the user or group ID and also the custom role ID.

Use the following cmdlet to get user or group Ids:

```PowerShell
$user = Get-MgUser -Filter "userPrincipalName eq 'sherlock@<yourDomain>'"
# or
$group = Get-MgGroup -Filter "DisplayName eq 'Detectives'"
```

To get the custom role ID use the following command:

```PowerShell
$CustomRole = Get-MgRoleManagementDirectoryRoleDefinition | Where-Object { $_.DisplayName -like 'SC300*' }
# or
$CustomRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "startswith(DisplayName, 'SC300')"
```

Now the assignment:

```PowerShell
$roleAssignment = New-MgRoleManagementDirectoryRoleAssignment -DirectoryScopeId '/' `
                                                              -PrincipalId $user.Id `
                                                              -RoleDefinitionId $CustomRole.Id
```

The result is an UnifiedRoleAssignment object. To work with it go to the next [section](#unassign-a-custom-role).

> Hint: For description how to assign a custom to a principal and Administrative Unit (AU), see the [documentation](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/manage-roles-portal?tabs=ms-powershell#assign-roles-with-administrative-unit-scope).

## Unassign a custom role

As you learned in the previous section, assignments are UnifiedRoleAssignment objects in Entra ID. To unassign a role, you have to delete the find and remove the UnifiedRoleAssignment object.

First, get the user's ID or group's ID for which you have to unassign a role. And also the custom role ID:

```PowerShell
$user = Get-MgUser -Filter "userPrincipalName eq 'sherlock@<yourDomain>'"
# or
$group = Get-MgGroup -Filter "DisplayName eq 'Detectives'"
# and
$CustomRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "startswith(DisplayName, 'SC300')"
```

The following cmdlets will get the correct assignment object:

```PowerShell
$Assignment = Get-mgRoleManagementDirectoryRoleAssignment |
                Where-Object { $_.PrincipalID -eq ($User.Id) -and $_.RoleDefinitionId -eq $CustomRole.Id }
```

Now, remove the Assignment object

```PowerShell
Remove-MgRoleManagementDirectoryRoleAssignment -UnifiedRoleAssignmentId $Assignemnt.Id
```

## Update a custom role

First, you have to find the role definition Id. Use the cmdlet `Get-MgRoleManagementDirectoryRoleDefinition`:

```PowerShell
Get-MgRoleManagementDirectoryRoleDefinition

Get-MgRoleManagementDirectoryRoleDefinition | Where-Object { -not $_.IsBuiltIn }

$customRole = Get-MgRoleManagementDirectoryRoleDefinition | Where-Object { -not $_.IsBuiltIn -and  $_.DisplayName -like 'SC300*' }
```

To change the description use this:

```PowerShell
Update-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $customRole.Id -Description 'This role ...'
```

To change the permissions, create a hash table like in section [Create a custom role](#create-a-custom-role) and use the parameter `-RolePermissions`

```PowerShell
Update-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $customRole.Id -RolePermissions $rolePermissions
```

## Remove a custom role

Also for removing a custom role, get first the Id of the role definition like you did it in the last section [Update a custom role](#update-a-custom-role). Then use the following command:

```PowerShell
Remove-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $customRole.Id
```
