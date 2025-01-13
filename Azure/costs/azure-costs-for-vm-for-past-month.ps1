# Variables
$subscriptionId = "YOUR-SUBSCRIPTION-ID"
$resourceGroupName = "YOUR-RG-NAME"
$vmName = "YOUR-VM-NAME"

# Date Calculations
$lastMonth = (Get-Date).AddMonths(-1)
$startDate = Get-Date -Year $lastMonth.Year -Month $lastMonth.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate = $startDate.AddMonths(1).AddSeconds(-1)

# Get VM Resource ID
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$vmId = $vm.Id

# Create request body using same format as original script
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
                "values" = @($vmId)
            }
        }
    }
}

# Get access token from current context
$token = (Get-AzAccessToken).Token
$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $token"
}

# Use same API endpoint format
$apiEndpoint = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.CostManagement/query?api-version=2023-11-01"

# Get cost data
$response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Post -Body ($requestBody | ConvertTo-Json -Depth 10)
$vmCost = [int][math]::Truncate([double]$response.properties.rows[0][0])

# Output results
[PSCustomObject]@{
    VMName = $vmName
    Month = $startDate.ToString("MMMM yyyy")
    Cost = '$' + $vmCost
}
