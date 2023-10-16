# Get a list of azure arc agents that havent checked in over 30 days, display and delete.
$ThirtyDaysAgo = (Get-Date).AddDays(-30)
$MachinesToDelete = Get-AzConnectedMachine | 
    Where-Object { $_.LastStatusChange -lt $ThirtyDaysAgo } |
    Select-Object Name, ResourceGroupName, LastStatusChange

$MachinesToDelete 
$MachinesToDelete | ForEach-Object {
    Remove-AzConnectedMachine -Name $_.Name -ResourceGroupName $_.ResourceGroupName
}
