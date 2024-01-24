<#
.SYNOPSIS
This PowerShell script automates the process of retrieving Azure subscription cost data and sends personalized cost reports to each subscription owner.

.DESCRIPTION
This script connects to Azure using service principal credentials and fetches cost data for all enabled Azure subscriptions. It then processes this data to calculate the costs for the previous two months and the percentage change in these costs. 

For each subscription, the script:
- Retrieves Azure costs for the previous two months.
- Identifies the subscription owner.
- Calculates the percentage change in costs between the two months.
- Compiles this data into an HTML table.
- Sends a personalized email to each subscription owner with their cost details. If an owner has multiple subscriptions, all information is consolidated into a single email.

The script also includes error handling for email sending with a retry mechanism.

.PREREQUISITES
- Azure PowerShell Az Module.
- MSAL.PS, Mailozaurr, and PSWriteHTML PowerShell modules.
- Azure service principal with appropriate permissions for accessing subscription and cost data.
- Proper configuration of Managed Identity for authentication.

.PARAMETERS
- Client ID, Client Secret, and Tenant ID for Azure service principal authentication.
- Email addresses for sending and receiving reports.

.EXAMPLE
.\AzureCostReport.ps1

.INPUTS
None. All inputs are retrieved within the script from Azure and defined parameters.

.OUTPUTS
Emails to subscription owners with cost details.

.NOTES
Version:        1.0
Author:         Vyente Ruffin
Creation Date:  01/24/24
Purpose/Change: Initial script development

#>

# Declare variables and Authentication
$client_id = "xxx"
$client_secret = "xxx"
$tenant_id = "xxx"
$from_email_address = "user1@contoso.com"
$to_email_address = "user2@contoso.com"
$cc_email_address = @("user3@contoso.com", "user4@contoso.com")

# Get the names of the previous month and the month before that
$previous_month = (Get-Date).AddMonths(-1).ToString("MMMM yyyy")
$previous_2_months = (Get-Date).AddMonths(-2).ToString("MMMM yyyy")

# Convert the client secret to a SecureString for security
$SecureClientSecret = ConvertTo-SecureString $client_secret -AsPlainText -Force

# Create a credential object for Azure connection
$PsCredential = New-Object System.Management.Automation.PSCredential($client_id, $SecureClientSecret)

# Connect to Azure with the service principal credentials
Connect-AzAccount -ServicePrincipal -Credential $PsCredential -Tenant $tenant_id -WarningAction SilentlyContinue | Out-Null

# Date Calculations
$lastMonth = (Get-Date).AddMonths(-1)
$startDate = Get-Date -Year $lastMonth.Year -Month $lastMonth.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate = $startDate.AddMonths(1).AddSeconds(-1)

$twoMonthsAgo = (Get-Date).AddMonths(-2)
$startDateTwoMonthsAgo = Get-Date -Year $twoMonthsAgo.Year -Month $twoMonthsAgo.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDateTwoMonthsAgo = $startDateTwoMonthsAgo.AddMonths(1).AddSeconds(-1)

