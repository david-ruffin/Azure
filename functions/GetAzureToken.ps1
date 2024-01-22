function GetAzureToken {
    <#
    .SYNOPSIS
    Acquires an Azure access token using a service principal.

    .DESCRIPTION
    This function makes a REST API call to Azure's OAuth 2.0 token endpoint to obtain an access token. 
    It's designed to be used for non-interactive authentication to Azure for making API requests.

    .PARAMETER client_id
    The Client ID of the Azure service principal.

    .PARAMETER client_secret
    The Client Secret of the Azure service principal. It should be treated securely.

    .PARAMETER tenant_id
    The Tenant ID of the Azure account.

    .EXAMPLE
    $accessToken = GetAzureToken -client_id 'xxxxxx' -client_secret 'xxxxxx' -tenant_id 'xxxxxx'

    .NOTES
    This function is useful for scripts that need to authenticate with Azure non-interactively, 
    such as in automated workflows or CI/CD pipelines.
    #>

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
