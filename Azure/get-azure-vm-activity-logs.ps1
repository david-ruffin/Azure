# -----------------------------------------------------------------------
# Script Description:
# This PowerShell script retrieves activity logs for all virtual machines (VMs) 
# across all subscriptions within the last 90 days. It filters for logs where 
# the caller is a user account (indicated by an '@' symbol in the Caller field), 
# and outputs the results in a readable table format. If no logs are found, 
# it notifies the user for each VM.
# -----------------------------------------------------------------------

# Set the time range to retrieve logs from the last 90 days
$startTime = (Get-Date).AddDays(-90)  # Set to the last 90 days
$outputFile = "AzureVMActivityLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Create an empty array to store all results
$allResults = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    $subscriptionName = $subscription.Name
    
    # Set the context to the current subscription
    Set-AzContext -SubscriptionId $subscriptionId

    # Get all VMs in the current subscription
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        $vmId = $vm.Id
        $vmName = $vm.Name
        $resourceGroupName = $vm.ResourceGroupName

        # Get activity log for the VM by ResourceId
        $logs = Get-AzActivityLog -ResourceId $vmId -StartTime $startTime

        # Filter for user accounts only (those with '@' in the caller)
        $userLogs = $logs | Where-Object { $_.Caller -like "*@*" }

        # Add results to the array
        if ($userLogs) {
            $allResults += $userLogs | Select-Object `
                @{Name="Date";Expression={$_.EventTimestamp.ToString("yyyy-MM-dd")}},
                @{Name="Time";Expression={$_.EventTimestamp.ToString("HH:mm:ss")}},
                @{Name="Resource Name";Expression={$vmName}},
                @{Name="Resource Group";Expression={$resourceGroupName}},
                @{Name="Subscription Name";Expression={$subscriptionName}},
                @{Name="Caller";Expression={$_.Caller}}
        } else {
            $allResults += [PSCustomObject]@{
                Date = (Get-Date).ToString("yyyy-MM-dd")
                Time = (Get-Date).ToString("HH:mm:ss")
                "Resource Name" = $vmName
                "Resource Group" = $resourceGroupName
                "Subscription Name" = $subscriptionName
                Caller = "No user activity logs"
            }
        }
    }
}

# Export all results to CSV file
$allResults | Export-Csv -Path $outputFile -NoTypeInformation

Write-Output "Results have been exported to $outputFile"
