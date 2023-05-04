$Username = "your_username_here"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force  
$Credentials = New-Object System.Management.Automation.PSCredential $Username, $Password  
Connect-AzAccount -Credential $Credential #-Tenant "your_tenant_id_here" -ServicePrincipal

# Get all avaialble subscriptions
$subs = (get-azsubscription).Name
$results = $null
$script = "C:\scripts\check-openssl-installed.ps1"
$subs | ForEach-Object {
    set-azcontext -Subscription $_ 
    $azvms = Get-azvm | where-object { $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
    $azvms | ForEach-Object { $status = Invoke-AzVmRunCommand `
            -ResourceGroupName $_.ResourceGroupName `
            -VMName $_.Name `
            -CommandId "RunPowerShellScript" `
            -ScriptPath $script -Verbose
        # If theres response to script, store in $results variable
        if ($null -ne $status.Value.message) { $results += $status.Value.message }
    }
}
Disconnect-AzAccount -Scope Process -Force

$results
