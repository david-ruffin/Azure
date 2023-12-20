$subscription_id = 'xxx'
$client_id = 'xxx'
$client_secret = 'xxx'
$tenant_id = 'xxx'
$Resource = "https://management.core.windows.net/"
$AppKey = $client_secret | ConvertTo-SecureString -AsPlainText -Force
$loginUrl = "https://login.microsoftonline.com"

$body = @{
    grant_type = "client_credentials"
    resource = $Resource
    client_id = $client_id
    client_secret = (New-Object PSCredential $client_id, $AppKey).GetNetworkCredential().Password
}
$token = Invoke-RestMethod -Method Post -Uri $loginUrl/$tenant_id/oauth2/token?api-version=1.0 -Body $body


$billing_period = '202311'
$usageURL = "https://management.azure.com/subscriptions/$subscription_id/providers/Microsoft.Billing/billingPeriods/$billing_period/providers/Microsoft.Consumption/usageDetails?api-version=2023-05-01"

$header = @{
    'Authorization' = "Bearer $($token.access_token)"
    "Content-Type" = "application/json"
}
$UsageData = Invoke-RestMethod -Method Get -Uri $usageURL -Headers $header

$totalCost = 0.0

foreach ($record in $UsageData.value) {
    if ($record.properties -and $record.properties.CostInBillingCurrency) {
        $totalCost += $record.properties.CostInBillingCurrency
    }
}

Write-Host "Total cost for November 2023: $totalCost"


$totalCostUSD = 0.0

foreach ($record in $UsageData.value) {
    if ($record.properties -and $record.properties.costInUSD) {
        $totalCostUSD += $record.properties.costInUSD
    }
}

Write-Host "Total cost for November 2023 in USD: $totalCostUSD"
