# This will log into Azure, and check vm "VM-LaserficheApp-Prod-westus-01" for all its drives. If any drive is over 80% full, it will send results via email
# Login to azure
$Username = 'rundeck_svc@amtwoundcare.com'
$Password = ConvertTo-SecureString 'tdfNJxg3NT6?' -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential $Username, $Password
Connect-AzAccount -Credential $Credentials | Out-Null
# Select subscription
Set-AzContext -Subscription "sub-prod"
# Check space on vm drives
$command = Invoke-AzVmRunCommand `
     -ResourceGroupName "rg-prod-westus-laserfiche-001" `
     -VMName "VM-LaserficheApp-Prod-westus-01" `
     -CommandId "RunPowerShellScript" `
     -ScriptPath "Get-DriveSpace.ps1"
# If space is less than 20% send email
if (($command[0].Value.message) -ne ""){
$s=$command.Value[0].Message 
$bodyArray=$s | ConvertFrom-Csv

$body += "<body><table width=""560"" border=""1""><tr>"
$bodyArray[0] | ForEach-Object {
foreach ($property in $_.PSObject.Properties){$body += "<td>$($property.name)</td>"}
} 
$body += "</tr><tr>"
$bodyArray | ForEach-Object {
foreach ($property in $_.PSObject.Properties){$body += "<td>$($property.value)</td>"}
$body += "</tr><tr>"
}
$body += "</tr></table></body>"
# Send email
Send-MailMessage -From "sysadmins@amtwoundcare.com" -To "david.ruffin@amtwoundcare.com", "jaren.thorsen@amtwoundcare.com" -Subject "AMTLF1 drivespace less than 20% - daily report" -Body $body  -BodyAsHtml -Priority High -DeliveryNotificationOption OnFailure -SmtpServer "amtsmtpr01.amtwoundcare.com" -port 25
}
# Disconnect from Azure
Disconnect-AzAccount | Out-Null
