# Service Principal Auth
$spAppId = "YOUR-SP-APP-ID"
$spSecret = "YOUR-SP-SECRET"
$tenantId = "YOUR-TENANT-ID"

# Connect with SP
$securePassword = ConvertTo-SecureString $spSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($spAppId, $securePassword)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId

$report = @()

# Process each subscription
foreach ($sub in Get-AzSubscription) {
   Set-AzContext -Subscription $sub.Id
   $vms = Get-AzVM | Where-Object {$_.StorageProfile.OsDisk.OsType -eq "Windows"}
   
   foreach ($vm in $vms) {
       $status = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses | 
           Where-Object {$_.Code -match "PowerState"} | 
           Select-Object -ExpandProperty DisplayStatus

       if ($status -ne "VM running") {
           $report += [PSCustomObject]@{
               VMName = $vm.Name
               ResourceGroup = $vm.ResourceGroupName
               Subscription = $sub.Name
               Status = $status
               Username = "N/A"
               LastLogin = "N/A"
           }
           continue
       }

       $script = @"
           `$users = @()
           Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624} -MaxEvents 50 | 
           Where-Object {`$_.Properties[8].Value -notlike '*$'} | 
           Select-Object @{n='Username';e={`$_.Properties[5].Value}}, 
                        @{n='LoginTime';e={`$_.TimeCreated}} | 
           Sort-Object LoginTime -Unique |
           ForEach-Object {
               `$users += @{
                   Username = `$_.Username
                   LastLogin = `$_.LoginTime.ToString('yyyy-MM-dd HH:mm')
               }
           }
           ConvertTo-Json -InputObject `$users -Compress
"@

       try {
           $result = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name `
               -CommandId 'RunPowerShellScript' -ScriptString $script

           $userDetails = $result.Value[0].Message | ConvertFrom-Json
           
           foreach ($user in $userDetails) {
               $report += [PSCustomObject]@{
                   VMName = $vm.Name
                   ResourceGroup = $vm.ResourceGroupName
                   Subscription = $sub.Name
                   Status = $status
                   Username = $user.Username
                   LastLogin = $user.LastLogin
               }
           }
       }
       catch {
           Write-Warning "Error processing VM $($vm.Name): $_"
       }
   }
}

$report | Export-Csv "VMUserAccessAudit.csv" -NoTypeInformation
$report | Format-Table -AutoSize
