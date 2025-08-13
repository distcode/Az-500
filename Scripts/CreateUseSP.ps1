# Preparation
$domain = 'company.com'
$tenantID = 'any valid tenant id'
$password = ConvertTo-SecureString -String 'anyusefulpwd' -AsPlainText -Force



# Create Service Principal and save Certificate
$ssc = New-SelfSignedCertificate -DnsName $domain `
                                 -CertStoreLocation "cert:\currentuser\my" `
                                 -KeyExportPolicy Exportable `
                                 -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
                                 -FriendlyName 'AAD Service Principal' `
                                 -NotAfter (Get-Date).AddYears(3)

Export-PfxCertificate -cert $ssc -FilePath c:\spncert.pfx -Password $password
Export-Certificate -Type CERT -FilePath c:\spncert.cer -Cert $ssc

$sscRawBase64 = [System.Convert]::ToBase64String($ssc.RawData)
New-AzADServicePrincipal -DisplayName 'demoSP' -CertValue $sscRawBase64

Get-AzAdServicePrincipal
$spn = Get-AzAdServicePrincipal -Displayname 'demoSP'
$spn

############################################################################################################

# Use Service Principal
Connect-AzAccount -Serviceprincipal `
                  -ApplicationID $spn.ApplicationId `
                  -TenantID $tenantID `
                  -CertificateThumbprint $ssc.Thumbprint