# Access Token Acquisition
$tokenBody = @{
    'grant_type'    = 'client_credentials'
    'resource'      = 'https://management.azure.com/'
    'client_id'     = $client_id
    'client_secret' = $client_secret
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant_id/oauth2/token" -Body $tokenBody
$accessToken = $tokenResponse.access_token

# Subscription Retrieval
#$subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"} | Select-Object Name, Id, @{Name='Owner'; Expression={$_.Tags["owner"]}}
$subscriptions = Get-AzSubscription | 
Where-Object { $_.State -eq "Enabled" } | 
Select-Object Name, Id, 
@{Name = 'Owner'; Expression = { $_.Tags["owner"] } } #| Select-Object -first 1
# Initialize an array to store cost information for each subscription
$allCostInfo = @()

# Function to get cost amount for a subscription
function GetCostAmount($requestBody, $apiEndpoint, $headers, $subscriptionName) {
    try {
        Write-Host "Checking cost for subscription: $subscriptionName"
        Start-Sleep -Seconds 20
        $jsonBody = $requestBody | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Post -Body $jsonBody

        if ($response.properties.rows.Count -eq 0) {
            Write-Host "No cost data available for subscription: $subscriptionName"
            return $null
        }
        
        return [int][math]::Truncate([double]$response.properties.rows[0][0])
    }
    catch {
        Write-Warning "Failed to retrieve cost for subscription: $subscriptionName. Error: $_"
        return $null
    }
}

# Function to calculate percentage change
function CalculatePercentageChange($oldValue, $newValue) {
    if ($oldValue -eq 0) {
        return $newValue -eq 0 ? 0 : 100
    }
    else {
        return (($newValue - $oldValue) / $oldValue) * 100
    }
}

# Function to create request body
function CreateRequestBody($fromDate, $toDate) {
    @{
        "type"       = "ActualCost"
        "timeframe"  = "Custom"
        "timePeriod" = @{
            "from" = $fromDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "to"   = $toDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        "dataset"    = @{
            "granularity" = "None"
            "aggregation" = @{
                "totalCost" = @{
                    "name"     = "PreTaxCost"
                    "function" = "Sum"
                }
            }
            "grouping"    = @(
                @{
                    "type" = "Dimension"
                    "name" = "SubscriptionName"
                }
            )
        }
    }
}

# Process each subscription to gather cost information
foreach ($subscription in $subscriptions) {
    Write-Host "Now processing subscription: $($subscription.Name)"
    $apiEndpoint = "https://management.azure.com/subscriptions/$($subscription.Id)/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $accessToken"
        'ClientType'    = 'YourCustomClientType'  # Custom client type to manage API rate limits
    }

    $requestBodyLastMonth = CreateRequestBody $startDate $endDate
    $requestBodyTwoMonthsAgo = CreateRequestBody $startDateTwoMonthsAgo $endDateTwoMonthsAgo

    $costAmountLastMonth = GetCostAmount $requestBodyLastMonth $apiEndpoint $headers $subscription.Name
    if ($costAmountLastMonth -eq $null) {
        continue
    }

    $costAmountTwoMonthsAgo = GetCostAmount $requestBodyTwoMonthsAgo $apiEndpoint $headers $subscription.Name
    if ($costAmountTwoMonthsAgo -eq $null) {
        continue
    }

    $percentageChange = CalculatePercentageChange $costAmountTwoMonthsAgo $costAmountLastMonth

    $costInfo = New-Object -TypeName PSObject -Property @{
        SubscriptionName                = $subscription.Name
        Owner                           = $subscription.Owner
        ($previous_month + " Costs")    = '$' + $costAmountLastMonth
        ($previous_2_months + " Costs") = '$' + $costAmountTwoMonthsAgo
        "Percentage Change"             = [math]::Round($percentageChange, 2)
    }
    $allCostInfo += $costInfo
}

$ownerCostDetails = @{}
foreach ($info in $allCostInfo) {
    if ([string]::IsNullOrWhiteSpace($info.Owner)) {
        Write-Warning "Skipping a subscription due to null or empty owner."
        continue
    }
    if (-not $ownerCostDetails.ContainsKey($info.Owner)) {
        $ownerCostDetails[$info.Owner] = @()
    }
    $ownerCostDetails[$info.Owner] += $info
}

# Send an email for each owner with their subscription details
Install-Module MSAL.PS -Scope CurrentUser -Force | Out-Null
Install-Module Mailozaurr -Force | Out-Null
Install-Module PSWriteHTML -Force | Out-Null
Import-Module -Name PSWriteHTML

# Generate Access Token to use in the connection string to MSGraph
$MsalToken = Get-MsalToken -TenantId $Tenant_Id -ClientId $Client_Id -ClientSecret ($Client_Secret | ConvertTo-SecureString -AsPlainText -Force)

#Connect to Graph using access token
$Credential = ConvertTo-GraphCredential -MsalToken $MsalToken.AccessToken

foreach ($owner in $ownerCostDetails.Keys) {
    # Create a single HTML table for each owner
    $subscriptionsHtml = New-HTML -Content {
        $ownerSubscriptions = $ownerCostDetails[$owner] | Select-Object SubscriptionName, "$previous_month Costs", "$previous_2_months Costs", "Percentage Change"
        New-HTMLTable -DataTable $ownerSubscriptions -HideFooter
    } -FilePath $tempFile

    # Read the HTML content from the temporary file
    $subscriptionsHtml = Get-Content -Path $tempFile -Raw

    # Get the first name of the owner
    $firstName = (Get-AzADUser -Mail $owner).GivenName
    # Construct the HTML body for the email
    $htmlbody = @"
    <html>
        <body>
            Hello $firstname,<br>
            Below are your Azure subscription(s) costs for the last two months. <br><br>
            
            $subscriptionsHtml
            
        </body>
    </html>
"@

    $retryCount = 0
    $retryMax = 5

    while ($retryCount -lt $retryMax) {
        # Send the email
        $result = Send-EmailMessage -From $from_email_address -To $to_email_address -Credential $Credential -HTML $htmlbody -Subject "Azure Subscription Costs as of $date" -Graph -DoNotSaveToSentItems -Verbose -ErrorAction SilentlyContinue
        if ($result.Status) {
            Write-Host "Email sent successfully."
            break
        }
        else {
            $retryCount++
            Write-Host "Failed to send email. Attempt: $retryCount"
            Start-Sleep -Seconds 5 # You may adjust this sleep time as per your need
        }
    }
    if ($retryCount -eq $retryMax) {
        Write-Host "Failed to send email after $retryMax attempts."
    }
}

# Optional: Disconnect from Azure to clean up the session
Disconnect-AzAccount -Confirm:$false | Out-Null
