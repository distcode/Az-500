# Manage and use Service Principals (SP)

This guide shows how to create and manage Service Principals (SP) in Entra ID with Microsoft PowerShell. The second section demonstrates how to sign in to an Azure subscription using a SP.

---

+ [Manage a SP](#manage-a-sp)
  + [Preparation](#preparation)
  + [Create a SP](#create-a-sp)
  + [Get a SP](#get-a-sp)
  + [Update a SP](#update-a-sp)
  + [Add a secret](#add-a-secret)
  + [Add a certificate](#add-a-certificate)
  + [Remove a SP](#remove-a-sp)
+ [Sign in with a SP](#sign-in-with-a-sp)
  + [Sign in using a certificate](#sign-in-using-a-certificate)
  + [Sign in using a secret](#sign-in-using-a-secret)

---

## Manage a SP

### Preparation

To use the following cmdlets and script fragments, install the `Microsoft.Graph` modules form PowerShell Gallery:

```PowerShell
Install-PSResource Microsoft.Graph

# in case of working with old version of PowerShellGet
Install-Module Microsoft.Graph
```

For managing a SP you must be assigned at least the `Application Administrator` or `Cloud Application Administrator` role. To use these roles in Microsoft Graph PS SDK connect by the following:

```PowerShell
Connect-MgGraph -Scopes Application.ReadWrite.All 
```

### Create a SP

To create a new SP in PowerShell, you have to create first an application object:

```PowerShell
$App = New-MgApplication -DisplayName 'Sc3-Demo-AppSP'
```

>Note: The Application ID is already created and must be used in the next command.

At this point, you could find in the Entra ID portal under `Application registration` already an entry, ==but not in _Enterprise applications_==.

Then, create a SP an associate it to the application:

```PowerShell
$SP = New-MgServicePrincipal -AppId $App.AppId -DisplayName 'Sc3-Demo-AppSP' 
```

>Hint: The SP cannot created without an application object and the DisplayName of a SP must be the same as the one of the application!

Now, you will find an entry of `Sc3-Demo-AppSP` also in `Enterprise registration` list.

### Get a SP

To get a SP use one of the following commands:

```PowerShell
Get-MgServicePrincipal
Get-MgServiceprincipal -Filter "DisplayName eq 'SC3-Demo-AppSP'"
Get-MgServicePrincipal -Filter "startswith(Displayname, 'SC3')"
```

### Update a SP

First, find and save the ID of your SP you would like to change:

```PowerShell
$SP = Get-MgServicePrincipal -Filter "DisplayName eq 'SC3-Demo-AppSP'"
```

Then use the cmdlet to update any property:

```PowerShell
Update-MgServicePrincipal -ServicePrincipalId $SP.Id -Description 'Just for demonstration ...'
```

To check the last command:

```PowerShell
(Get-MgServicePrincipal -Filter "DisplayName eq 'SC3-Demo-App'").description
```

### Add a secret

To use a secret for signing in with an SP, you have to add a secret to the application object, therefor save the application object and not the service principal in a variable:

```PowerShell
$App = Get-MgApplication -Filter "DisplayName eq 'Sc3-Demo-AppSP'"
```

Now, create a variable of type `MicrosoftGraphPasswordCredential` and set the properties.

```PowerShell
$pwdcred = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordCredential
$pwdcred.DisplayName = 'SecretX'
$pwdcred.EndDateTime = (Get-Date).AddDays(180)
$pwdcred.StartDateTime = (Get-Date)
```

Alternatively you could use also a hash table.

```PowerShell
$pwdcred = @{
    DisplayName = "SecretX"
    EndDateTime = (Get-Date).AddDays(180)
    StartDateTime = (Get-Date)
}
```

The command adds the new password to your application. Be careful, the result of the command is an object of type `MicrosoftGraphPasswordCredential` and contains the created password. It is recommended to save that result in a variable. Only here, you can see the password for later use. Save it where you could reuse it in future.

```PowerShell
$result = Add-MgApplicationPassword -ApplicationId $App.Id -PasswordCredential $pwdcred

$result
$result.SecretText
```

To check the configuration:

```PowerShell
(Get-MgApplication -ApplicationId $app.Id).PasswordCredentials
```

### Add a certificate

To add a the possibility to sign in by a certificate instead of a secret, add a certificate () to the application object. Again, save it in variable:

```PowerShell
$App = Get-MgApplication -Filter "DisplayName eq 'Sc3-Demo-AppSP'"
```

For demonstration reasons a self-signed certificate will be used. Of course, a client certificate issued by your certification authority could also used.

```PowerShell
$CertParam = @{
    'KeyAlgorithm'      = 'RSA'
    'KeyLength'         = 2048
    'KeyExportPolicy'   = 'Exportable'
    'DnsName'           = 'server.dist.at'
    'FriendlyName'      = 'SP Sign In Certificate'
    'CertStoreLocation' = 'Cert:\LocalMachine\My\'
    'NotAfter'          = (Get-Date).AddYears(1)
}
$Cert = New-SelfSignedCertificate @CertParam
```

Export the public key into a _*.cer_ file. If necessary to use the same public/private key pair on other systems, export public and private key into a _*.pfx_ file (`Export-PfxCertificate`) and import it there.

```PowerShell
Export-Certificate -Cert $Cert -FilePath $Home\Documents\AutomationApp.cer
```

Mention that the thumbprint of your created certificate is used for later sign in.

Now upload the public key to Entra ID to your application object. Prepare a `MicrosoftGraphKeyCredential` object and set the properties accordingly:

```PowerShell
$certPath = "$home\documents\AutomationApp.cer"
$certBytes = [System.IO.File]::ReadAllBytes($certPath)
$base64Cert = [System.Convert]::ToBase64String($certBytes)
$base64ByteArray = [System.Convert]::FromBase64String($base64Cert)

$keyCredential = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphKeyCredential
$keyCredential.Type = "AsymmetricX509Cert"
$keyCredential.Usage = "Verify"
$keyCredential.Key = $base64ByteArray
$keyCredential.DisplayName = "Certificate01"
$keyCredential.StartDateTime = Get-Date
$keyCredential.EndDateTime = (Get-Date).AddYears(1).Date.ToUniversalTime() # avoid setting time
```

If you not have configured a certificate for your application use the cmdlet `Update-MgApplication`:

```PowerShell
Update-MgApplication -ApplicationId $App.Id -KeyCredentials $keyCredential
```

Would you like to add another certificate use the cmdlet `Add-MgApplicationKey`:

```PowerShell
Add-MgApplicationKey -ApplicationId $App.Id -KeyCredential $keyCredential
```

To check the configuration:

```PowerShell
(Get-MgApplication -ApplicationId $app.Id).KeyCredentials
```

### Remove a SP

Quite easy:

```PowerShell
$SP = Get-MgServicePrincipal -Filter "DisplayName eq 'SC3-Demo-AppSP'"

Remove-MgServicePrincipal -ServicePrincipalId $SP.Id
```

>Note: The last command removes only the SP but not the application object.

To remove the application object:

```PowerShell
$App = Get-MgApplication -Filter "Displayname eq 'Sc3-Demo-AppSP'"

Remove-MgApplication -ApplicationId $App.Id
```

## Sign in with a SP

### Sign in using a certificate

To use a certificate to sign in with a SP, use the following command:

```PowerShell
$TenandID = '<yourTenantID>'
$AppID = '<yourAppID>'
$Thumbprint = '<yourThumbprint>'

Connect-AzAccount -ServicePrincipal -Tenant $TenantID -ApplicationId $AppID -CertificateThumbprint $Thumbprint
```

### Sign in using a secret

To use a secret to sign in with a SP, use the following command:

```PowerShell
$TenandID = '<yourTenantID>'
$AppID = '<yourAppID>'
$Secret = '<yourSecret>'
$SPCred = New-Object -TypeName pscredential -ArgumentList $AppID,(ConvertTo-SecureString -String $Secret -AsPlainText -Force)

Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $SPCred
```
