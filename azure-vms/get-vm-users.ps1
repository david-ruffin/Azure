# Service Principal Auth
$spAppId = "YOUR-SP-APP-ID"
$spSecret = "YOUR-SP-SECRET"
$tenantId = "YOUR-TENANT-ID"
$subId = "YOUR-SUB-ID"

# VM Details
$vmName = "YOUR-VM-NAME"
$rgName = "YOUR-RG"

# Connect using Service Principal
$SecureClientSecret = ConvertTo-SecureString $client_secret -AsPlainText -Force
$PsCredential = New-Object System.Management.Automation.PSCredential($client_id, $SecureClientSecret)
Connect-AzAccount -ServicePrincipal -Credential $PsCredential -Tenant $tenant_id

$report = @()

# Get VM status
$status = (Get-AzVM -ResourceGroupName $rgName -Name $vmName -Status).Statuses | 
   Where-Object {$_.Code -match "PowerState"} | 
   Select-Object -ExpandProperty DisplayStatus

if ($status -ne "VM running") {
   $report += [PSCustomObject]@{
       VMName = $vmName
       ResourceGroup = $rgName
       Subscription = (Get-AzContext).Subscription.Name
       Status = $status
       OSType = "Windows"
       Username = "N/A"
       UserType = "N/A"
       Groups = "N/A"
       LastLogin = "N/A"
   }
}
else {
    $script = @"
    # Get local users and their details
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
       $result = Invoke-AzVMRunCommand -ResourceGroupName $rgName -Name $vmName `
           -CommandId 'RunPowerShellScript' -ScriptString $script

       $userDetails = $result.Value[0].Message | ConvertFrom-Json
       
       foreach ($user in $userDetails) {
           $report += [PSCustomObject]@{
               VMName = $vmName
               ResourceGroup = $rgName
               Subscription = (Get-AzContext).Subscription.Name
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
       Write-Warning "Error processing VM $vmName : $_"
   }
}

# Export and display
$report | Export-Csv "VMUserAccessAudit.csv" -NoTypeInformation
$report | Format-Table -AutoSize

# Disconnect
Disconnect-AzAccount
