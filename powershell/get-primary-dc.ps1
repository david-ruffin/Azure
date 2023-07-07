 # Define the child domains
$childDomains = @("subdomain1.acme.org", "subdomain2.acme.org", "subdomain3.acme.org", "subdomain4.acme.org", "acme.org")

# Loop through each child domain
foreach ($domain in $childDomains) {
    # Get the primary domain controller for the current child domain
    $PDC = Get-ADDomainController -Discover -Service PrimaryDC -DomainName $domain

    # Output the name of the primary domain controller for the current child domain
    Write-Output "The PDC for $domain is $($PDC.HostName)"
} 
