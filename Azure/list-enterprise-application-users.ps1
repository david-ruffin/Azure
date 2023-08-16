# Import the Az module
Import-Module Az

# Connect to Azure
Connect-AzAccount

# Set the Tenant ID
$tenantId = "< tenant id >"

# Get the access token
$token = (Get-AzAccessToken -ResourceUrl https://graph.microsoft.com -TenantId $tenantId).Token

# Set the Object ID of the service principal for the Enterprise Application
$objectId = "< object id >"

# Construct the URL for the Graph API call
$url = "https://graph.microsoft.com/v1.0/servicePrincipals/$objectId/appRoleAssignedTo"

# Invoke the Graph API call
$response = Invoke-RestMethod -Headers @{Authorization = "Bearer $token"} -Uri $url -Method Get

# Output the users
$response.value
($response.value).principalDisplayName | sort
