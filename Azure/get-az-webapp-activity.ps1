# -----------------------------------------------------------------------
# Script Description:
# This PowerShell script retrieves activity logs for all Azure App Services
# (Web Apps) across all subscriptions for the last 90 days. It filters logs 
# to include only user actions (by checking for '@' in the Caller field) and 
# outputs the results to a CSV file.
# -----------------------------------------------------------------------

# Set the time range to retrieve logs from the last 90 days
$startTime = (Get-Date).AddDays(-90)

# Create a filename with timestamp for the output CSV
$outputFile = "AzureAppServiceActivityLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# Create an empty array to store all results
$allResults = @()

# Get all Azure subscriptions that the current user has access to
$subscriptions = Get-AzSubscription

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    $subscriptionName = $subscription.Name
    
    # Set the Azure context to the current subscription
    Set-AzContext -SubscriptionId $subscriptionId

    # Retrieve all App Services (Web Apps) in the current subscription
    $appServices = Get-AzWebApp

    # Loop through each App Service
    foreach ($appService in $appServices) {
        $appServiceId = $appService.Id
        $appServiceName = $appService.Name
        $resourceGroupName = $appService.ResourceGroup

        # Retrieve the activity logs for the App Service
        $logs = Get-AzActivityLog -ResourceId $appServiceId -StartTime $startTime

        # Filter the logs to include only those where the Caller is a user
        $userLogs = $logs | Where-Object { $_.Caller -like "*@*" }

        # If user activity logs are found, add them to the results
        if ($userLogs) {
            $allResults += $userLogs | Select-Object `
                @{Name="Date";Expression={$_.EventTimestamp.ToString("yyyy-MM-dd")}},
                @{Name="Time";Expression={$_.EventTimestamp.ToString("HH:mm:ss")}},
                @{Name="App Service Name";Expression={$appServiceName}},
                @{Name="Resource Group";Expression={$resourceGroupName}},
                @{Name="Subscription Name";Expression={$subscriptionName}},
                @{Name="Caller";Expression={$_.Caller}}
        } else {
            # Add a record indicating no logs were found
            $allResults += [PSCustomObject]@{
                Date = (Get-Date).ToString("yyyy-MM-dd")
                Time = (Get-Date).ToString("HH:mm:ss")
                "App Service Name" = $appServiceName
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
