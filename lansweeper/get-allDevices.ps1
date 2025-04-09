# Lansweeper Database Query PowerShell Script
# Parameters - modify these to match your environment
$sqlServer = "CA-COE-LANSWPR\SQLEXPRESS" 
$databaseName = "lansweeperdb" 
$outputFile = "C:\temp\LansweeperDevices.csv" 

# SQL Query to run - no TOP or row limit
$sqlQuery = @"
SELECT 
    tblAssets.AssetName,
    tblAssets.UserDomain,
    tblAssets.Username,
    tblAssetCustom.Manufacturer,
    tblAssetCustom.Model,
    tsysAssetTypes.AssetTypename AS Type,
    tblAssets.IPAddress,
    tsysIPLocations.IPLocation
FROM 
    tblAssets
LEFT JOIN 
    tblAssetCustom ON tblAssets.AssetID = tblAssetCustom.AssetID
LEFT JOIN
    tsysAssetTypes ON tsysAssetTypes.AssetType = tblAssets.Assettype
LEFT JOIN
    tsysIPLocations ON tblAssets.IPNumeric >= tsysIPLocations.StartIP 
    AND tblAssets.IPNumeric <= tsysIPLocations.EndIP
WHERE 
    tblAssets.AssetID IS NOT NULL
ORDER BY 
    tblAssets.AssetName
"@

# Load SQL Server module
try {
    Import-Module SqlServer -ErrorAction Stop
} 
catch {
    Write-Host "SqlServer module not found. Installing..."
    try {
        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
        Import-Module SqlServer
    } 
    catch {
        Write-Error "Failed to install SqlServer module. Error: $_"
        exit 1
    }
}

# Main execution
try {
    Write-Host "Connecting to Lansweeper database on $sqlServer..."
    
    # Create a SQL connection with TrustServerCertificate=True
    $connectionString = "Server=$sqlServer;Database=$databaseName;Integrated Security=True;TrustServerCertificate=True;"
    
    # Execute query directly with the modified connection string
    $results = Invoke-SqlCmd -Query $sqlQuery -ConnectionString $connectionString -QueryTimeout 300
    
    if ($results) {
        $count = ($results | Measure-Object).Count
        Write-Host "Query executed successfully. Retrieved $count devices."
        
        # Export ALL results to CSV
        $results | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Host "All $count results exported to $outputFile"
        
        # Display only the first 5 records as a preview
        Write-Host "`nPreview of results (showing only first 5 of $count total records):"
        $results | Select-Object -First 5 | Format-Table -AutoSize
    }
    else {
        Write-Host "Query executed successfully but returned no results."
    }
}
catch {
    Write-Error "Script execution failed: $_"
}

###
# Get lansweeper info
# Simple PowerShell script to find the SQL Server instance name
# Run this on the VM where Lansweeper or SQL Server is installed

# Option 1: Check SQL Server Configuration Manager
Write-Host "SQL Server Instances from SQL Server Configuration Manager:"
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" | 
    ForEach-Object { $_.PSObject.Properties } | 
    Where-Object { $_.Name -ne "PSPath" -and $_.Name -ne "PSParentPath" -and $_.Name -ne "PSChildName" -and $_.Name -ne "PSDrive" -and $_.Name -ne "PSProvider" } | 
    ForEach-Object { "$($env:COMPUTERNAME)\$($_.Name)" }

# Option 2: Check running SQL Server services
Write-Host "`nSQL Server Instances from Services:"
Get-Service | Where-Object {$_.DisplayName -like "SQL Server (*"} | 
    ForEach-Object {
        $instanceName = $_.DisplayName -replace "SQL Server \((.*?)\).*", '$1'
        if ($instanceName -eq "MSSQLSERVER") {
            "$($env:COMPUTERNAME)"
        } else {
            "$($env:COMPUTERNAME)\$instanceName"
        }
    }
