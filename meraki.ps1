# https://developer.cisco.com/meraki/api-v1/introduction/#base-uri

# In the portal, setup api key
Run this command to get org id (name: id)
curl -L -H 'X-Cisco-Meraki-API-Key: <api_key>' -H 'Content-Type: application/json' -X GET 'https: //api.meraki.com/api/v1/organizations'

# --- Configuration: YOU MUST PROVIDE THESE ---
$ApiKey         = "YOUR_COPIED_API_KEY"
$OrganizationId = "YOUR_ORGANIZATION_ID" 
# --- End Configuration ---

$headers = @{ "X-Cisco-Meraki-API-Key" = $ApiKey }
$baseUrl = "https://api.meraki.com/api/v1"

# Helper function
function Out-NullIfEmpty($Value) {
    if ([string]::IsNullOrEmpty($Value)) { return "N/A" } else { return $Value }
}

try {
    # STEP 1: Get all networks in the organization to create a NetworkID -> NetworkName mapping
    Write-Host "Fetching all network names for Organization ID: $OrganizationId..."
    $networksUri = "$baseUrl/organizations/$OrganizationId/networks"
    $allNetworks = Invoke-RestMethod -Uri $networksUri -Headers $headers -Method Get -ErrorAction Stop
    
    $networkNameMap = @{} # Create a hashtable for quick lookups
    foreach ($network in $allNetworks) {
        $networkNameMap[$network.id] = $network.name
    }
    Write-Host "Network name mapping complete. Found $($networkNameMap.Count) networks."
    Write-Host "--------------------------------------------------------------------------------------------"

    # STEP 2: Get uplink statuses for all MX/Z-series appliances
    $uplinksUri = "$baseUrl/organizations/$OrganizationId/appliance/uplink/statuses"
    Write-Host "Fetching uplink statuses for all MX/Z-series appliances..."
    $allUplinkStatuses = Invoke-RestMethod -Uri $uplinksUri -Headers $headers -Method Get -ErrorAction Stop

    if ($allUplinkStatuses) {
        Write-Host "Successfully retrieved uplink statuses for $($allUplinkStatuses.Count) appliances."
        Write-Host "--------------------------------------------------------------------------------------------"
        
        $outputTable = [System.Collections.Generic.List[PSCustomObject]]::new()

        foreach ($deviceStatus in $allUplinkStatuses) {
            $networkId = $deviceStatus.networkId
            $networkName = $networkNameMap[$networkId] # Look up the network name
            if ([string]::IsNullOrEmpty($networkName)) {
                $networkName = "Network ID: $networkId (Name Not Found)" # Fallback if ID not in map
            }

            if ($deviceStatus.uplinks -and $deviceStatus.uplinks.Count -gt 0) {
                foreach ($uplink in $deviceStatus.uplinks) {
                    if (-not [string]::IsNullOrEmpty($uplink.publicIp) -and $uplink.publicIp -ne "N/A") {
                        $outputTable.Add([PSCustomObject]@{
                            "Network Name" = $networkName
                            "Interface"    = $uplink.interface
                            "Public IP"    = $uplink.publicIp
                            "Status"       = $uplink.status
                            "Device Model" = $deviceStatus.model
                            "Device Serial"= $deviceStatus.serial
                        })
                    }
                }
            }
        }

        if ($outputTable.Count -gt 0) {
            Write-Host "Network Public IP Information:"
            $outputTable | Format-Table -AutoSize # Display the table
            
            # Optional: Export to CSV
            # $csvPath = "C:\temp\MerakiPublicIPs.csv"
            # $outputTable | Export-Csv -Path $csvPath -NoTypeInformation
            # Write-Host "Data also exported to $csvPath"

        } else {
            Write-Warning "No active public IPs found for any MX/Z-series appliances."
        }

    } else {
        Write-Warning "API call for uplink statuses was successful but no data was returned."
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.Value__ 
        Write-Error "HTTP Status Code: $statusCode"
        # Add more detailed error body parsing if needed
    }
}
