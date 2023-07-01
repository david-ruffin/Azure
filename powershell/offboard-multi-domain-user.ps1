 # Import the Active Directory module
Import-Module ActiveDirectory

# Define the user to search for
$userToSearch = "vruffin@ocvibe.com"

# Define the child domains
$childDomains = @("arena.hsventures.org", "skate.hsventures.org", "home.hsventures.org", "corp.hsventures.org")

# Loop through each child domain
foreach ($domain in $childDomains) {
    # Define the LDAP path to the 'Accounts' OU in the child domain
    $ldapPath = "LDAP://OU=Accounts,DC=" + $domain.Replace(".", ",DC=")

    # Create a new DirectoryEntry object for the 'Accounts' OU
    $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath)

    # Create a new DirectorySearcher object
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry)

    # Set the filter to search for the user
    $directorySearcher.Filter = "(&(objectCategory=user)(userPrincipalName=$userToSearch))"

    # Search for the user
    $user = $directorySearcher.FindOne()

    # Check if the user was found
    if ($user -ne $null) {
        # Output the user's distinguished name
        #Write-Output "User '$userToSearch' found in domain '$domain': $($user.Properties.distinguishedname)"

        # Get the user's information using Get-ADUser
        $adUser = Get-ADUser -Identity $user.Properties.samaccountname[0] -Server $domain -Properties *

        # Get the user's Group membership
        $groups = Get-ADPrincipalGroupMembership $adUser | Select-Object @{Name='Active Directory Groups'; Expression={$_.Name}}

        # Break the loop as the user has been found
        break
    } else {
        # Output a message indicating that the user was not found
        Write-Output "User '$userToSearch' not found in domain '$domain'"
    }
}

Write-Host "DisplayName:" $adUser.DisplayName
Write-Host "Company:" $adUser.Company
Write-Host "EmailAddress:" $adUser.EmailAddress
Write-Host "DistinguishedName:" $adUser.DistinguishedName
Write-Host "Domain: $domain"
$groups 
