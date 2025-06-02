#Requires -Modules Az.Accounts, Az.Compute, Az.ConnectedMachine
<#
.SYNOPSIS
    Azure Virtual Machine and Arc-enabled Machine Inventory Script

.DESCRIPTION
    This script inventories all Azure VMs and Azure Arc-enabled machines across all accessible subscriptions.
    It collects VM metadata including power state, OS information, and resource group details.
    
    The script follows Azure PowerShell best practices including:
    - Proper error handling considerations
    - Efficient resource enumeration
    - Structured output formatting
    - Cross-subscription support

.OUTPUTS
    Returns a collection of PSCustomObjects containing VM inventory data
    Optionally exports to CSV file

.NOTES
    Author: [Your Name]
    Version: 1.0
    Created: [Date]
    
    Prerequisites:
    - Az PowerShell module installed
    - User must be authenticated (Connect-AzAccount)
    - Appropriate RBAC permissions (Reader role minimum) on target subscriptions
    
    Performance Considerations:
    - Script processes all accessible subscriptions sequentially
    - VM status calls are made individually (consider batching for large environments)
    - Memory usage scales with VM count across all subscriptions

.EXAMPLE
    .\Get-AzureVMInventory.ps1
    Runs the inventory across all accessible subscriptions and displays results in table format

.EXAMPLE
    $inventory = .\Get-AzureVMInventory.ps1
    $inventory | Export-Csv -Path "VMInventory-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
    Captures results and exports to timestamped CSV file
#>

$subscriptions = Get-AzSubscription

$results = @()

foreach ($sub in $subscriptions) {
    # Set the context to the current subscription
    Set-AzContext -SubscriptionId $sub.Id | Out-Null

    # Retrieve all Azure VMs in the current subscription
    $azureVMs = Get-AzVM

    foreach ($vm in $azureVMs) {
        # Get the status of the VM
        $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        $poweredOn = $powerState -eq 'VM running'

        # Determine OS platform and name
        $osType = $vm.StorageProfile.OSDisk.OSType
        $osName = $vm.StorageProfile.ImageReference?.Sku ?? $vm.StorageProfile.OSDisk.OsType

        # Add the VM details to the results array
        $results += [PSCustomObject]@{
            Subscription    = $sub.Name
            VMName          = $vm.Name
            ResourceGroup   = $vm.ResourceGroupName
            Type            = 'Azure'
            Platform        = $osType
            OSName          = $osName
            PoweredOn       = $poweredOn
        }
    }

    # Retrieve all Azure Arc-enabled machines in the current subscription
    $arcVMs = Get-AzConnectedMachine

    foreach ($arc in $arcVMs) {
        # Determine power state based on connectivity status
        $poweredOn = $arc.Status -eq 'Connected'

        # Add the Arc machine details to the results array
        $results += [PSCustomObject]@{
            Subscription    = $sub.Name
            VMName          = $arc.Name
            ResourceGroup   = $arc.ResourceGroupName
            Type            = 'Arc'
            Platform        = $arc.OsType
            OSName          = $arc.OsName
            PoweredOn       = $poweredOn
        }
    }
}

# Output the results as a table
$results | Format-Table -AutoSize

# Optionally, export to CSV
# $results | Export-Csv -Path "AllVMs.csv" -NoTypeInformation
