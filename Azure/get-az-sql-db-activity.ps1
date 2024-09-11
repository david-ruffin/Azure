# -----------------------------------------------------------------------
# Script Description:
# This PowerShell script retrieves activity logs for all Azure SQL Databases
# across all subscriptions for the last 90 days. It filters logs to include 
# only user actions (indicated by '@' in the Caller field) and outputs the 
# results in a readable table format. If no logs are found for a particular 
# SQL Database, the script provides feedback.
# -----------------------------------------------------------------------

# Set the time range to retrieve logs from the last 90 days
$startTime = (Get-Date).AddDays(-90)  # Sets the lookback period to 90 days

# Get all Azure subscriptions that the current user has access to
$subscriptions = Get-AzSubscription  # Retrieves all subscriptions for the current user

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id  # Store the subscription ID for context switching
    $subscriptionName = $subscription.Name  # Store the subscription name for output formatting
    
    # Set the Azure context to the current subscription to ensure correct targeting of resources
    Set-AzContext -SubscriptionId $subscriptionId

    # Retrieve all SQL Servers in the current subscription
    $sqlServers = Get-AzSqlServer  # Fetch all SQL Servers in the subscription

    # Loop through each SQL Server
    foreach ($sqlServer in $sqlServers) {
        $serverName = $sqlServer.ServerName  # Get the server name
        $resourceGroupName = $sqlServer.ResourceGroupName  # Get the resource group for the SQL Server
        
        # Get all SQL Databases in the current SQL Server
        $sqlDatabases = Get-AzSqlDatabase -ServerName $serverName -ResourceGroupName $resourceGroupName  # Retrieve all SQL databases on the server
        
        # Loop through each SQL Database
        foreach ($sqlDatabase in $sqlDatabases) {
            $dbResourceId = $sqlDatabase.ResourceId  # Get the unique Resource ID for the SQL Database
            $dbName = $sqlDatabase.DatabaseName  # Store the SQL database name

            # Retrieve the activity logs for the SQL Database by its Resource ID within the last 90 days
            $logs = Get-AzActivityLog -ResourceId $dbResourceId -StartTime $startTime

            # Filter the logs to include only those where the Caller is a user (denoted by '@' in the Caller field)
            $userLogs = $logs | Where-Object { $_.Caller -like "*@*" }  # Filter user-triggered actions

            # If user activity logs are found, format them for output
            if ($userLogs) {
                $userLogs | Select-Object `
                    @{Name="Date";Expression={$_.EventTimestamp.ToString("yyyy-MM-dd")}},  # Format the date
                    @{Name="Time";Expression={$_.EventTimestamp.ToString("HH:mm:ss")}},    # Format the time
                    @{Name="Database Name";Expression={$dbName}},  # Show the SQL Database name
                    @{Name="Resource Group";Expression={$resourceGroupName}},  # Show the resource group
                    @{Name="Subscription Name";Expression={$subscriptionName}},  # Show the subscription name
                    @{Name="Caller";Expression={$_.Caller}}  # Show the user who performed the action
                | Format-Table -AutoSize  # Format the output into a table with automatic column sizing
            } else {
                # Output a message if no user activity logs are found for the SQL Database
                Write-Output "No user activity logs for SQL Database: $dbName in Subscription: $subscriptionName"
            }
        }
    }
}
