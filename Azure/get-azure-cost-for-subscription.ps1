# Authentication and request details
$client_id = "xxx"
$client_secret = "xxx"
$tenant_id = "xxx"
$subscription_id = "xx"

# Acquire Token
$tokenBody = @{
    'grant_type'    = 'client_credentials'
    'resource'      = 'https://management.azure.com/'
    'client_id'     = $client_id
    'client_secret' = $client_secret
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $tokenBody
$accessToken = $tokenResponse.access_token

# API endpoint and request body
$apiEndpoint = "https://management.azure.com/subscriptions/$subscription_id/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
$requestBody = @{
    "type" = "ActualCost"
    "timeframe" = "Custom"
    "timePeriod" = @{
        "from" = "2023-12-01T00:00:00+00:00"
        "to" = "2023-12-31T23:59:59+00:00"
    }
    "dataset" = @{
        "granularity" = "None"
        "aggregation" = @{
            "totalCost" = @{
                "name" = "PreTaxCost"
                "function" = "Sum"
            }
        }
        "grouping" = @(
            @{
                "type" = "Dimension"
                "name" = "SubscriptionName"
            }
        )
    }
}

# Define headers for API request
$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $accessToken"
}

# Send POST request and process the response
try {
    $jsonBody = $requestBody | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Post -Body $jsonBody

    # Check if response is already a PowerShell object or a JSON string
    $parsedResponse = if ($response -is [System.String]) {
        $response | ConvertFrom-Json
    } else {
        $response
    }

    # Extracting the cost amount and subscription name
    $costAmount = [math]::Truncate([double]$parsedResponse.properties.rows[0][0])
    $subscriptionName = $parsedResponse.properties.rows[0][1]

    # Creating a custom object
    $costInfo = New-Object PSObject -Property @{
        SubscriptionName = $subscriptionName
        CostAmount = $costAmount
    }

    # Output the object
    $costInfo | ConvertTo-Json -Depth 10
}
catch {
    # Error handling
    Write-Error "Error: $_"
}
