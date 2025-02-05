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



##### Provide a CSV ####
# Import the CSV file; make sure it has a column named "UserPrincipalName".
$usersFromCsv = Import-Csv -Path "no-mfa-short.csv"

# Process each user and collect results.
$results = foreach ($user in $usersFromCsv) {
    $upn = $user.UserPrincipalName
    Write-Host "Processing UPN: $upn"
    
    # Retrieve the user using a filter on userPrincipalName.
    $graphUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -Property "displayName,userPrincipalName,signInActivity,accountEnabled" | Select-Object -First 1

    if ($graphUser) {
        [PSCustomObject]@{
            DisplayName       = $graphUser.displayName
            UserPrincipalName = $graphUser.userPrincipalName
            AccountStatus     = if ($graphUser.accountEnabled) { "Enabled" } else { "Disabled" }
            LastSignInDate    = $graphUser.signInActivity?.LastSignInDateTime
        }
    }
    else {
        Write-Warning "User not found: $upn"
    }
}

# Display the collected results in a formatted table.
$results | Format-Table -AutoSize
