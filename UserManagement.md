
# User Management with Microsoft Graph PowerShell SDK

Take this as a primer or first steps guide to perform user management with Microsoft Graph PowerShell SDK.

---

Table of Content

+ [Sign In to Microsoft.Graph](#sign-in-to-microsoftgraph)
+ [Create new user](#create-new-user)
+ [Get a user's information](#get-a-users-information)
+ [Filter users](#filter-users)
+ [Get user's details](#get-users-details)
+ [Change user's setting](#change-users-setting)
+ [Delete user](#delete-user)
+ [Restore deleted user](#restore-deleted-user)

---

## Sign In to Microsoft.Graph

```PowerShell
Connect-MgGraph -Scopes 'User.ReadWrite.All'
```

> Hint: If you would use cmdlets just for reading use the scope 'User.Read.All'

For the following cmdlet some variables are use:

```PowerShell
$domain='aztrg.com'
$password = 'ein1000%SichersPasswort'
$passwordSecure = ConvertTo-SecureString -String $password -AsPlainText -Force
```

> Hint: The `*-MgUser*` cmdlets do not need a secure Password.

## Create new user

```PowerShell
$htPasswordprofile = @{
    Password = $password;
    ForceChangePasswordNextSignIn = $false;
    # ForceChangePasswordnextSignInWithMfa=$true --> User must perform Mfa before change password!
}
New-MgUser -DisplayName 'Guido Brunetti' `
           -UserPrincipalName "guido@$domain" `
           -AccountEnabled `
           -MailNickname 'Guido' `
           -Surname 'Brunetti' `
           -GivenName 'Guido' `
           -UsageLocation 'IT' `
           -UserType 'Member' `
           -PasswordProfile $htPasswordprofile
```

## Get a user's information

```PowerShell
Get-MgUser
$curUser = Get-MgUser -Search '"DisplayName:Guido"' -ConsistencyLevel eventual
Get-MgUser -UserId $curUser.Id
Get-MgUser -UserId $curUser.Id | Format-List *
```

## Filter users

```PowerShell
Get-MgUser -Filter "city eq 'Graz'"
Get-MgUser -Filter "startswith(city, 'G')" 
```

> Hint: There are many more operators like endswith, contains, ... see [documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter?tabs=http).

## Get user's details

```PowerShell
$curUser = Get-MgUser -Search '"DisplayName:Guido"' -ConsistencyLevel eventual -Property 'ID,UsageLocation'
$curUser | Format-List *
```

> Hint: Only the properties passed to the '-Property' parameter are actually returned.

```PowerShell
$curUser = Get-MgUser -Search '"DisplayName:Guido"' -ConsistencyLevel eventual -Property 'ID,UsageLocation,DisplayName,MailnickName,UserPrincipalName'
$curUser | Format-List *
```

## Change user's setting

```PowerShell
Update-MgUser -UserId $curUser.Id -City 'Venice'
$curUser = Get-MgUser -UserId $curUser.Id -Property 'ID, City'
```

## Delete user

```PowerShell
Remove-MgUser -UserId $curUser.Id
```

## Restore deleted user

```PowerShell
$curUser = Get-MgDirectoryDeletedItemAsUser -Filter "Displayname eq 'Guido Brunetti'"
Restore-MgDirectoryDeletedItem -DirectoryObjectId $curUser.Id
```
