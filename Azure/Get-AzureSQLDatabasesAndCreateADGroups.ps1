<#
.SYNOPSIS
    Retrieves Azure SQL databases across all subscriptions and creates Azure AD groups for access management.

.DESCRIPTION
    This PowerShell script performs two main tasks:
    1. Retrieves all Azure SQL databases (excluding 'master') from all Azure subscriptions, collecting details such as subscription, resource group, server, database name, location, edition, and max size.
    2. Creates two Azure AD security groups per database for access management:
       - Database-GroupName:<DatabaseName>role:Reader (for db_datareader role)
       - Database-GroupName:<DatabaseName>role:Writer (for db_datawriter role)
    The database list is exported to a CSV file (AzureSQLDatabases.csv) and displayed in the console. Groups are only created if they don’t already exist.

.AUTHOR
    [Your Name]

.DATE
    2025-06-16

.REQUIREMENTS
    - PowerShell modules: Az.Accounts, Az.Sql, Microsoft.Graph
    - Azure permissions to list SQL servers and databases
    - Azure AD permissions to create groups (Group.ReadWrite.All scope)
    - Valid Azure and Microsoft Graph authentication

.OUTPUTS
    - AzureSQLDatabases.csv: CSV file containing details of all Azure SQL databases
    - Console output: List of databases and status of Azure AD group creation

.NOTES
    - Run with an account that has access to Azure subscriptions and Azure AD group management.
    - Ensure modules are installed before execution (uncomment Install-Module lines if needed).
    - The script is designed for one-time use to set up database access groups.
    - Use the created Azure AD groups to assign users and apply database roles (e.g., via SQL scripts).
#>

# Install required modules if needed (uncomment if not installed)
# Install-Module -Name Az.Accounts, Az.Sql, Microsoft.Graph -Force

# Connect to Azure
Connect-AzAccount

# Initialize output array
$databases = @()

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Loop through each subscription
foreach ($sub in $subscriptions) {
    Set-AzContext -Subscription $sub.Id
    $sqlServers = Get-AzSqlServer
    foreach ($server in $sqlServers) {
        $dbs = Get-AzSqlDatabase -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName | 
            Where-Object { $_.DatabaseName -ne 'master' }
        foreach ($db in $dbs) {
            $databases += [PSCustomObject]@{
                Subscription    = $sub.Name
                ResourceGroup   = $server.ResourceGroupName
                ServerName      = $server.ServerName
                DatabaseName    = $db.DatabaseName
                Location        = $db.Location
                Edition         = $db.Edition
                MaxSizeGB       = $db.MaxSizeBytes / 1GB
            }
        }
    }
}

# Export to CSV
$databases | Export-Csv -Path "AzureSQLDatabases.csv" -NoTypeInformation

# Display results
$databases | Format-Table -AutoSize

# Connect to Microsoft Graph with appropriate permissions
Connect-MgGraph -Scopes "Group.ReadWrite.All"

# Loop through each database in the $databases array
foreach ($db in $databases) {
    $dbName = $db.DatabaseName

    # Define group names
    $readerGroupName = "Database-GroupName:$dbName`role:Reader"
    $writerGroupName = "Database-GroupName:$dbName`role:Writer"

    # Create Reader group if it doesn't exist
    if (-not (Get-MgGroup -Filter "displayName eq '$readerGroupName'")) {
        New-MgGroup -DisplayName $readerGroupName `
                    -Description "Reader group for $dbName database" `
                    -MailEnabled:$false `
                    -SecurityEnabled:$true `
                    -MailNickname ($readerGroupName -replace '[^a-zA-Z0-9]', '')
        Write-Output "Created group: $readerGroupName"
    } else {
        Write-Output "Group already exists: $readerGroupName"
    }

    # Create Writer group if it doesn't exist
    if (-not (Get-MgGroup -Filter "displayName eq '$writerGroupName'")) {
        New-MgGroup -DisplayName $writerGroupName `
                    -Description "Writer group for $dbName database" `
                    -MailEnabled:$false `
                    -SecurityEnabled:$true `
                    -MailNickname ($writerGroupName -replace '[^a-zA-Z0-9]', '')
        Write-Output "Created group: $writerGroupName"
    } else {
        Write-Output "Group already exists: $writerGroupName"
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
