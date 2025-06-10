<#
.SYNOPSIS
    GitHub Repository Migration Tool - Single Repository

.DESCRIPTION
    Migrates a single repository from a source GitHub organization to a destination organization.
    Preserves complete Git history, all branches, tags, and commits.
    Handles GitHub secret detection errors with automatic retry mechanism.

.FEATURES
    - Complete repository clone with all Git history
    - Automatic destination repository creation
    - Handles secret detection with unblock URL extraction
    - Retry mechanism with 10-second intervals
    - Progress messaging with color-coded output
    - Robust error handling and cleanup

.PREREQUISITES
    - GitHub CLI (gh) installed and authenticated
    - Git installed and configured
    - Admin access to both source and destination organizations
    - PowerShell 5.1 or later

.PRESERVES
    - Complete Git history
    - All branches and tags
    - All commits and metadata
    - Repository structure

.DOES NOT PRESERVE
    - Issues and Pull Requests
    - Repository settings and configurations
    - Wikis and Releases
    - Webhooks and integrations
    - Team permissions

.USAGE
    1. Update the organization names and repository name in the variables section
    2. Run the script from PowerShell
    3. If secrets are detected, use the provided URL to resolve them
    4. Script will automatically retry after resolution

.NOTES
    Author: AI Assistant
    Version: 1.0
    The source repository remains unchanged (this is a copy, not a move)
#>

# =============================================================================
# CONFIGURATION - Update these values for your migration
# =============================================================================

# Set specific repository name to migrate
$REPO_NAME = "fdhaero-website"

# Set source organization name
$SOURCE_ORG = "fdhgithub"
# Set destination organization name
$DEST_ORG = "fdh-aero" 


# Get current directory for cleanup
$CURRENT_DIR = Get-Location

# Download complete repository with all branches/tags/history
Write-Host "Cloning $REPO_NAME..."
git clone --mirror "https://github.com/$SOURCE_ORG/$REPO_NAME.git" "$REPO_NAME.git"

# Create new empty repository in destination organization
Write-Host "Creating destination repo..."
gh repo create "$DEST_ORG/$REPO_NAME" --private

# Push to destination from the cloned repo directory
Write-Host "Pushing to destination..."
Push-Location "$REPO_NAME.git"
git remote set-url origin "https://github.com/$DEST_ORG/$REPO_NAME.git"

# Retry loop for handling secret detection
$pushSuccess = $false
$maxRetries = 10
$retryCount = 0

while (-not $pushSuccess -and $retryCount -lt $maxRetries) {
    try {
        # Capture both stdout and stderr
        $result = git push --mirror 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $pushSuccess = $true
            Write-Host "✅ Push successful!"
        } else {
            # Check if it's a secret detection error
            $secretError = $result | Select-String "unblock-secret"
            
            if ($secretError) {
                # Extract the unblock URL
                $unblockUrl = ($secretError -split '\s+' | Where-Object { $_ -like "*unblock-secret*" }).Trim()
                
                Write-Host "🚨 Secret detected! Please resolve at:" -ForegroundColor Yellow
                Write-Host $unblockUrl -ForegroundColor Cyan
                Write-Host "Waiting 10 seconds before retry..." -ForegroundColor Yellow
                
                Start-Sleep -Seconds 10
                $retryCount++
            } else {
                # Different error, stop retrying
                Write-Host "❌ Push failed with different error:" -ForegroundColor Red
                Write-Host $result
                break
            }
        }
    } catch {
        Write-Host "❌ Push failed: $_" -ForegroundColor Red
        break
    }
}

if (-not $pushSuccess) {
    Write-Host "❌ Push failed after $retryCount retries" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Delete the temporary local copy
Write-Host "Cleaning up..."
Remove-Item -Recurse -Force "$REPO_NAME.git"
Write-Host "✅ Migration complete!"
