# List of VMs with their resource groups
$vmList = "vm1", "vm2"


# CSV output file path
$outputFile = "VM_Backup_Status.csv"

# Create a list to store results
$results = @()

# Get all Azure subscriptions
$subscriptions = Get-AzSubscription

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    Write-Host "Checking subscription: $($subscription.Name)" -ForegroundColor Cyan
    Set-AzContext -Subscription $subscription.Id

    # Get all VMs in the current subscription
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        # Check if the VM is in the list of VMs you are tracking
        if ($vmList -contains $vm.Name) {
            $vmName = $vm.Name
            $resourceGroupName = $vm.ResourceGroupName

            Write-Host "Checking backup status for VM: $vmName in subscription: $($subscription.Name)"

            # Get the backup status of the VM
            $backupStatus = Get-AzRecoveryServicesBackupStatus -Name $vmName -ResourceGroupName $resourceGroupName -Type AzureVM
            if ($backupStatus.BackedUp -eq $false) {
                Write-Host "No backup found for VM: $vmName" -ForegroundColor Red
                # Add the result to the list
                $results += [PSCustomObject]@{
                    Subscription     = $subscription.Name
                    VMName           = $vmName
                    ResourceGroup    = $resourceGroupName
                    VaultName        = "N/A"
                    BackupStatus     = "Not Backed Up"
                    LastBackupTime   = "N/A"
                    PolicyName       = "N/A"
                }
                continue
            }

            # Get the vault where the VM is backed up
            $vault = Get-AzRecoveryServicesVault -ResourceGroupName (Get-AzResource -ResourceId $backupStatus.VaultId).ResourceGroupName

            # Set the vault context
            Set-AzRecoveryServicesVaultContext -Vault $vault

            # Get the backup item for the VM
            $backupItem = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -Name $vmName

            # Add the result to the list
            $results += [PSCustomObject]@{
                Subscription     = $subscription.Name
                VMName           = $vmName
                ResourceGroup    = $resourceGroupName
                VaultName        = $vault.Name
                BackupStatus     = "Backed Up"
                LastBackupTime   = $backupItem.LastBackupTime
                PolicyName       = $backupItem.ProtectionPolicyName
            }
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputFile -NoTypeInformation -Force

Write-Host "Backup status report has been exported to $outputFile"
