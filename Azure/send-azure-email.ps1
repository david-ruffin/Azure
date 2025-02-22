# Define Variables
$TenantId = "wwefwef"
$ClientId = "wefwef"
$ClientSecret = "wef" 
$email = "david@contoso.com"
$fromEmail = "david@contoso.com"
$cc = "david@contoso.com"
$subject = "Test Subject"
          
Install-Module MSAL.PS -Scope CurrentUser -Force | Out-Null
Install-Module Mailozaurr -Force | Out-Null
Install-Module PSWriteHTML -Force | Out-Null

# Generate Access Token to use in the connection string to MSGraph
$MsalToken = Get-MsalToken -TenantId $TenantId -ClientId $ClientId -ClientSecret ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)


$firstName = "David"
$name = "david.james"
#Connect to Graph using access token
$Credential = ConvertTo-GraphCredential -MsalToken $MsalToken.AccessToken
$htmlbody = @"
<html>
    <body style="font-family:Calibri'cont-size:11">
        Greetings $firstName, <br><br>

        Congratulations!  You have been assigned a new AWS WorkSpace!  Please open and carefully read the attached instructions to access your newly provisioned AWS WorkSpace. <br><br>

        <b>ATTACHMENT #1: 01-Microsoft Authenticator - Login & Setup Instructions v2</b><br>
        <ul>

        <li> You MUST have your <u>Microsoft Authenticator App </u> configured and set as the default sign-in method before you can log in.</a></span><br></li>
        <li> <i> (Note: You may have already completed this step.) </i></b>.</br><br></li></ul></p>

        <b>ATTACHMENT #2: 02-AWS WorkSpaces - Login Instructions</b><br>
        <ul>
        <li>Follow these instructions to log into your AWS WorkSpace.</i> 
        <li>On <b>PAGE 4</b>, the <u>Registration Code</u> is: <b><FONT COLOR="#ff0000">WSpdx+A6JMTZ</FONT></b></i> 
        <li>On <b>PAGE 5</b>:</i> 
            <ul>
            <li><b>Username</b>: firstname.lastname (e.g., $name)</i> 
            <li><b>Password</b>: (The same password to log into your computer)</i>
            <li><b>MFA Code</b>: Enter the number "1"</i></ul>
            <li>Once you successfully log into your AWS Workspace, you may  log out/close it. <u><b>Please continue to work in your normal remote desktop until further notice.</u></b></i>

        </ul>
        <br></br>


        You may contact the IT Helpdesk if you experience any issues with your AWS WorkSpace.</br></br>

        <b>Email:</b> support@contoso.com</br>
        <b>Phone:</b> 123-743-2515</br>
        <b>Hours:</b> M-F, 6:30am-4:30pm PST</br>

    </body>
</html>
"@
# Send Email
Send-EmailMessage -From $fromemail -To $email -Cc $cc -Credential $Credential -HTML $htmlbody  -Subject $subject -Graph -DoNotSaveToSentItems  
