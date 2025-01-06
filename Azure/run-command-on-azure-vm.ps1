# Script
$script = @"
hostname
"@

Invoke-AzVMRunCommand -ResourceGroupName "<rg_name>" -Name "<vm_name>" -ScriptString $script -CommandId 'RunPowerShellScript'  
