#Install MSAL.PS module for all users (requires admin rights)
Install-Module MSAL.PS -Scope CurrentUser -Force
 
#Generate Access Token to use in the connection string to MSGraph
$AppId = 'xxx'
$TenantId = 'xxx'
$ClientSecret = 'xxx'
 
Import-Module MSAL.PS
$MsalToken = Get-MsalToken -TenantId $TenantId -ClientId $AppId -ClientSecret ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
 
#Connect to Graph using access token
Connect-Graph -AccessToken $MsalToken.AccessToken

#Log into Azure with env vars
$clientId = $env:AZURE_CLIENT_ID
$clientSecret = $env:AZURE_CLIENT_SECRET
$tenantId = $env:AZURE_TENANT_ID

$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force)

Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantId
