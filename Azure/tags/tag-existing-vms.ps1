# example: ./tag-existing-vms.ps1 -VMNames @("server01", "server02") 

param(
    [Parameter(Mandatory=$true)]
    [string[]]$VMNames
)

foreach ($vmName in $VMNames) {
    $vm = Get-AzVM -Name $vmName
    $resource = Get-AzResource -ResourceId $vm.Id -ExpandProperties
    $timeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")
    $creationTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($resource.Properties.timeCreated, $timeZone.Id)

    $tagsToUpdate = @{
        Creator = "Unknown (Pre-existing)"
        DateCreated = $creationTime.ToString('M/d/yyyy')
        TimeCreatedInPST = $creationTime.ToString('hh:mmtt')
    }

    Update-AzTag -ResourceId $vm.Id -Tag $tagsToUpdate -Operation Merge
    Write-Host "Updated tags for: $vmName"
}
