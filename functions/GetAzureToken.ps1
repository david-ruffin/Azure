<#
.SYNOPSIS
Acquires an Azure access token using a service principal.

.DESCRIPTION
This function makes a REST API call to Azure's OAuth 2.0 token endpoint to obtain an access token for Azure REST API calls.
It's designed for non-interactive authentication using service principal credentials.

.PARAMETER client_id
The Client ID of the Azure service principal.

.PARAMETER client_secret
The Client Secret of the Azure service principal. It is handled as a SecureString for security.

.PARAMETER tenant_id
The Tenant ID of the Azure account.

.EXAMPLE
$accessToken = GetAzureToken -client_id 'xxxxxx' -client_secret 'xxxxxx' -tenant_id 'xxxxxx'

.NOTES
Modules required:
- Az.Accounts: For using Azure-specific cmdlets (e.g., Get-AzAccessToken).
- Microsoft.PowerShell.Utility: For making REST API calls using Invoke-RestMethod.
Ensure these modules are installed and up to date in your PowerShell environment.
Use 'Install-Module -Name Az -AllowClobber -Scope CurrentUser' to install the Az module.

.LINK
https://learn.microsoft.com/en-us/powershell/module/az.accounts/get-azaccesstoken
#>

function GetAzureToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$client_id,

        [Parameter(Mandatory=$true)]
        [string]$client_secret,

        [Parameter(Mandatory=$true)]
        [string]$tenant_id
    )

    # Convert the client secret to a SecureString
    $SecureClientSecret = ConvertTo-SecureString -String $client_secret -AsPlainText -Force

    # Prepare the body for the OAuth 2.0 token request
    $tokenBody = @{
        'grant_type'    = 'client_credentials'
        'resource'      = 'https://management.azure.com/'
        'client_id'     = $client_id
        'client_secret' = [System.Net.NetworkCredential]::new("", $SecureClientSecret).Password
    }

    # Send the request to Azure's token endpoint
    try {
        $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $tokenBody
        $accessToken = $tokenResponse.access_token
    } catch {
        Write-Error "Failed to retrieve Azure access token: $_"
        return $null
    }

    # Return the access token
    return $accessToken
}
