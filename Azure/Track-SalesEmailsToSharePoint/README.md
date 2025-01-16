
# Track-SalesEmailsToSharePoint.ps1

## Overview
This PowerShell script retrieves email data for a list of users in a Microsoft 365 environment using the Microsoft Graph API. It compiles the data into a CSV file and uploads the file to a SharePoint document library for further use, such as integration with Power BI.

## Key Features
- **Authentication**: Connects to Microsoft Graph using Azure App Registration credentials.
- **Email Tracking**: Retrieves key email details including:
  - Received date
  - Sent date
  - Sender and recipient addresses
  - Subject
  - Read/unread status
  - Timestamp
- **Data Export**: Combines all email data into a single CSV file.
- **SharePoint Upload**: Automatically uploads the generated CSV to a specified SharePoint document library.

## Use Cases
- Weekly tracking of sales team email activity.
- Automating report generation for integration with Power BI.
- Monitoring email responsiveness and communication trends.

## Prerequisites
1. **Azure App Registration**:
   - Create an app registration in Azure with `Mail.Read` permission.
   - Generate a client secret and note the client ID, tenant ID, and client secret.
2. **PowerShell Modules**:
   - Install the following modules:
     ```powershell
     Install-Module Microsoft.Graph -Scope CurrentUser -Force
     Install-Module PnP.PowerShell -Scope CurrentUser -Force
     ```
3. **Access**:
   - Ensure permissions to the target SharePoint site and document library.
4. **User List**:
   - Prepare a list of sales team email addresses to track.

## How It Works
1. Authenticates to Microsoft Graph using client credentials.
2. Iterates through a list of users and retrieves email data for each.
3. Exports the combined email data to a CSV file.
4. Connects to SharePoint and uploads the CSV to the designated document library.

## Script Flow
1. **Authenticate to Microsoft Graph**: Establishes a connection using Azure App credentials.
2. **Fetch Email Data**: Retrieves emails for the defined users.
3. **Compile Data**: Formats and stores the email details in a CSV file.
4. **Upload to SharePoint**: Saves the CSV file to the SharePoint site.

## Best Practices
- Use the principle of least privilege for the Azure App Registration.
- Securely store client secrets (e.g., use Azure Key Vault for production).
- Test the script with a small set of users before scaling.

## Future Enhancements
- Add email filtering options (e.g., keywords or specific folders).
- Implement logging for better monitoring and debugging.
- Integrate error notifications for failed executions.

## Disclaimer
This script is provided "as-is" and should be tested in a non-production environment before deployment.
