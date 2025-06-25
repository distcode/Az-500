# License Management with Microsoft Graph PowerShell SDK

This document shows you how to assign und unassign licenses to users and groups with Microsoft Graph PowerShell SDK.

---

Table of Content

+ [Sign in to Entra ID](#sign-in-to-entra-id)
+ [Set Usage Location](#set-usage-location)
+ [Get License SKUs](#get-license-skus)
+ [Assign licenses](#assign-licenses)
+ [Assign Licenses with options](#assign-licenses-with-options)
+ [Get information of assigned licenses](#get-information-of-assigned-licenses)
+ [Remove a license](#remove-a-license)

---

## Sign in to Entra ID

To assign licenses the scopes User.ReadWrite.All and Organization.Read.All are required.

```PowerShell
Connect-MgGraph -Scopes User.ReadWrite.All, Organization.Read.All
```

## Set Usage Location

The usage location is mandatory for assigning licenses.

```PowerShell
$curUser = Get-MgUser -Filter "givenname eq 'guido'" -Property 'ID, UsageLocation'
Update-MgUser -UserId $curUser.Id -UsageLocation IT
```

## Get License SKUs

Next, the License SKU and their ID must be determined. The ID will be used for the assignment cmdlet. The first line shows you all your purchases licenses in your tenant. The second line shows you the licenses and the amount of paid and consumed licenses. In the last line the Microsoft 365 E5 subscription is saved in a variable for later use.

```PowerShell
Get-MgSubscribedSku | Format-Table SkuPartNumber,ServicePlans
Get-MgSubscribedSku | Format-Table SkuPartNumber,ConsumedUnits,@{Label='PaidUnits';E={$_.prepaidunits.enabled}}
$licSKU = Get-MgSubscribedSku | Where-Object {
    $PSItem.SkuPartNumber -eq 'Microsoft_365_E5_(no_Teams)'
}
```

## Assign licenses

To assign a license use Set-MgUserLicense as follows. This examples would assign a license with all service plans.

```PowerShell
Set-MgUserLicense -UserId $curUser.Id -AddLicenses @{SkuId = $licSKU.SkuId} -RemoveLicenses @()
```

## Assign Licenses with options

If not all service plans or options of a license are needed an array of disabled services plan should be created. The items in the array must be objects of type _Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePlanInfo_.

In the second line a new license object is created as hashtable. The keys _SkuId_ and _DisabledPlans_ are part of it. This new object is then assigned to the user.

```PowerShell
$disabledServices = $licSKU.ServicePlans | Where-Object { $_.ServicePlanName -like 'VIVA*' }
$lic = @{ SkuId = $licSKU.SkuId; DisabledPlans = $disabledServices }
Set-MgUserLicense -UserId $curUser.Id -AddLicenses $lic -RemoveLicenses @()
```

## Get information of assigned licenses

```PowerShell
$curUser = Get-MgUser -Filter "givenname eq 'guido'" -Property 'ID, UsageLocation, UserPrincipalName'
Get-MgUserLicenseDetail -UserId $curUser.Id
```

## Remove a license

To unassign a license from an user, use the parameter -RemoveLicenses of the cmdlet Set-MguserLicense. The parameter value is an array of SkuIds.

```PowerShell
Set-MgUserLicense -UserId $curUser.Id -RemoveLicenses @($licSKU.SkuId) -AddLicenses @()
```
