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
