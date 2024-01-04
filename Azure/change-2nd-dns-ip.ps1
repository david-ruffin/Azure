 # Declare a variable to store the new DNS IP address
$newDNSip = "10.1.50.5"

# Retrieve and display the hostname of the server
$hostname = hostname
Write-Host "Server Hostname: $hostname"

# Retrieve the network adapter that is currently active
$interfaceIndex = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" }).InterfaceIndex

# Obtain the current DNS server addresses for the active network adapter
$dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4).ServerAddresses

# Store the original second DNS server address for display
$originalSecondDns = $dnsServers[1]

# Display the original second DNS IP
Write-Host "1. Original DNS IP: $originalSecondDns"

# Check if there are at least two DNS entries
if ($dnsServers.Count -ge 2) {
    $dnsServers[1] = $newDNSip

    # Apply the updated DNS server addresses to the network interface
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $dnsServers

    # Re-obtain the DNS server addresses to confirm the change
    $dnsServersUpdated = (Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4).ServerAddresses
    $newSecondDns = $dnsServersUpdated[1]

    # Display the new second DNS IP
    Write-Host "2. New DNS IP: $newSecondDns"
} else {
    # Output a message if there are not enough DNS entries to replace the second one
    Write-Host "Not enough DNS entries to replace the second one."
}
 
