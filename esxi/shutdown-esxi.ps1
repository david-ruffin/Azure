$Username = 'username'
$Password = ConvertTo-SecureString 'Password'  -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential $Username, $Password
Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:$false
connect-viserver 192.168.30.5 -Credential $Credentials
$vms = Get-VM | where {$_.PowerState -eq "PoweredOn"}
$vms | foreach {Suspend-VM -VM $_ -Confirm:$false} 
# Place the selected host into Maintenance Mode.
Get-VMHost -Name '192.168.30.5' | set-vmhost -State Maintenance
 
# Shutdown the host
Stop-VMhost -VMhost '192.168.30.5' -Confirm:$false
Disconnect-viserver -Confirm:$false -force
