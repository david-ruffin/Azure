# Get all databases for all Azure subscriptions
# Ensure you have logged in
Login-AzAccount

# Create a list to hold the result
$databasesList = New-Object 'System.Collections.Generic.List[System.Object]'

# Get all subscriptions
$subs = (Get-AzSubscription).Name

foreach ($sub in $subs) {
    # Set the context to the current subscription
    Set-AzContext -SubscriptionName $sub

    # Get databases from all servers in all resource groups for the current subscription
    Get-AzResourceGroup | ForEach-Object {
        Get-AzSqlServer -ResourceGroupName $_.ResourceGroupName | ForEach-Object {
            $serverName = $_.ServerName
            Get-AzSqlDatabase -ResourceGroupName $_.ResourceGroupName -ServerName $serverName | ForEach-Object {
                $databaseObject = [PSCustomObject]@{
                    'DatabaseName'   = $_.DatabaseName
                    'ServerName'     = $serverName
                    'Subscription'   = $sub
                }
                $databasesList.Add($databaseObject) | Out-Null
            }
        }
    }
}

# Display the list
$databasesList | Format-Table
