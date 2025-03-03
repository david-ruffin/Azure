# This script will install carbon black on AMT Workspace VM
# Log into AWS

# Get Workspace aname
$computerName = Get-AWSWorkspace 'AMTWKSP-T01LDUM'
# Ensure Workspace machine is online

# Install carbon black
$command = {
  Start-Process -Wait -FilePath 'C:\IT\installer_vista_win7_win8-64-3.8.0.684.msi' -ArgumentList '/qn /norestart COMPANY_CODE=TZ725OTDWDCT4NOSD6Z POLICY_NAME=AWS' -PassThru -WorkingDirectory 'C:\IT\'
  }
$job = Invoke-Command -ComputerName $computerName -ScriptBlock $command -ErrorAction Stop -AsJob #-credential $Credentials1
Wait-Job -Job $Job
# Confirm agent installed correctly
