# SharePoint 'Share' URL provided by the user (Replace with the actual URL)
$sharePointUrl = "xxx"

# Client ID, Tenant ID, and Secret for Azure AD Application (Replace with your details)
$clientId = "xxx"
$tenantId = "xxx"
$clientSecret = "xxx"

# Use System.Web.HttpUtility to decode the URL
$decodedUrl = [System.Web.HttpUtility]::UrlDecode($sharePointUrl)

# Extract the part after 'id='
$idParam = $decodedUrl.Split('id=')[1]

# Isolate the folder name, which is before the first '&' character in $idParam
$folderName = $idParam.Split('&')[0].Split('/')[-1]
# Function to acquire Token
function Get-GraphApiToken {
    param (
        $TenantId,
        $ClientId,
        $ClientSecret
    )

    $body = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

    $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body
    return $response.access_token
}

# Acquire Token
$token = Get-GraphApiToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret

# Headers
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

# Function to decode and extract the site component from the SharePoint 'Share' URL
function Parse-SharePointUrlForSite {
    param (
        $Url
    )

    # SharePoint URLs are typically encoded and need to be decoded
    $decodedUrl = [System.Web.HttpUtility]::UrlDecode($Url)

    # Extract the site path from the URL
    # Adjust this regex based on your SharePoint URL format
    $siteUrlPattern = "sites/(.+?)/"
    if ($decodedUrl -match $siteUrlPattern) {
        $siteRelativeUrl = $matches[1]
        return $siteRelativeUrl
    }
    else {
        throw "Unable to parse SharePoint URL for site information"
    }
}

# Parse the SharePoint URL for Site
try {
    $siteRelativeUrl = Parse-SharePointUrlForSite -Url $sharePointUrl
} catch {
    Write-Error "Error parsing SharePoint URL for site: $_"
    return
}

# API Request to get Site ID using the site-relative URL
try {
    $siteResponse = Invoke-RestMethod -Headers $headers -Uri "https://graph.microsoft.com/v1.0/sites/root:/sites/$siteRelativeUrl"
    $siteId = $siteResponse.id
    Write-Output "Site ID: $siteId"
} catch {
    Write-Error "Error retrieving Site ID: $_"
}

# API Request to get Drive ID using the site ID
try {
    $driveResponse = Invoke-RestMethod -Headers $headers -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drive"
    $driveId = $driveResponse.id
    Write-Output "Drive ID: $driveId"
} catch {
    Write-Error "Error retrieving Drive ID: $_"
}

# Define headers
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}



#### needs refinement for folder_id ###
# API Request to list items in the drive
try {
    $apiUrl = "https://graph.microsoft.com/v1.0/drives/$driveId/root/children"
    $response = Invoke-RestMethod -Headers $headers -Uri $apiUrl
    $items = $response.value
} catch {
    Write-Error "Error retrieving items: $_"
    exit
}

try {
    $apiUrl = "https://graph.microsoft.com/v1.0/sites/" + $siteid + "/drives/" + $driveid + "/root:/General/Ticket Strategy/SFTP/Pricemaster/2023-24"
    $response = Invoke-RestMethod -Headers $headers -Uri $apiUrl
    $items = $response
} catch {
    Write-Error "Error retrieving items: $_"
    exit
}

# Search for the object with the name "2023-24"
$folderId = ($items | Where-Object { $_.name -eq $folderName }).Id

# Check if the item was found and output details
Write-Output "Folder ID: $folderId"
