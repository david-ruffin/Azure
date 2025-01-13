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
               OSType = "Windows"
               Username = "N/A"
               UserType = "N/A"
               Groups = "N/A"
               LastLogin = "N/A"
           }
           continue
       }

       $script = @"
           `$users = @()
           
           Get-LocalUser | Where-Object Enabled -eq `$true | ForEach-Object {
               `$user = `$_
               `$groups = Get-LocalGroup | Where-Object {
                   (Get-LocalGroupMember `$_.Name).Name -contains `$user.Name
               } | Select-Object -ExpandProperty Name
               
               `$users += @{
                   Username = `$user.Name
                   UserType = 'Local'
                   Groups = (`$groups -join ',')
                   LastLogin = if(`$user.LastLogon){`$user.LastLogon.ToString('yyyy-MM-dd')}else{'Never'}
               }
           }
           
           if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain) {
               Get-ADUser -Filter * -Property LastLogon | Where-Object Enabled -eq `$true | ForEach-Object {
                   `$groups = Get-ADPrincipalGroupMembership `$_.SamAccountName | Select-Object -ExpandProperty Name
                   
                   `$users += @{
                       Username = `$_.SamAccountName
                       UserType = 'Domain'
                       Groups = (`$groups -join ',')
                       LastLogin = if(`$_.LastLogon){([DateTime]::FromFileTime(`$_.LastLogon)).ToString('yyyy-MM-dd')}else{'Never'}
                   }
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
                   OSType = "Windows"
                   Username = $user.Username
                   UserType = $user.UserType
                   Groups = $user.Groups
                   LastLogin = $user.LastLogin
               }
           }
       }
       catch {
           Write-Warning "Error processing VM $($vm.Name): $_"
       }
   }
}

# Export and display
$report | Export-Csv "VMUserAccessAudit.csv" -NoTypeInformation
$report | Format-Table -AutoSize

# Disconnect
Disconnect-AzAccount
