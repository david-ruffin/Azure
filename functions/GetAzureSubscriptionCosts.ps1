<#
.SYNOPSIS
Retrieves cost information for a specific Azure subscription.

.DESCRIPTION
This function calculates costs for the previous two months for a given Azure subscription.
It uses Azure's Cost Management API to fetch the cost data and then calculates the percentage change in costs.

.PARAMETER SubscriptionId
The ID of the Azure subscription for which the costs are to be retrieved.

.PARAMETER AccessToken
The OAuth access token for making authenticated Azure API calls.

.EXAMPLE
$costs = GetAzureSubscriptionCosts -SubscriptionId 'your-subscription-id' -AccessToken 'your-access-token'

.OUTPUTS
Hashtable containing the subscription's cost information.

.NOTES
This function requires the following functions to be defined in the script:
- GetCostAmount
- CalculatePercentageChange
- CreateRequestBody
#>
function GetAzureSubscriptionCosts {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory=$true)]
        [string]$AccessToken
    )

    # Date Calculation for the previous two months
    $previous_month = (Get-Date).AddMonths(-1).ToString("MMMM yyyy")
    $previous_2_months = (Get-Date).AddMonths(-2).ToString("MMMM yyyy")
    $startDate = Get-Date -Year (Get-Date).AddMonths(-1).Year -Month (Get-Date).AddMonths(-1).Month -Day 1
    $endDate = $startDate.AddMonths(1).AddSeconds(-1)
    $startDateTwoMonthsAgo = Get-Date -Year (Get-Date).AddMonths(-2).Year -Month (Get-Date).AddMonths(-2).Month -Day 1
    $endDateTwoMonthsAgo = $startDateTwoMonthsAgo.AddMonths(1).AddSeconds(-1)

    # Headers for Azure API calls
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $AccessToken"
    }

    # Create request bodies for cost queries
    $requestBodyLastMonth = CreateRequestBody $startDate $endDate
    $requestBodyTwoMonthsAgo = CreateRequestBody $startDateTwoMonthsAgo $endDateTwoMonthsAgo

    # API endpoint for Azure Cost Management
    $apiEndpoint = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/query?api-version=2023-11-01"

    # Retrieve cost amounts for the previous two months
    $costAmountLastMonth = GetCostAmount $requestBodyLastMonth $apiEndpoint $headers
    $costAmountTwoMonthsAgo = GetCostAmount $requestBodyTwoMonthsAgo $apiEndpoint $headers

    # Calculate percentage change in costs
    $percentageChange = CalculatePercentageChange $costAmountTwoMonthsAgo $costAmountLastMonth

    # Construct and return the cost information
    return @{
        SubscriptionId = $SubscriptionId
        ($previous_month + " Costs") = $costAmountLastMonth
        ($previous_2_months + " Costs") = $costAmountTwoMonthsAgo
        "Percentage Change" = [math]::Round($percentageChange, 2)
    }
}
