# Ensure the Microsoft Graph Users module is installed; if not, uncomment the next line to install it.
# Install-Module Microsoft.Graph.Users -Force

# Connect to Microsoft Graph with the necessary scope.
Connect-MgGraph -Scopes "User.Read.All"

# Retrieve all users including displayName, userPrincipalName, signInActivity, and accountEnabled.
$users = Get-MgUser -All -Property "displayName,userPrincipalName,signInActivity,accountEnabled"

# Display users with their DisplayName, UserPrincipalName, Account Status, and LastLoginDate.
$users | Select-Object `
    displayName, `
    userPrincipalName, `
    @{Name="AccountStatus"; Expression = { if ($_.accountEnabled) { "Enabled" } else { "Disabled" } } }, `
    @{Name="LastLoginDate"; Expression = { $_.signInActivity?.LastSignInDateTime } } | 
    Format-Table -AutoSize
