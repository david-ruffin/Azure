# https://www.reddit.com/r/PowerShell/comments/px9ktd/microsoft_graph/
# Define the necessary variables
$tenantId = "<YourTenantId>"
$appId = "<YourAppId>"
$appSecret = "<YourAppSecret>"
$scope = "https://graph.microsoft.com/.default"
$grantType = "client_credentials"


# Construct the body for the token request
$body = @{
    tenant = $tenantId
    client_id = $appId
    scope = $scope
    client_secret = $appSecret
    grant_type = $grantType
}

# Get the access token
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $body
$accessToken = $tokenResponse.access_token

# Set the header with the access token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Define the SKU Part Number for E1 licenses
$e1SkuPartNumber = "STANDARDPACK"

# Invoke the Microsoft Graph API to get subscribed SKUs
$subscribedSkusUri = "https://graph.microsoft.com/v1.0/subscribedSkus"
$subscribedSkusResponse = Invoke-RestMethod -Uri $subscribedSkusUri -Headers $headers -Method Get

# Filter for E1 licenses and calculate available licenses
$e1Licenses = $subscribedSkusResponse.value | Where-Object { $_.skuPartNumber -eq $e1SkuPartNumber }
$e1AvailableLicenses = $e1Licenses.prepaidUnits.enabled - $e1Licenses.consumedUnits

# Output the number of available E1 licenses
if ($e1AvailableLicenses -gt 0) {
    Write-Output "There are $e1AvailableLicenses E1 licenses available."
} else {
    Write-Output "There are no E1 licenses available."
}
