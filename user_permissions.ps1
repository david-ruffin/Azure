$userEmail = "user@contoso.com"

# Create filename with username (replace @ and . for valid filename)
$safeUsername = $userEmail.Replace("@", "_").Replace(".", "_")
$exportPath = "UserPermissionsAudit_${safeUsername}_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$allPermissions = @()

Write-Host "Auditing permissions for: $userEmail" -ForegroundColor Yellow

# 1. AZURE RBAC ROLES ACROSS ALL SUBSCRIPTIONS
Write-Host "Checking Azure RBAC roles..." -ForegroundColor Green
$subscriptions = Get-AzSubscription

foreach ($sub in $subscriptions) {
    Write-Host "  Checking subscription: $($sub.Name)" -ForegroundColor Gray
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    
    # Get all role assignments
    $allAssignments = Get-AzRoleAssignment
    
    # Filter for user (direct and via groups)
    $userAssignments = $allAssignments | Where-Object {
        $_.SignInName -eq $userEmail -or 
        $_.ObjectType -eq "User" -and $_.DisplayName -eq $userEmail
    }
    
    foreach ($assignment in $userAssignments) {
        $allPermissions += [PSCustomObject]@{
            UserAccount = $userEmail  # Added this line
            Type = "Azure RBAC"
            Resource = $sub.Name
            Permission = $assignment.RoleDefinitionName
            Scope = $assignment.Scope
            Via = "Direct"
            ObjectId = $assignment.ObjectId
            AssignmentId = $assignment.RoleAssignmentId
        }
    }
    
    # Check group-based permissions
    $context = Get-AzContext
    $token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
    $headers = @{
        'Authorization' = "Bearer $($token.Token)"
        'Content-Type' = 'application/json'
    }
    
    # Get user's groups
    try {
        $userResponse = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userPrincipalName eq '$userEmail'" -Headers $headers -Method Get
        if ($userResponse.value.Count -gt 0) {
            $userId = $userResponse.value[0].id
            $groupsResponse = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$userId/memberOf" -Headers $headers -Method Get
            
            $userGroups = $groupsResponse.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' }
            
            foreach ($group in $userGroups) {
                $groupAssignments = $allAssignments | Where-Object { $_.ObjectId -eq $group.id }
                foreach ($assignment in $groupAssignments) {
                    $allPermissions += [PSCustomObject]@{
                        UserAccount = $userEmail  # Added this line
                        Type = "Azure RBAC (via Group)"
                        Resource = $sub.Name
                        Permission = $assignment.RoleDefinitionName
                        Scope = $assignment.Scope
                        Via = "Group: $($group.displayName)"
                        ObjectId = $assignment.ObjectId
                        AssignmentId = $assignment.RoleAssignmentId
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Could not retrieve group memberships: $_"
    }
}

# 2. GET DIRECTORY ROLES AND APP ASSIGNMENTS VIA REST API
Write-Host "Checking directory roles and app assignments..." -ForegroundColor Green
try {
    $token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
    $headers = @{
        'Authorization' = "Bearer $($token.Token)"
        'Content-Type' = 'application/json'
    }
    
    # Get user
    $userResponse = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users?`$filter=userPrincipalName eq '$userEmail'" -Headers $headers -Method Get
    if ($userResponse.value.Count -eq 0) {
        Write-Error "User not found in directory"
    }
    else {
        $userId = $userResponse.value[0].id
        
        # Get directory roles
        $rolesUri = "https://graph.microsoft.com/v1.0/users/$userId/memberOf"
        $rolesResponse = Invoke-RestMethod -Uri $rolesUri -Headers $headers -Method Get
        
        foreach ($item in $rolesResponse.value) {
            if ($item.'@odata.type' -eq '#microsoft.graph.directoryRole') {
                $allPermissions += [PSCustomObject]@{
                    UserAccount = $userEmail  # Added this line
                    Type = "Directory Role"
                    Resource = "Entra ID"
                    Permission = $item.displayName
                    Scope = "Tenant"
                    Via = "Direct"
                    ObjectId = $item.id
                    AssignmentId = ""
                }
            }
            elseif ($item.'@odata.type' -eq '#microsoft.graph.group') {
                $allPermissions += [PSCustomObject]@{
                    UserAccount = $userEmail  # Added this line
                    Type = "Group Membership"
                    Resource = "Entra ID"
                    Permission = $item.displayName
                    Scope = "Group"
                    Via = "Member"
                    ObjectId = $item.id
                    AssignmentId = ""
                }
            }
        }
        
        # Get app role assignments
        $appUri = "https://graph.microsoft.com/v1.0/users/$userId/appRoleAssignments"
        try {
            $appResponse = Invoke-RestMethod -Uri $appUri -Headers $headers -Method Get
            foreach ($app in $appResponse.value) {
                $allPermissions += [PSCustomObject]@{
                    UserAccount = $userEmail  # Added this line
                    Type = "Enterprise App"
                    Resource = $app.resourceDisplayName
                    Permission = "Assigned"
                    Scope = "Application"
                    Via = "Direct"
                    ObjectId = $app.resourceId
                    AssignmentId = $app.id
                }
            }
        }
        catch {
            Write-Warning "Could not retrieve app assignments: $_"
        }
    }
}
catch {
    Write-Warning "Error accessing directory information: $_"
}

# Export results
$allPermissions | Export-Csv -Path $exportPath -NoTypeInformation

# Display summary
Write-Host "`nPermission Summary for $userEmail :" -ForegroundColor Yellow
$allPermissions | Group-Object Type | ForEach-Object {
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor Cyan
}

