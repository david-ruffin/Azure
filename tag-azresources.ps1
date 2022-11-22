# Add this script to the function app in your azure subscription. Make sure to
# 1. Create a function app using Powershell and add this script
param($eventGridEvent, $TriggerMetadata)
Write-Host "##########################################################################################"
Write-Host '## eventGridEvent.json ##'
$eventGridEvent | ConvertTo-Json -depth 100 | Write-Host
$caller = $eventGridEvent.data.claims.name
if ($null -eq $caller) {
    $caller = "AppID " + $eventGridEvent.data.claims.appid
}
if (!($eventGridEvent.data.claims.name)) {
    Write-Host '!!!!!!!!!!!'
    Write-Host "$eventGridEvent.data.claims.appid"
    Write-Host "$caller"
}
$resourceId = $eventGridEvent.data.resourceUri
$date = (Get-Date -Format 'M/d/yyyy')
$time = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( (Get-Date), 'Pacific Standard Time').tostring("hh:mmtt") + ' PST'

Write-Host "Caller: $caller"
Write-Host "ResourceId: $resourceId"
Write-Host "ResourceId: $date"
Write-Host "Time: $time"

$Key = "Creator"
$tags = Get-AzTag -ResourceId $resourceId
$value = $tags.Properties.TagsProperty.$Key

# Determine if Creator tag already exists
if ($null -eq $value) {
    Write-Host "Updating tags"
    $tag = @{"Creator" = "$caller"; "DateCreated" = "$date"; "TimeCreated-PST" = "$time" }
    Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $tag
}
