# This script will log into Azure portal and check all vms (in every subscription) and return their backup status
$RundeckPassword = "@option.RundeckPassword@"

# Log into Azure
$Username = "rundeck_svc@amtwoundcare.com"
$Password = ConvertTo-SecureString $RundeckPassword -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential $Username,$Password

Connect-AzAccount -Credential $Credentials | out-null

$result = $null
$ErrorActionPreference = 'silentlycontinue'
foreach ($i in (Get-AzSubscription)) {
    Set-AzContext -Subscription $i.Name
    $azvm = get-azvm
    $result += $azvm | ForEach-Object { if ((Get-AzRecoveryServicesBackupStatus -name $_.Name -ResourceGroupName $_.ResourceGroupName -Type AzureVM).BackedUp -eq $true) {
            [PSCustomObject] @{
                'VMname'            = $_.Name
                'ResourceGroupName' = $_.ResourceGroupName
                'Subscription'      = $i.Name
                'BackedUp'          = (Get-AzRecoveryServicesBackupStatus -name $_.name -ResourceGroupName $_.ResourceGroupName -Type AzureVM).BackedUp
                'VaultId'           = (Get-AzRecoveryServicesBackupStatus -name $_.name -ResourceGroupName $_.ResourceGroupName -Type AzureVM).VaultId
            }
        }
        else {
            [PSCustomObject] @{
                'VMname'            = $_.Name
                'ResourceGroupName' = $_.ResourceGroupName
                'Subscription'      = $i.Name
                'BackedUp'          = 'FALSE'
                'VaultId'           = 'n/a'
            }
        }
    }
}
$ErrorActionPreference = 'continue'

# Disconnect from Azure 
Disconnect-AzAccount | out-null

$result
($result `
    | Format-Table -wrap `
        @{Name="VMName";Expression = { $_.VMName }; Alignment="left"; Width=25 },
        @{Name="ResourceGroupName";Expression = { $_.ResourceGroupName }; Alignment="left"; Width=37 },
        @{Name="Subscription";Expression = { $_.Subscription }; Alignment="left"; Width=7 },
        @{Name="BackedUp";Expression = { $_.BackedUp }; Alignment="left"; Width=10 },
        @{Name="VaultId";Expression = { $_.VaultId }; Alignment="left"; Width=7 } `
    | Out-String).Trim() | out-null
    
    # Format and create email
    $Header = @"
        <style>
            TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
            TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
            TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
"@
    $From = "sysadmins@amtwoundcare.com"
    $To = "david.ruffin@amtwoundcare.com" #, "jaren.thorsen@amtwoundcare.com", "Michael.McFarland@amtwoundcare.com"
    $Subject = "All Azure VMs and their backup status via Rundeck"
    $Body = ($result | ConvertTo-Html -Head $Header)
    $SMTPServer = "amtsmtpr01.amtwoundcare.com"
    $SMTPPort = "25"
    # Sending email
    Write-Output "Sending email to $To "
    Send-MailMessage -From $From -To $To -Subject $Subject -Body "$Body" -BodyAsHtml -Priority High -DeliveryNotificationOption OnFailure -SmtpServer $SMTPServer -port $SMTPPort
