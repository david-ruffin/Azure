# -----------------------------------------------------------------------
# Script Description:
# This PowerShell script retrieves activity logs for all Azure SQL Databases
# across all subscriptions for the last 90 days. It filters logs to include 
# only user actions (indicated by '@' in the Caller field) and outputs the 
# results to a CSV file, listing both database and server names separately.
# -----------------------------------------------------------------------

# Set the time range to retrieve logs from the last 90 days
$startTime = (Get-Date).AddDays(-90)

# Create a filename with timestamp for the output CSV
$outputFile = "AzureSQLActivityLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

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

    # Retrieve all SQL Servers in the current subscription
    $sqlServers = Get-AzSqlServer

    # Loop through each SQL Server
    foreach ($sqlServer in $sqlServers) {
        $serverName = $sqlServer.ServerName
        $resourceGroupName = $sqlServer.ResourceGroupName
        
        # Get all SQL Databases in the current SQL Server
        $sqlDatabases = Get-AzSqlDatabase -ServerName $serverName -ResourceGroupName $resourceGroupName
        
        # Loop through each SQL Database
        foreach ($sqlDatabase in $sqlDatabases) {
            $dbResourceId = $sqlDatabase.ResourceId
            $dbName = $sqlDatabase.DatabaseName

            # Retrieve the activity logs for the SQL Database
            $logs = Get-AzActivityLog -ResourceId $dbResourceId -StartTime $startTime

            # Filter the logs to include only those where the Caller is a user
            $userLogs = $logs | Where-Object { $_.Caller -like "*@*" }

            # If user activity logs are found, add them to the results
            if ($userLogs) {
                $allResults += $userLogs | Select-Object `
                    @{Name="Date";Expression={$_.EventTimestamp.ToString("yyyy-MM-dd")}},
                    @{Name="Time";Expression={$_.EventTimestamp.ToString("HH:mm:ss")}},
                    @{Name="Server Name";Expression={$serverName}},
                    @{Name="Database Name";Expression={$dbName}},
                    @{Name="Resource Group";Expression={$resourceGroupName}},
                    @{Name="Subscription Name";Expression={$subscriptionName}},
                    @{Name="Caller";Expression={$_.Caller}}
            } else {
                # Add a record indicating no logs were found
                $allResults += [PSCustomObject]@{
                    Date = (Get-Date).ToString("yyyy-MM-dd")
                    Time = (Get-Date).ToString("HH:mm:ss")
                    "Server Name" = $serverName
                    "Database Name" = $dbName
                    "Resource Group" = $resourceGroupName
                    "Subscription Name" = $subscriptionName
                    Caller = "No user activity logs"
                }
            }
        }
    }
}

# Export all results to CSV file
$allResults | Export-Csv -Path $outputFile -NoTypeInformation

Write-Output "Results have been exported to $outputFile"
