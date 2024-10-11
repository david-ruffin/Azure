# Set variables
$vmName = "FdhDefenseAftermarket-Dev"
$vmResourceGroup = "FdhDefense"

# Get today's date in MM-DD-YYYY format
$datePrefix = Get-Date -Format "MM-dd-yyyy"

# Get the VM
$vm = Get-AzVM -Name $vmName -ResourceGroupName $vmResourceGroup

if ($null -eq $vm) {
    Write-Error "VM not found"
    exit
}

# Get the backup status of the VM
$backupStatus = Get-AzRecoveryServicesBackupStatus -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Type AzureVM
if ($backupStatus.BackedUp -eq $false) {
    Write-Error "No backup found for this VM"
    exit
}

# Get the vault where the VM is backed up
$vault = Get-AzRecoveryServicesVault -ResourceGroupName (Get-AzResource -ResourceId $backupStatus.VaultId).ResourceGroupName

# Set the vault context
Set-AzRecoveryServicesVaultContext -Vault $vault

# Get the backup item for the VM
$backupItem = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -Name $vm.Name

# Display backup info
Write-Output "Backup Info for VM: $vmName"
Write-Output "Vault Name: $($vault.Name)"
Write-Output "Policy Name: $($backupItem.ProtectionPolicyName)"
Write-Output "Last Backup Status: $($backupItem.LastBackupStatus)"
Write-Output "Last Backup Time: $($backupItem.LastBackupTime)"

# Create a custom backup name with today's date
$backupName = "$datePrefix-$vmName-Backup"

# Trigger a new backup
$job = Backup-AzRecoveryServicesBackupItem -Item $backupItem -BackupType Full

Write-Output "Initiated backup with reference name: $backupName"

# Monitor the job status
do {
    $job = Get-AzRecoveryServicesBackupJob -JobId $job.JobId
    Write-Output "Backup status: $($job.Status)"
    Start-Sleep -Seconds 30
} while ($job.Status -notin "Completed", "Failed", "CompletedWithWarnings")

if ($job.Status -eq "Completed") {
    Write-Output "Backup completed successfully"
} else {
    Write-Output "Backup ended with status: $($job.Status)"
}
