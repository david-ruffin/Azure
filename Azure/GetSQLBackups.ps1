connect-azaccount

# Variables
$serverName = "<YourServerName>.database.windows.net" # Update with your server name
$databaseName = "<YourDatabaseName>" # Update with your database name
$userId = "<YourUserId>" # Update with your SQL Server username
$password = "<YourPassword>" # Update with your SQL Server password
$query = @"
SELECT TOP 1 *, 
       backup_finish_date AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS backup_finish_date_pst 
FROM sys.dm_database_backups 
ORDER BY backup_finish_date DESC
"@

# Connection string for SQL Server authentication
$connectionString = "Server=tcp:$serverName;Database=$databaseName;User ID=$userId;Password=$password;"

# Execute the query
((Invoke-Sqlcmd -ConnectionString $connectionString -Query $query).backup_finish_date_pst).DateTime 
