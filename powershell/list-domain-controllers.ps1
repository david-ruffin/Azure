 # Get the forest
$forest = Get-ADForest

# Loop through each domain in the forest
foreach ($domain in $forest.Domains) {
    # Get the domain controllers for the domain
    $dcs = Get-ADDomainController -Filter * -Server $domain

    # Print the domain name and the names of the domain controllers
    Write-Output "Domain: $domain"
    foreach ($dc in $dcs) {
        Write-Output "  Domain Controller: $($dc.HostName)"
    }
}
 
