$ErrorActionPreference = 'Stop'

# Path to the custom role definition JSON file
$roleDefinitionPath = ".\CustomRoleDemoAzure_Part1.json"

# Find Subcscription ID
$SubscriptionId = (Get-AzContext).Subscription.Id
if (-not $SubscriptionId) {
    Write-Error "No active Azure subscription found. Please set a subscription context."
    return
}

# Get content of the custom role definition file, replace the placeholder with the actual subscription ID and save it to a temporary file
$roleDefinitionContent = Get-Content -Path $roleDefinitionPath -Raw
$roleDefinitionContent = $roleDefinitionContent -replace '<your-subscription-id>', $SubscriptionId
$tempFile = New-TemporaryFile
Set-Content -Path $tempFile.FullName -Value $roleDefinitionContent

# Create the custom role
try {
    New-AzRoleDefinition -InputFile $tempFile.FullName
}
catch {
    Write-Error "Failed to create custom role: $_"
    # Remove-Item -Path $tempFile.FullName -Force
    return
}

# Clean up the temporary file
Remove-Item -Path $tempFile.FullName -Force

Write-Host "Custom role created successfully."
