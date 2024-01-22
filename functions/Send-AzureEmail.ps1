function Send-AzureEmail {
    <#
    .SYNOPSIS
    Send an email using Azure and Microsoft Graph.

    .DESCRIPTION
    This function sends an email through Azure using Microsoft Graph. It includes the capability to send emails to multiple recipients and CCs, with an optional HTML body and attachments.

    .PARAMETER TenantId
    The Tenant ID for Azure authentication.

    .PARAMETER ClientId
    The Client ID for Azure authentication.

    .PARAMETER ClientSecret
    The Client Secret for Azure authentication.

    .PARAMETER EmailSender
    The sender's email address.

    .PARAMETER EmailRecipient
    Array of recipient email addresses.

    .PARAMETER Cc
    Array of CC email addresses.

    .PARAMETER EmailSubject
    Subject of the email.

    .PARAMETER HtmlBody
    HTML body of the email.

    .PARAMETER Attachments
    Array of file paths for attachments.

    .EXAMPLE
    Send-AzureEmail -TenantId 'xxx' -ClientId 'xxx' -ClientSecret 'xxx' -EmailSender 'sender@example.com' -EmailRecipient @('recipient@example.com') -Cc @('cc@example.com') -EmailSubject 'Subject' -HtmlBody '<html>...</html>'

    .NOTES
    Requires MSAL.PS, Mailozaurr, and PSWriteHTML modules.
    #>

    param (
        [Parameter(Mandatory=$true)]
        [string]$TenantId,

        [Parameter(Mandatory=$true)]
        [string]$ClientId,

        [Parameter(Mandatory=$true)]
        [string]$ClientSecret,

        [Parameter(Mandatory=$true)]
        [string]$EmailSender,

        [Parameter(Mandatory=$true)]
        [string[]]$EmailRecipient,

        [string[]]$Cc,

        [Parameter(Mandatory=$true)]
        [string]$EmailSubject,

        [string]$HtmlBody,

        [string[]]$Attachments
    )

    # Ensure necessary modules are installed
    Install-Module MSAL.PS -Scope CurrentUser -Force | Out-Null
    Install-Module Mailozaurr -Force | Out-Null
    Install-Module PSWriteHTML -Force | Out-Null

    # Authenticate and get access token
    $MsalToken = Get-MsalToken -TenantId $TenantId -ClientId $ClientId -ClientSecret ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
    $Credential = ConvertTo-GraphCredential -MsalToken $MsalToken.AccessToken

    # Email sending logic with retry
    $retryCount = 0
    $retryMax = 5
    while ($retryCount -lt $retryMax) {
        $result = Send-EmailMessage -From $EmailSender -To $EmailRecipient -Cc $Cc -Credential $Credential -HTML $HtmlBody -Subject $EmailSubject -Graph -DoNotSaveToSentItems -Attachments $Attachments -Verbose -ErrorAction SilentlyContinue
        if ($result.Status) {
            Write-Host "Email sent successfully."
            break
        } else {
            $retryCount++
            Write-Host "Failed to send email. Attempt: $retryCount"
            Start-Sleep -Seconds 5
        }
    }
    if ($retryCount -eq $retryMax) {
        Write-Host "Failed to send email after $retryMax attempts."
    }
}
