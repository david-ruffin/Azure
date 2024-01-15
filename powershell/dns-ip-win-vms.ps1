# List all windows vms with their 2nd dns ip
$guestUser = 'xxx'
$guestPassword = 'xxx'

# Initialize an array to store VM info
$vmInfo = @()

# Get all Windows VMs
$vms = Get-VM | Where-Object {$_.Guest.OSFullName -like "*Windows*"} 

foreach ($vm in $vms) {
    # Run the hostname command inside the VM
    $hostnameScript = {hostname}
    $hostnameOutput = Invoke-VMScript -VM $vm -ScriptText $hostnameScript -GuestUser $guestUser -GuestPassword $guestPassword -ScriptType Powershell

    # Get DNS server addresses inside the VM
    $dnsScript = {
        Get-DnsClientServerAddress -AddressFamily IPv4 | 
        Where-Object {$_.InterfaceAlias -like "Ethernet*"} | 
        Select-Object -ExpandProperty ServerAddresses
    }
    $dnsOutput = Invoke-VMScript -VM $vm -ScriptText $dnsScript -GuestUser $guestUser -GuestPassword $guestPassword -ScriptType Powershell

    # Extract the second DNS entry
    $secondDnsEntry = $dnsOutput.ScriptOutput.Split("`n")[1].Trim()

    # Create a custom object and add it to the array
    $vmDetails = New-Object PSObject -Property @{
        VMName = $vm.Name
        Hostname = $hostnameOutput.ScriptOutput.Trim()
        SecondDNSEntry = $secondDnsEntry
    }

    $vmInfo += $vmDetails
}

# $vmInfo now contains the information of each VM
$vmInfo
