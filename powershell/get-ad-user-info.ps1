 # Import the Active Directory module
Import-Module ActiveDirectory

# Specify the username
$username = "david.ruffin"

# Get the user
$user = Get-ADUser -Identity $username -Properties Name, SamAccountName, UserPrincipalName

Write-Output "### On Premise Active Directory Settings ###"

# Output the user's Name, SamAccountName, and UserPrincipalName
Write-Output "Name: $($user.Name)"
Write-Output "SamAccountName: $($user.SamAccountName)"
Write-Output "UserPrincipalName: $($user.UserPrincipalName)"

# Get the user's group membership
$groups = Get-ADPrincipalGroupMembership -Identity $username | Select-Object -ExpandProperty Name

# Output the user's group membership
Write-Output ""
Write-Output "Group Membership:"
Write-Output ""
$groups | sort 
