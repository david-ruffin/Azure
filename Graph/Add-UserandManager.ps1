  <#
.SYNOPSIS
Concise script to create a new Azure AD user and set their manager using Microsoft.Graph.
.NOTES
- Requires Microsoft.Graph module: Install-Module Microsoft.Graph -Scope CurrentUser
- Requires connection: Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
- Assumes manager UPN is correct and exists. Basic error checks included.
#>

# --- User and Manager Details ---
$managerDisplayName = "Bob Marley"# <-- REPLACE with ACTUAL manager Display Name

$newUserParams = @{
    GivenName             = "Sean"
    Surname               = "Carter"
    DisplayName           = "Sean Carter"
    UserPrincipalName     = "Sean.Carter@contoso.com" # Double-check this UPN
    JobTitle              = "Sr. Systems Engineer"
    PostalCode            = "90045"
    State                 = "CA"
    City                  = "Commerce"
    StreetAddress         = "123 Elm Street"
    CompanyName           = "Contoso"
    Department            = "Engineering"
    MobilePhone           = "1234567890"
    AccountEnabled        = $true
    MailNickname          = "SeanCarter" # Adjust if needed (often derived from UPN)
    UsageLocation       = "US" # Required for licensing - uncomment and set if needed
    PasswordProfile       = @{
        Password                             = 'SecurePassword123!' # Consider better password handling
        ForceChangePasswordNextSignIn        = $true
        ForceChangePasswordNextSignInWithMfa = $false
    }
}

# --- Check if user already exists ---

try {
    Write-Host "Checking if user '$($newUserParams.UserPrincipalName)' already exists..."
    $existingUser = Get-MgUser -Filter "UserPrincipalName eq '$($newUserParams.UserPrincipalName)'" -ErrorAction Stop
    if ($existingUser) {
        Write-Host "User '$($newUserParams.UserPrincipalName)' already exists. Exiting." -ForegroundColor Yellow
        return
    }
} catch {
    Write-Host "Error checking if user exists: $($_.Exception.Message)" -ForegroundColor Yellow
    # Continue execution as this is just a check
}

# --- Create User ---
$newUser = $null
try {
    Write-Host "Creating user '$($newUserParams.UserPrincipalName)'..."
    $newUser = New-MgUser @newUserParams -ErrorAction Stop
    Write-Host "Successfully created user '$($newUser.DisplayName)' (ID: $($newUser.Id))" -ForegroundColor Green
} catch {
    Write-Error "Failed to create user '$($newUserParams.UserPrincipalName)'. Error: $($_.Exception.Message)"
    # Exit if user creation fails
    return
}

# Find Manager
$managerUser = $null
$managerResults = Get-MgUser -Filter "DisplayName eq '$managerDisplayName'" -Select Id,UserPrincipalName | Where-Object {$_.UserPrincipalName -like "*@fdhaero.com"}

if ($managerResults.Count -eq 1) {
    $managerUser = $managerResults
    Write-Host "Found manager: $($managerUser.UserPrincipalName) (ID: $($managerUser.Id))" -ForegroundColor Green
} else {
    Write-Host "Manager '$managerDisplayName' not found or multiple matches found. Skipping manager assignment." -ForegroundColor Yellow
}

# --- Set Manager (if found and user created) ---
if ($newUser -and $managerUser) {
    try {
        Write-Host "Setting manager for '$($newUser.DisplayName)' to '$managerDisplayName'..."
        
        # Create the manager reference using odata format exactly as shown in the docs
        $managerReference = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($managerUser.Id)"
        }
        
        # Set the manager using Set-MgUserManagerByRef
        Set-MgUserManagerByRef -UserId $newUser.Id -BodyParameter $managerReference -ErrorAction Stop
        Write-Host "Successfully set manager for '$($newUser.DisplayName)'" -ForegroundColor Green
    } catch {
        Write-Host "Failed to set manager for '$($newUser.DisplayName)'. Error: $($_.Exception.Message)" -ForegroundColor Yellow
        # Note: Not returning/exiting here as this is a non-critical operation
    }
}

Write-Host "Script finished."
