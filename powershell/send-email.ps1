$firstName = (Get-Culture).TextInfo.ToTitleCase($firstName)
# Start
$date = Get-Date -UFormat "%m/%d/%Y"
$htmlbody = @" 
        <html>
            <body style="font-family:Calibri'cont-size:11"> 
                <b>From:</b> IT Helpdesk</br>
                <b>Date:</b> $date </br></br>
                
                Greetings $firstName, <br><br>
                
                Your AWS workspaces have been provisioned and are ready for use.  Before you access them, you must have your Microsoft MFA configured using notifications to your Authenticator app, <b>not text messages</b>.  If you already have push notifications set up for your MFA, skip to the AWS login instructions below. <br><br>
                
                <b>Microsoft MFA Setup</b><br><br>
                
                Go to the Google Play Store or Apple App Store and download the Microsoft Authenticator app.  Then follow the instructions below.<br><br>
                
                <p style="margin-left: 40px">1.	Go to <span style="color:#1E90FF"><a href="url"> https://aka.ms/mfasetup</a></span><br>
                2.	Change <b>Authentication phone</b> to <b> Mobile App </b> and click <b>Set up</b>.</br>
                3.	Follow the instructions on the pop-up.</br>
                4.	Click Next and approve the notification you receive on your cell phone through the Authenticator app.</br>
                5.	Complete the rest of the Set-up.</br><br>

                <b>AWS Login Instructions</b><br><br>
                
                A new Amazon WorkSpace has been provided for you. Follow the steps below to quickly get up and running with your WorkSpace: <br>

                <p style="margin-left: 40px">1.	Download and install a WorkSpaces Client for your favorite devices: <span style="color:#1E90FF"><a href="url"> https://clients.amazonworkspaces.com/</a></span><br>

                2.  Launch the client and enter the following registration code: <b>WSpdx+FKWX4B</b></br>
                3.  Login with your password. Your username is <b>firstname.lastname</b></br><br>
                
                
                On the login screen you will be prompted for Username, Password, and MFA Code.  <b>This is misleading.  </b>On the login screen, enter your username, password, and for the MFA code field, <b>enter the number "1." </b>  You will then receive a push notification on your cell phone Authenticator app to approve login.  Once approved, your Workspace will launch. <br><br>
                
                If you have any issues connecting to your WorkSpace, please contact helpdesk@amtwoundcare.com. If you need any modifications made to your new Workspace, please CC your manager for permission.<br></br></p>

                Sincerely,</br></br>

                IT Helpdesk</br>
                <b>Email:</b> helpdesk@contoso.com</br>
                <b>Phone:</b> 949-213-2515</br>
                <b>Hours:</b> M-F, 6:30am-4:30pm PST</br>
            </body>
        </html>
"@

Send-MailMessage -from $helpdeskEmail -To david.ruffin@amtwoundcare.com -Subject "Welcome to AMT" -BodyAsHtml "$htmlbody" -SmtpServer amtsmtpr01.amtwoundcare.com -Port 25

Write-Host "Email successfully sent."

Write-Host "Personal Email: $personalEmail"
Write-Host "AMT Email: $amtEmail"
Write-Host "Password: $password"
Write-Host "Start Date: $startDate"
Write-Host "Manager Email: $managerEmail"
