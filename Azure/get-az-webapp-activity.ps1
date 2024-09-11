# -----------------------------------------------------------------------
# Script Description:
# This PowerShell script retrieves activity logs for all Azure App Services
# (Web Apps) across all subscriptions for the last 90 days. It filters logs 
# to include only user actions (by checking for '@' in the Caller field) and 
# outputs the results in a readable table format. If no logs are found for a 
# particular App Service, the script provides feedback.
# -----------------------------------------------------------------------

# Set the time range to retrieve logs from the last 90 days
$startTime = (Get-Date).AddDays(-90)  # Set the lookback period to 90 days

# Get all Azure subscriptions that the current user has access to
$subscriptions = Get-AzSubscription  # Retrieves all subscriptions

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id  # Store the subscription ID for context switching
    $subscriptionName = $subscription.Name  # Store the subscription name for output formatting
    
    # Set the Azure context to the current subscription to ensure correct targeting of resources
    Set-AzContext -SubscriptionId $subscriptionId

    # Retrieve all App Services (Web Apps) in the current subscription
    $appServices = Get-AzWebApp  # Fetch all App Services in the subscription

    # Loop through each App Service
    foreach ($appService in $appServices) {
        $appServiceId = $appService.Id  # Get the unique resource ID for the App Service
        $appServiceName = $appService.Name  # Get the name of the App Service
        $resourceGroupName = $appService.ResourceGroup  # Get the resource group name

        # Retrieve the activity logs for the App Service by Resource ID, within the last 90 days
        $logs = Get-AzActivityLog -ResourceId $appServiceId -StartTime $startTime

        # Filter the logs to include only those where the Caller is a user (denoted by '@' in the Caller)
        $userLogs = $logs | Where-Object { $_.Caller -like "*@*" }  # Check if Caller contains '@'

        # If user activity logs are found, format them for output
        if ($userLogs) {
            $userLogs | Select-Object `
                @{Name="Date";Expression={$_.EventTimestamp.ToString("yyyy-MM-dd")}},  # Format the date
                @{Name="Time";Expression={$_.EventTimestamp.ToString("HH:mm:ss")}},    # Format the time
                @{Name="App Service Name";Expression={$appServiceName}},  # Show the App Service name
                @{Name="Resource Group";Expression={$resourceGroupName}},  # Show the resource group name
                @{Name="Subscription Name";Expression={$subscriptionName}},  # Show the subscription name
                @{Name="Caller";Expression={$_.Caller}}  # Show the user who performed the action
            | Format-Table -AutoSize  # Format the output into a table with automatic column sizing
        } else {
            # Output a message if no user activity logs are found for the App Service
            Write-Output "No user activity logs for App Service: $appServiceName in Subscription: $subscriptionName"
        }
    }
}
