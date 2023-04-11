#! /usr/bin/pwsh
param(
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$AccessKey,
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$SecretKey,
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$AzureAppId,
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$AzureTenantId,
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$AzureClientSecret,
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$user,
  [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]$sendEmail
)
# Decalre variables
$DirectoryID = "d-sefsef"
$Region = "us-west-2"
$software = 'C:\IT\installer_vista_win7_win8-64-3.8.0.684.msi'

Import-Module AWSPowerShell
Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs default
Set-DefaultAWSRegion -Region $Region

# Wait for workspace state to be "Available"
while ((Get-WKSWorkspace -Region $Region -UserName $user -DirectoryId $DirectoryID).state -ne "Available") {
  Start-Sleep 20
  Write-Output "still waiting for $user workspace to be in Available state..."
}

# When workspace is ready, edit its attributes
Edit-WKSWorkspaceProperty -WorkspaceId (Get-WKSWorkspace -Region $Region -UserName $user -DirectoryId $DirectoryID).WorkspaceId -Region $Region -WorkspaceProperties_RunningMode AUTO_STOP -WorkspaceProperties_RunningModeAutoStopTimeoutInMinute 60
#Edit-WKSWorkspaceProperty -WorkspaceId (Get-WKSWorkspace -Region $Region -UserName $user -DirectoryId $DirectoryID).WorkspaceId -Region $Region -WorkspaceProperties_RunningMode AlwaysOn

write-output "$user Workspace ready"


if ($sendEmail -eq "yes") {
  Write-Output "Sending email..."
  # Install Microsoft Graph Dependencies to send email
  # Install MSAL.PS module for all users (requires admin rights)
  Install-Module MSAL.PS -Scope CurrentUser -Force
  Install-Module Mailozaurr -Force
  Install-Module PSWriteHTML -Force 
    
  #Generate Access Token to use in the connection string to MSGraph
  $MsalToken = Get-MsalToken -TenantId $AzureTenantId -ClientId $AzureAppId -ClientSecret ($AzureClientSecret | ConvertTo-SecureString -AsPlainText -Force)
 
  #Connect to Graph using access token
  $Credential = ConvertTo-GraphCredential -MsalToken $MsalToken.AccessToken
  # Get Email address
  $email = Invoke-Command -ComputerName 'CONTOSOdc5.contoso.com' -ScriptBlock {
        (Get-ADUser -SearchBase "OU=Employees,DC=CONTOSOWOUNDCARE,DC=com" -filter { enabled -eq $true } | Where-Object { $_.SamAccountName -eq $using:user }).UserPrincipalName
  }
  # Ensure 1st letter in name is upper-case
  $firstname = (Get-Culture).TextInfo.ToTitleCase($email.Split(".")[0])
  # Split email to firstname.lastname as login example
  $name = $email.Split("@")[0]
  # Email Body
  $htmlbody = @"
        <html>
            <body style="font-family:Calibri'cont-size:11">
                Greetings $firstName, <br><br>
                Your AWS workspaces have been provisioned and are ready for use.  Before you access them, you must have your Microsoft MFA configured using notifications to your Authenticator app, <b>not text messages</b>.  If you already have push notifications set up for your MFA, skip to the AWS login instructions below. <br><br>
                <b>Microsoft MFA Setup</b><br><br>
                Go to the Google Play Store or Apple App Store and download the Microsoft Authenticator app.  Then follow the instructions below.<br><br>
                <p style="margin-left: 40px">1. Go to <span style="color:#1E90FF"><a href="https://aka.ms/mfasetup"> https://aka.ms/mfasetup</a></span><br>
                2.      Change <b>Authentication phone</b> to <b> Mobile App </b> and click <b>Set up</b>.</br>
                <img src='cid:awsworkspaceimage1.png'></br>
                3.      Follow the instructions on the pop-up.</br>
                <img src='cid:awsworkspaceimage2.png'></br>
                4.      Click Next and approve the notification you receive on your cell phone through the Authenticator app.</br>
                5.      Complete the rest of the Set-up.</br><br>
                <b>AWS Login Instructions</b><br><br>
                A new Amazon WorkSpace has been provided for you. Follow the steps below to quickly get up and running with your WorkSpace: <br>
                1.  Launch the client and enter the following registration code: <b>awdawd+awdawdZ</b></br>
                2.  Login with your password. Your username is <b>firstname.lastname</b> (e.g., <b>$name</b>)</br><br>
                On the login screen you will be prompted for Username, Password, and MFA Code.  <b>This is misleading.  </b>On the login screen, enter your username, password, and for the MFA code field, <b>enter the number "1." </b>  You will then receive a push notification on your cell phone Authenticator app to approve login.  Once approved, your Workspace will launch. <br><br>
                If you have any issues connecting to your WorkSpace, please contact helpdesk@contoso.com. If you need any modifications made to your new Workspace, please CC your manager for permission.<br></br></p>
                Sincerely,</br></br>
                IT Helpdesk</br>
                <b>Email:</b> helpdesk@contoso.com</br>
                <b>Phone:</b> 123-743-2445</br>
                <b>Hours:</b> M-F, 6:30am-4:30pm PST</br>
            </body>
        </html>
"@
  Write-host "email: $email"
  Write-host "firstname: $firstname"
  Write-Host "User: $user"
  Write-Host "Name: $name"
  Write-Host "Send Email: $sendEmail"
  # Send Email
  Send-EmailMessage -From 'helpdesk@contoso.com' -To $email -Cc 'matmie.shtarp@contoso.com', 'rex.ntle@contoso.com', 'tony.nguyen@contoso.com', 'duncan.jann@contoso.com' -Credential $Credential -HTML $htmlbody  -Subject "Your CONTOSO Workspace Instructions" -Graph -DoNotSaveToSentItems -Attachments "/var/lib/rundeck/dependencies/git-rundeck/awsworkspaceimage1.png", "/var/lib/rundeck/dependencies/git-rundeck/awsworkspaceimage2.png" | out-null

}

