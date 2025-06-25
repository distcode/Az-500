
# Group Management with Microsoft Graph PowerShell SDK

This document shows you how to perform group management with Microsoft Graph PowerShell SDK.

---

Table of Content

+ [Sign In to Microsoft.Graph](#sign-in-to-microsoftgraph)
+ [Create a new Group](#create-a-new-group)
+ [Get groups / group](#get-groups--group)
+ [Add member(s) to groups](#add-members-to-groups)
+ [Remove member(s) from group(s)](#remove-members-from-groups)

---

## Sign In to Microsoft.Graph

For group management cmdlet the scope 'Group.ReadWrite.All' is needed. Also the 'User.ReadWrite.All' so you can read and change user attributes as well.

```PowerShell
Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Group.ReadWrite.All'
```

## Create a new Group

To create a new group use the cmdlet `New-MgGroup`. Use the parameter `-SecurityEnabled` to create a security group, `-MailEnabled:$false` to create a group without a mail address (not mail enabled security group).

```PowerShell
New-MgGroup `
    -MailNickname 'mgDetectives' `
    -DisplayName 'mgDetectives' `
    -SecurityEnabled `
    -MailEnabled:$false
```

## Get groups / group

```PowerShell
Get-MgGroup
$myGroup = Get-MgGroup -Search 'displayName:mgDetectives' -ConsistencyLevel eventual
$myGroup = Get-MgGroup -GroupId $myGroup.Id
$myGroup | Format-List -Property *
```

## Add member(s) to groups

Instead of using Add-MgGroupMember use the cmdlet `New-MgGroupMember`. Use the parameter `-DirectoryObjectId` to indicate the object you would like to add to the group.

```PowerShell
$myUser = Get-MgUser -Search '"Displayname:Guido"' -ConsistencyLevel eventual
New-MgGroupMember -GroupId $myGroup.Id -DirectoryObjectId $myUser.Id
Get-MgGroupMember -GroupId $myGroup.Id
Get-MgGroupMember -GroupId $myGroup.Id | ForEach-Object { Get-MgUser -UserId $PSItem.Id }
```

## Remove member(s) from group(s)

```PowerShell
$myUser = Get-MgUser -Search '"Displayname:Guido"' -ConsistencyLevel eventual
Remove-MgGroupMemberByRef -GroupId $myGroup.Id -DirectoryObjectId $myUser.Id
```
