$arcVMName = ""
$location = "westus"
$resourceGroupName = ""

# Initiate a mars backup on arc enabled server
$script = @"
Import-Module -Name 'C:\Program Files\Microsoft Azure Recovery Services Agent\bin\Modules\MSOnlineBackup\MSOnlineBackup.psd1'
Get-OBPolicy | Start-OBBackup
"@

New-AzConnectedMachineRunCommand -ResourceGroupName $resourceGroupName -Location $location -SourceScript $script -RunCommandName $patchName -MachineName $arcVMName
