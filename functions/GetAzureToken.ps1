function GetAzureToken {
    param(
        [string]$client_id,
        [string]$client_secret,
        [string]$tenant_id
    )

    # Convert the client secret to a SecureString for security
    $SecureClientSecret = ConvertTo-SecureString $client_secret -AsPlainText -Force

    # Create a credential object for Azure connection
    $PsCredential = New-Object System.Management.Automation.PSCredential($client_id, $SecureClientSecret)

    # Connect to Azure with the service principal credentials
    Connect-AzAccount -ServicePrincipal -Credential $PsCredential -Tenant $tenant_id -WarningAction SilentlyContinue | Out-Null

    # Acquire an access token for Azure API requests
    $tokenBody = @{
        'grant_type'  = 'client_credentials'
        'resource'    = 'https://management.azure.com/'
        'client_id'   = $client_id
        'client_secret' = $client_secret
    }
    $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $tokenBody
    $accessToken = $tokenResponse.access_token

    return $accessToken
}
