# This will check all drives of a windows vm and report any drive over 80% full
$size             = @{label="Size(GB)"; expression = { [Math]::Round( ($_.Size/1GB), 2 ) }}
$freeSpace        = @{label="FreeSpace(GB)"; expression = { [Math]::Round( ($_.FreeSpace/1GB), 2 ) }}
$freeSpacePercent = @{label="FreeSpace(%)"; expression = { [Math]::Round( ($_.FreeSpace/$_.Size * 100), 2 ) }}

$space = Get-CimInstance -ClassName Win32_LogicalDisk | 
Select-Object -Property DeviceID,VolumeName,$size,$freeSpace,$freeSpacePercent 
$alert = $space | foreach {if( $_.'freespace(%)' -lt 20){echo $_}}
$alert  | ConvertTo-Csv 
