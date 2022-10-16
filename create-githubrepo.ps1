# Create repo in github using powershell rest command
# https://medium.com/objectsharp/create-a-github-repo-with-powershell-27fc2e697a3d
param ([Parameter(Mandatory=$true)] $repoName)
$orgName = "405Network-com"
$pat = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:GH_PAT)"))
$body = @{name="$repoName"}
$params = @{
'Uri' = ('https://api.github.com/orgs/{0}/repos' -f $orgName)
'Headers'     = @{'Authorization' = 'Basic ' + $pat}
'Method'      = 'Post'
'ContentType' = 'application/json'
'Body'        = ($body | ConvertTo-Json)}
Invoke-RestMethod @params
