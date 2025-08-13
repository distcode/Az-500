
# Set Sync Schedule
$SchedulerInterval = New-TimeSpan -Hours 3
Set-ADSyncScheduler -CustomizedSyncCycleInterval $SchedulerInterval
Set-ADSyncScheduler -SyncCycleEnabled $false
Get-AdSyncScheduler

# Set deleted objects treshold
Get-ADSyncExportDeletionThreshold
Enable-ADSyncExportDeletionThreshold -DeletionThreshold 50

# Disable Entra Connect Sync
## Link1: https://www.alitajran.com/uninstall-azure-ad-connect/
## Link2: https://www.alitajran.com/disable-active-directory-synchronization/

## Install nescesary modules
Install-Module Microsoft.Graph -Force
Install-Module Microsoft.Graph.Beta -AllowClobber -Force

## Connect MG Graph
Connect-MgGraph -Scopes "Organization.ReadWrite.All" # -TenantId '541544f3-4d73-4594-a819-2ac265a75f10'

## Disable Sync
$OrgID = (Get-MgOrganization).Id
$params = @{
    onPremisesSyncEnabled = $false
}

Update-MgOrganization -OrganizationId $OrgID -BodyParameter $params

Get-MgOrganization | Select-Object DisplayName, OnPremisesSyncEnabled

