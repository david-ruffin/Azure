<#
Script Overview: Email Tracking and SharePoint Upload

Description:
This script retrieves email data for a list of users in a Microsoft 365 environment using the Microsoft Graph API. 
It compiles the data into a CSV file and uploads the file to a SharePoint document library for further use, such as integration with Power BI.

Key Functionality:
1. Authenticate to Microsoft Graph:
   - Uses client credentials (client ID, tenant ID, and client secret) to connect to the Microsoft Graph API.
   - Requires prior setup of an Azure App Registration with the necessary permissions (Mail.Read).

2. Fetch Email Data:
   - Iterates through a predefined list of users (email addresses).
   - Retrieves up to 50 emails per user with the following details:
     - Received date
     - Sent date
     - Sender address
     - Recipient addresses
     - Subject
     - Read/unread status
     - Timestamp (added during script execution for tracking purposes).

3. Compile Data:
   - Combines email data for all users into a single dataset.
   - Exports the data to a CSV file for further processing or archiving.

4. Upload to SharePoint:
   - Connects to a specified SharePoint site using PnP.PowerShell.
   - Uploads the generated CSV file to a designated document library.

5. Logging and Cleanup:
   - Provides real-time status messages in the PowerShell console for transparency.
   - Disconnects from Microsoft Graph and SharePoint after operations are complete.

Use Cases:
- Weekly tracking of sales team email activity.
- Automating report generation for integration with Power BI.
- Monitoring email responsiveness and communication trends.

Best Practices:
- Ensure the Azure App Registration follows the principle of least privilege (only Mail.Read permission).
- Store sensitive information like client secrets securely (consider using Azure Key Vault for production environments).
- Validate the list of users and test with a small subset before scaling.

Pre-requisites:
- The Azure App Registration is set up and properly configured (refer to "Pre-Steps for the Script" section above).
- Required PowerShell modules (Microsoft.Graph and PnP.PowerShell) are installed.
- Access to the target SharePoint site with permissions to upload files to the specified document library.

Pre-Steps for the Script

1. Create an App Registration in Azure:
   - Go to the Azure Portal → Azure Active Directory → App registrations → New registration.
   - Provide a name for the app (e.g., "EmailTrackingApp").
   - Select "Accounts in this organizational directory only" as the supported account type.
   - Click "Register".

2. Assign API Permissions:
   - In the App Registration page, navigate to API permissions → Add a permission → Microsoft Graph → Application permissions.
   - Add the following permission:
     - Mail.Read: Allows the app to read all mail in users' mailboxes.
   - Click "Grant admin consent" to approve the permission for your organization.

3. Create Client Credentials:
   - Navigate to Certificates & secrets → New client secret.
   - Add a description (e.g., "EmailTrackingSecret") and set an expiration (e.g., 6 months, 1 year).
   - Click "Add" and copy the **Value** of the client secret. 
     Save this securely, as it won't be shown again.

4. Gather Required Details:
   - From the App Registration overview page, note down the following:
     - Application (client) ID: This is your $clientId.
     - Directory (tenant) ID: This is your $tenantId.

5. Ensure Necessary Azure AD Permissions:
   - Confirm that the account running the script has the **Application Administrator** or equivalent role in Azure AD 
     to create and manage app registrations.
#>

# Define credentials
$ClientId = ""
$TenantId = ""
$ClientSecret = ""
$UserId = ""

Install-Module MSAL.PS -Scope CurrentUser -Force | Out-Null
Install-Module Mailozaurr -Force | Out-Null
Install-Module PSWriteHTML -Force | Out-Null
install-module Microsoft.Graph.Mail -Force | Out-Null
Install-Module Microsoft.Graph -Force | Out-Null
Install-Module Microsoft.Graph.Mail -Force | Out-Null
Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Mail

$clientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)
Connect-MgGraph -NoWelcome -ClientSecretCredential $credential -TenantId $tenantId

# Fetch Emails for Test User
$emails = Get-MgUserMessage -UserId $UserId -Top 10 -Select ReceivedDateTime, SentDateTime, From, ToRecipients, Subject, IsRead

# Display Email Data in PowerShell
foreach ($email in $emails) {
    $receivedDate = $email.ReceivedDateTime
    $sentDate = $email.SentDateTime
    $senderAddress = $email.From.EmailAddress.Address

    # Handle null or empty ToRecipients gracefully
    if ($email.ToRecipients -and $email.ToRecipients.Count -gt 0) {
        $recipientAddresses = ($email.ToRecipients | ForEach-Object { $_.EmailAddress.Address }) -join "; "
    } else {
        $recipientAddresses = "N/A"
    }

    $subject = $email.Subject
    $status = if ($email.IsRead) { "Read" } else { "Unread" }
    $timeStamp = Get-Date

    # Print results
    Write-Output "Received: $receivedDate, Sent: $sentDate, From: $senderAddress, To: $recipientAddresses, Subject: $subject, Status: $status, TimeStamp: $timeStamp"
}
