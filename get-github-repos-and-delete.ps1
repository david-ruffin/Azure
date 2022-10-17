# This script will get repos in your organization repo and delete
# Add your token string to $token var
$token = "123"
$token_string = ("Bearer " + $token) 

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $token_string) 
 

$headers.Add("Authorization", "Bearer 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")

$response = Invoke-RestMethod 'https://api.github.com/orgs/405network-com/repos' -Method 'GET' -Headers $headers -TimeoutSec 999999
$response | ConvertTo-Json

$response.name

$repos = $response.name
$url = 'https://api.github.com/repos/405Network-com/'
$repos | foreach {

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer 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")

$response = Invoke-RestMethod ($url + $_) -Method 'DELETE' -Headers $headers
$response | ConvertTo-Json } 
