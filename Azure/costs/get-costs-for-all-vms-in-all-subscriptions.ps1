# Service Principal Credentials
$client_id = "YOUR_CLIENT_ID"
$client_secret = "YOUR_CLIENT_SECRET"
$tenant_id = "YOUR_TENANT_ID"

# Connect using Service Principal
$SecureClientSecret = ConvertTo-SecureString $client_secret -AsPlainText -Force
$PsCredential = New-Object System.Management.Automation.PSCredential($client_id, $SecureClientSecret)
Connect-AzAccount -ServicePrincipal -Credential $PsCredential -Tenant $tenant_id

# Get all subscriptions
$subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"}
$allVMCosts = @()

# Date Calculations
$lastMonth = (Get-Date).AddMonths(-1)
$startDate = Get-Date -Year $lastMonth.Year -Month $lastMonth.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate = $startDate.AddMonths(1).AddSeconds(-1)

# Get token once
$tokenBody = @{
    'grant_type'    = 'client_credentials'
    'resource'      = 'https://management.azure.com/'
    'client_id'     = $client_id
    'client_secret' = $client_secret
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $tokenBody
$accessToken = $tokenResponse.access_token

foreach ($sub in $subscriptions) {
    Write-Host "Processing subscription: $($sub.Name)" -ForegroundColor Green
    Set-AzContext -Subscription $sub.Id | Out-Null
    
    $vms = Get-AzVM
    Write-Host "Found $($vms.Count) VMs"
    
    foreach ($vm in $vms) {
        Write-Host "Processing VM: $($vm.Name)" -ForegroundColor Cyan
        
        $requestBody = @{
            "type" = "ActualCost"
            "timeframe" = "Custom"
            "timePeriod" = @{
                "from" = $startDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                "to" = $endDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
            "dataset" = @{
                "granularity" = "None"
                "aggregation" = @{
                    "totalCost" = @{
                        "name" = "PreTaxCost"
                        "function" = "Sum"
                    }
                }
                "filter" = @{
                    "dimensions" = @{
                        "name" = "ResourceId"
                        "operator" = "In"
                        "values" = @($vm.Id)
                    }
                }
            }
        }

        $headers = @{
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $accessToken"
            'ClientType' = 'YourCustomClientType'
        }

        $apiEndpoint = "https://management.azure.com/subscriptions/$($sub.Id)/providers/Microsoft.CostManagement/query?api-version=2023-11-01"

        Start-Sleep -Seconds 20

        try {
            $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Post -Body ($requestBody | ConvertTo-Json -Depth 10)
            
            if ($response.properties.rows.Count -gt 0) {
                $vmCost = [int][math]::Truncate([double]$response.properties.rows[0][0])
            } else {
                $vmCost = 0
            }

            $allVMCosts += [PSCustomObject]@{
                SubscriptionName = $sub.Name
                ResourceGroup = $vm.ResourceGroupName
                VMName = $vm.Name
                Status = $vm.PowerState
                Location = $vm.Location
                Month = $startDate.ToString("MMMM yyyy")
                Cost = '$' + $vmCost
            }
        }
        catch {
            Write-Warning "Failed to get cost for VM $($vm.Name): $_"
        }
    }
}

$allVMCosts | Format-Table -AutoSize
$allVMCosts | Export-Csv -Path "VMCosts_$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
