# Define credentials and parameters
$clientId = ""
$tenantId = ""
$clientSecret = ""
$siteId = "" # Replace with your SharePoint Site ID
$listId = "" # Replace with your SharePoint List ID
# Array of users to process
$UserIds = @(
   "user1@contoso.com",
   "user2@contoso.com",
   "user3@contoso.com"
   # Add more users as needed
)


# Retry configuration
$retryMaxAttempts = 3
$retryBaseDelay = 2 # Seconds
$pageRequestDelay = 1 # Seconds between paginated requests

# Get Graph token
$authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id = $clientId
    client_secret = $clientSecret
    scope = "https://graph.microsoft.com/.default"
    grant_type = "client_credentials"
}
$response = Invoke-RestMethod -Method POST -Uri $authUrl -Body $body -ContentType "application/x-www-form-urlencoded"
$accessToken = $response.access_token

$baseUrl = "https://graph.microsoft.com/v1.0"
$allEmails = @()
$headers = @{
    Authorization = "Bearer $accessToken"
    ConsistencyLevel = "eventual"
}

foreach ($userId in $UserIds) {
    Write-Output "Processing emails for user: $userId"
    
    $lastWeek = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $filter = "receivedDateTime ge $lastWeek or sentDateTime ge $lastWeek"
    $emailUrl = "$baseUrl/users/$userId/messages?`$select=receivedDateTime,sentDateTime,from,toRecipients,subject,isRead&`$filter=$filter"
    
    $nextLink = $emailUrl
    while ($nextLink) {
        $currentAttempt = 0
        $success = $false
        
        do {
            try {
                $emails = Invoke-RestMethod -Method GET -Uri $nextLink -Headers $headers -ErrorAction Stop
                $success = $true
                
                # Process emails
                foreach ($email in $emails.value) {
                    $isSent = $email.from.emailAddress.address -eq $userId
                    $emailData = [PSCustomObject]@{
                        UserName = $userId.Split('@')[0]
                        ReceivedDate = if(!$isSent) { $email.receivedDateTime } else { $null }
                        SentDate = if($isSent) { $email.sentDateTime } else { $null }
                        SenderAddress = $email.from.emailAddress.address
                        RecipientAddresses = ($email.toRecipients | ForEach-Object { $_.emailAddress.address }) -join "; "
                        Subject = $email.subject
                        Status = if ($email.isRead) { "Read" } else { "Unread" }
                    }
                    $allEmails += $emailData
                }
                
                # Add delay between page requests
                Start-Sleep -Seconds $pageRequestDelay
            }
            catch {
                $currentAttempt++
                $statusCode = $_.Exception.Response.StatusCode.value__
                
                if ($currentAttempt -ge $retryMaxAttempts -or $statusCode -notin @(429, 503)) {
                    Write-Warning "Permanent failure processing $userId : $_"
                    $success = $true # Force exit loop
                    break
                }
                
                $delay = [math]::Pow($retryBaseDelay, $currentAttempt)
                Write-Warning "Attempt $currentAttempt failed for $userId. Retrying in $delay seconds..."
                Start-Sleep -Seconds $delay
            }
        } while (-not $success)
        
        $nextLink = $emails.'@odata.nextLink'
    }
}

$allEmails | Format-Table -AutoSize
