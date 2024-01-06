# Declare variables and Authentication
$client_id = "xxx"
$client_secret = "xxx"
$tenant_id = "xxx"

# Get the names of the previous month and the month before that
$previous_month = (Get-Date).AddMonths(-1).ToString("MMMM yyyy")
$previous_2_months = (Get-Date).AddMonths(-2).ToString("MMMM yyyy")
    
# Convert the client secret to a SecureString for security
$SecureClientSecret = ConvertTo-SecureString $client_secret -AsPlainText -Force

# Create a credential object for Azure connection
$PsCredential = New-Object System.Management.Automation.PSCredential($client_id, $SecureClientSecret)

# Connect to Azure with the service principal credentials
Connect-AzAccount -ServicePrincipal -Credential $PsCredential -Tenant $tenant_id 

# Calculate last month's start and end dates
$lastMonth = (Get-Date).AddMonths(-1)
$startDate = Get-Date -Year $lastMonth.Year -Month $lastMonth.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate = $startDate.AddMonths(1).AddSeconds(-1)

# Calculate the start and end dates for two months ago
$twoMonthsAgo = (Get-Date).AddMonths(-2)
$startDateTwoMonthsAgo = Get-Date -Year $twoMonthsAgo.Year -Month $twoMonthsAgo.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDateTwoMonthsAgo = $startDateTwoMonthsAgo.AddMonths(1).AddSeconds(-1)

# Acquire an access token for Azure API requests
$tokenBody = @{
    'grant_type'    = 'client_credentials'
    'resource'      = 'https://management.azure.com/'
    'client_id'     = $client_id
    'client_secret' = $client_secret
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $tokenBody
$accessToken = $tokenResponse.access_token

# Retrieve all Azure subscriptions that are enabled
$subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"}

# Initialize an array to store cost information for each subscription
$allCostInfo = @()

# Function to get cost amount for a subscription
function GetCostAmount($requestBody, $apiEndpoint, $headers) {
    do {
        try {
            Start-Sleep -Seconds 20  # Enforce wait time between API calls to avoid rate limits
            $jsonBody = $requestBody | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Post -Body $jsonBody
            return [int][math]::Truncate([double]$response.properties.rows[0][0])
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                $retryAfter = [int] $_.Exception.Response.Headers['Retry-After']
                Start-Sleep -Seconds $retryAfter
            }
            else {
                Write-Warning "Failed to retrieve cost for subscription: $($subscription.Id). Error: $_"
                return $null
            }
        }
    } while ($true)
}

# Function to calculate percentage change
function CalculatePercentageChange($oldValue, $newValue) {
    if ($oldValue -eq 0) {
        return $newValue -eq 0 ? 0 : 100
    } else {
        return (($newValue - $oldValue) / $oldValue) * 100
    }
}

# Process each subscription to gather cost information
foreach ($subscription in $subscriptions) {
    $apiEndpoint = "https://management.azure.com/subscriptions/$($subscription.Id)/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $accessToken"
        'ClientType'    = 'YourCustomClientType'  # Custom client type to manage API rate limits
    }

    # Prepare request bodies for API calls
    $requestBodyLastMonth = CreateRequestBody $startDate $endDate
    $requestBodyTwoMonthsAgo = CreateRequestBody $startDateTwoMonthsAgo $endDateTwoMonthsAgo

    # Retrieve cost amounts
    $costAmountLastMonth = GetCostAmount $requestBodyLastMonth $apiEndpoint $headers
    $costAmountTwoMonthsAgo = GetCostAmount $requestBodyTwoMonthsAgo $apiEndpoint $headers

    # Calculate the percentage change in costs
    $percentageChange = CalculatePercentageChange $costAmountTwoMonthsAgo $costAmountLastMonth

    # Create an object to hold the subscription's cost information
    $costInfo = New-Object -TypeName PSObject -Property @{
        SubscriptionName = $subscription.Name
        ("$previous_month Total Costs") = $costAmountLastMonth
        ("$previous_2_months Total Costs") = $costAmountTwoMonthsAgo
        "Percentage Change" = [math]::Round($percentageChange, 2)
    }

    # Add the cost information to the array
    $allCostInfo += $costInfo
}

# Output the cost information for all subscriptions
return $allCostInfo

# Disconnect from Azure to clean up the session
Disconnect-AzAccount -Force
