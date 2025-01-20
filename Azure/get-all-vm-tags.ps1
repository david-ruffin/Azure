$tagBackup = @()
$vms = Get-AzVM

foreach ($vm in $vms) {
   try {
       $resource = Get-AzResource -ResourceId $vm.Id -ExpandProperties
       $tags = Get-AzTag -ResourceId $vm.Id -ErrorAction SilentlyContinue
       
       $tagsString = if ($tags -and $tags.Properties.TagsProperty) {
           ($tags.Properties.TagsProperty.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '
       } else {
           ""
       }
       
       $tagBackup += [PSCustomObject]@{
           VMName = $vm.Name
           ResourceId = $vm.Id
           CreationTime = $resource.Properties.timeCreated.ToString('M/d/yyyy h:mm:ss tt')
           ExistingTags = $tagsString
       }
   } catch {
       Write-Host "Error processing $($vm.Name): $($_.Exception.Message)"
   }
}

$tagBackup | Export-Csv -Path "vm_tags_backup_$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation -Encoding UTF8