# Final step to install carbon black
# Get Workspace name
$hostname = (Get-WKSWorkspace -Region $Region -UserName $user -DirectoryId $DirectoryID).computerName

Write-host "The AWS Workspace name is $hostname"
$installed = $false
while ($installed -eq $false) {
  # Try to resolve the hostname
  try {
    $ip = [System.Net.Dns]::GetHostAddresses($hostname)
  }
  catch {
    Write-Host "Waiting for AWS Workspace $hostname to resolve..."
    $ip = $null
  }
  
  # If hostname resolves, proceed with checking if host is online and installing software
  if ($ip) {
    Write-host "AWS Workspace hostname resolved"
    # Check if host is online by pinging it
    Write-host "Checking to see if AWS Workspace $hostname is online"
    $ping = new-object System.Net.NetworkInformation.Ping
    $reply = $ping.Send($hostname)
    if ($reply.Status -eq "Success") {
      Write-Host "AWS Workspace $hostname is online"
      # Install software
      Write-Host "Installing carbon black on AWS Workspace $hostname"
      $command = {
        write-host "Installing carbon black"
        Start-Process -Wait -FilePath 'C:\IT\installer_vista_win7_win8-64-3.8.0.684.msi' -ArgumentList '/qn /norestart COMPANY_CODE=TZ725OTDWDCT4NOSD6Z POLICY_NAME=AWS' -PassThru -WorkingDirectory 'C:\IT\'
        sleep 10
        write-host "Confirming Carbon Black installed"
        if ((Get-Service -Name 'CbDefense') -and (Get-Service -Name 'CbDefense').status -eq 'Running') {
          Write-Host 'Success: Carbon Black is installed and the service "CbDefense" is Running'
        }
        else {
          Write-Host 'Error: the Carbon Black service "CbDefense" is not running. It may not be installed correctly.'
        }
      }
      $Job = Invoke-Command -ComputerName $hostname -ScriptBlock $command -ErrorAction Stop -AsJob 
      Wait-Job -Job $Job | out-null
      
      # Exit loop
    #if (($job.ChildJobs[0].Information[2]) -eq 'Success: Carbon Black is installed and the service "CbDefense" is Running'){
    #Write-host "Carbon Black installed"}
    Edit-WKSWorkspaceProperty -WorkspaceId (Get-WKSWorkspace -Region $Region -UserName $user -DirectoryId $DirectoryID).WorkspaceId -Region $Region -WorkspaceProperties_RunningMode AUTO_STOP -WorkspaceProperties_RunningModeAutoStopTimeoutInMinute 60

    $installed = $true
    }else{
      Write-Host "Carbon black is not installed because $hostname is offline"
      $installed = $true
    }
  }
  
  # Wait for one minute before checking again
  Start-Sleep -Seconds 60
}
