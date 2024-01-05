<#
.SYNOPSIS
Retrieves the cost information for an Azure subscription.

.DESCRIPTION
This cmdlet fetches the cost information for a specified Azure subscription using the Azure Cost Management API. It requires a service principal for authentication and returns the total cost along with the subscription name.

.PARAMETER ClientId
The Client ID of the Azure service principal.

.PARAMETER ClientSecret
The Client Secret of the Azure service principal.

.PARAMETER TenantId
The Tenant ID of the Azure service principal.

.PARAMETER SubscriptionId
The ID of the Azure subscription for which cost information is being retrieved.

.PARAMETER StartDate
The start date of the period for which costs are to be retrieved, in ISO 8601 format.

.PARAMETER EndDate
The end date of the period for which costs are to be retrieved, in ISO 8601 format.

.EXAMPLE
PS> Get-AzureCostInfo -ClientId 'your_client_id' -ClientSecret 'your_client_secret' -TenantId 'your_tenant_id' -SubscriptionId 'your_subscription_id' -StartDate '2023-12-01T00:00:00+00:00' -EndDate '2023-12-31T23:59:59+00:00'

This command retrieves the total cost information for the Azure subscription 'your_subscription_id' for the month of December 2023.

.NOTES
Requires the Azure PowerShell module and appropriate permissions to access the Azure subscription and make billing queries.

.LINK
https://docs.microsoft.com/en-us/rest/api/cost-management/
#>
function Get-AzureCostInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ClientId,

        [Parameter(Mandatory=$true)]
        [string]$ClientSecret,

        [Parameter(Mandatory=$true)]
        [string]$TenantId,

        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory=$true)]
        [string]$StartDate,

        [Parameter(Mandatory=$true)]
        [string]$EndDate
    )

    Begin {
        # Acquire Token
        $tokenBody = @{
            'grant_type'    = 'client_credentials'
            'resource'      = 'https://management.azure.com/'
            'client_id'     = $ClientId
            'client_secret' = $ClientSecret
        }

        try {
            $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" -Body $tokenBody
        }
        catch {
            Write-Error "Failed to acquire token: $_"
            return
        }
        $accessToken = $tokenResponse.access_token
    }

    Process {
        # API endpoint and request body
        $apiEndpoint = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
        $requestBody = @{
            "type" = "ActualCost"
            "timeframe" = "Custom"
            "timePeriod" = @{
                "from" = $StartDate
                "to" = $EndDate
            }
            "dataset" = @{
                "granularity" = "None"
                "aggregation" = @{
                    "totalCost" = @{
                        "name" = "PreTaxCost"
                        "function" = "Sum"
                    }
                }
                "grouping" = @(
                    @{
                        "type" = "Dimension"
                        "name" = "SubscriptionName"
                    }
                )
            }
        }

        # Define headers for API request
        $headers = @{
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $accessToken"
        }

        try {
            $jsonBody = $requestBody | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Post -Body $jsonBody
        }
        catch {
            Write-Error "Failed to invoke REST method: $_"
            return
        }

        # Parsing and handling the response
        try {
            $parsedResponse = if ($response -is [System.String]) {
                $response | ConvertFrom-Json
            } else {
                $response
            }

            $costAmount = [math]::Truncate([double]$parsedResponse.properties.rows[0][0])
            $subscriptionName = $parsedResponse.properties.rows[0][1]

            # Creating a custom object
            $costInfo = New-Object PSObject -Property @{
                SubscriptionName = $subscriptionName
                CostAmount = $costAmount
            }

            return $costInfo
        }
        catch {
            Write-Error "Failed to parse response: $_"
        }
    }
}
