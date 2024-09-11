# -----------------------------------------------------------------------
# Script Description:
# This PowerShell script retrieves activity logs for all virtual machines (VMs) 
# across all subscriptions within the last 90 days. It filters for logs where 
# the caller is a user account (indicated by an '@' symbol in the Caller field), 
# and outputs the results in a readable table format. If no logs are found, 
# it notifies the user for each VM.
# -----------------------------------------------------------------------

# Set the time range to retrieve logs from the last 90 days
$startTime = (Get-Date).AddDays(-90)  # This sets the lookback period to 90 days

# Get all Azure subscriptions that the current user has access to
$subscriptions = Get-AzSubscription  # Retrieves the list of subscriptions

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id  # Store the subscription ID
    $subscriptionName = $subscription.Name  # Store the subscription name for reporting
    
    # Set the Azure context to the current subscription (ensures commands target the correct subscription)
    Set-AzContext -SubscriptionId $subscriptionId

    # Retrieve all virtual machines (VMs) in the current subscription
    $vms = Get-AzVM  # Fetches all VMs in the subscription

    # Loop through each VM in the subscription
    foreach ($vm in $vms) {
        $vmId = $vm.Id  # Get the unique resource ID for the VM
        $vmName = $vm.Name  # Get the name of the VM
        $resourceGroupName = $vm.ResourceGroupName  # Get the resource group containing the VM

        # Retrieve the activity logs for the VM by its Resource ID within the last 90 days
        $logs = Get-AzActivityLog -ResourceId $vmId -StartTime $startTime

        # Filter the logs to include only those where the Caller is a user (not a system/service account)
        $userLogs = $logs | Where-Object { $_.Caller -like "*@*" }  # Checks for '@' in the Caller field

        # If user activity logs are found, output them in a readable table format
        if ($userLogs) {
            $userLogs | Select-Object `
                @{Name="Date";Expression={$_.EventTimestamp.ToString("yyyy-MM-dd")}},  # Format the date
                @{Name="Time";Expression={$_.EventTimestamp.ToString("HH:mm:ss")}},    # Format the time
                @{Name="Resource Name";Expression={$vmName}},  # Display the VM name
                @{Name="Resource Group";Expression={$resourceGroupName}},  # Display the resource group name
                @{Name="Subscription Name";Expression={$subscriptionName}},  # Display the subscription name
                @{Name="Caller";Expression={$_.Caller}}  # Display the user who performed the action
            | Format-Table -AutoSize  # Format the output into a table with automatic column sizing
        } 
        else {
            # Output a message if no user activity logs are found for the VM
            Write-Output "No user activity logs for VM: $vmName in Subscription: $subscriptionName"
        }
    }
}
