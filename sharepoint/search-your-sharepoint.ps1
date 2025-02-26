# Configuration
$clientId = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_CLIENT_SECRET"
$tenantId = "YOUR_TENANT_ID"
$sharepointSiteUrl = "https://contoso.sharepoint.com/sites/Operations"
$sharepointLibrary = "Documents"  # Or whatever library name you're targeting

# Get access token
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$tokenBody = @{
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}

$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $tokenBody
$accessToken = $tokenResponse.access_token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

# Test 1: Verify site exists
$siteUrl = $sharepointSiteUrl -replace "https://[^/]+/", "/"
$graphApiUrl = "https://graph.microsoft.com/v1.0/sites/root:$siteUrl"
try {
    $siteInfo = Invoke-RestMethod -Uri $graphApiUrl -Method GET -Headers $headers
    Write-Host "✅ Site found: $($siteInfo.displayName)" -ForegroundColor Green
    $siteId = $siteInfo.id
} catch {
    Write-Host "❌ Site not found or access denied: $_" -ForegroundColor Red
    exit
}

# Test 2: Check document libraries
$drivesUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/drives"
try {
    $drives = Invoke-RestMethod -Uri $drivesUrl -Method GET -Headers $headers
    Write-Host "Available libraries:" -ForegroundColor Cyan
    $drives.value | ForEach-Object { Write-Host "- $($_.name)" }
    
    $targetDrive = $drives.value | Where-Object { $_.name -eq $sharepointLibrary }
    if ($targetDrive) {
        Write-Host "✅ Library '$sharepointLibrary' found" -ForegroundColor Green
    } else {
        Write-Host "❌ Library '$sharepointLibrary' NOT found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error checking libraries: $_" -ForegroundColor Red
}

# Add after the previous code
Write-Host "Checking for folders in libraries:" -ForegroundColor Cyan
foreach ($drive in $drives.value) {
    Write-Host "Folders in '$($drive.name)':" -ForegroundColor Yellow
    $foldersUrl = "https://graph.microsoft.com/v1.0/drives/$($drive.id)/root/children"
    try {
        $items = Invoke-RestMethod -Uri $foldersUrl -Method GET -Headers $headers
        $folders = $items.value | Where-Object { $_.folder -ne $null }
        foreach ($folder in $folders) {
            Write-Host "- $($folder.name)"
        }
        if ($folders.Count -eq 0) {
            Write-Host "  (No folders found)"
        }
    } catch {
        Write-Host "  Error checking folders: $_" -ForegroundColor Red
    }
}
