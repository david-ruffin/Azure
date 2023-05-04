# Declare variables
$Username = 'user'
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$vmcreds = New-Object System.Management.Automation.PSCredential $Username, $Password
$viservers = '<vmware-server1>', '<vmware-server2>'
$csvfile = c:\vms.csv
 
# Log into vmware
$viservers | ForEach-Object { connect-viserver -server $_ -credential $vmcreds }
 
# Define the list of VM names that are Windows and powered on
$vmList = Get-VM | Where-Object { $_.PowerState -eq 'PoweredOn' -and $_.Guest.OSFullName -like 'Microsoft Windows*' }
 
# Define the command you want to run
$command = "net localgroup Administrators; hostname"
 
# Create an empty array to store the results
$results = @()
 
# Loop through the list of VM names and run the command for each VM
foreach ($vmName in $vmList) {
    $scriptResult = Invoke-VMScript -VM $vmName -GuestCredential $vmcreds -ScriptText $command -ScriptType Powershell
 
    # Process the output
    $scriptOutput = $scriptResult.ScriptOutput -split "`r`n" | Where-Object { $_.Trim() -ne "" }
    $hostname = $scriptOutput | Select-Object -Last 1
    $adminMembers = ($scriptOutput | Select-Object -Skip 4 | Select-Object -SkipLast 2) -join ", "
    $vmhost = (Get-VM $vmName | Get-VMHost).Name
 
    # Create a custom object with the output information
    $outputObject = [PSCustomObject]@{
        VMName                 = $vmName
        Hostname               = $hostname
        LocalAdminGroupMembers = $adminMembers
        VMHost                 = $vmhost
    }
     
    # Add the output object to the results array
    $results += $outputObject
}
# Display the output object
$results 
$results | Export-Csv -Path $csvfile -NoTypeInformation -Append -Force

Disconnect-VIServer -Server * -Confirm:$false
