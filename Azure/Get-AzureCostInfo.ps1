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

    # Script implementation remains the same as previously provided
}
