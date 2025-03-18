# Declare Variables
$clientId = ""
$tenantId = ""
$clientSecret = ""
$subscription = "pay-as-you-go"
$resourceGroup = ""
$resourceName = "VM Alerts"

# Connect using Service Principal
$SecureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$PsCredential = New-Object System.Management.Automation.PSCredential($clientId, $SecureClientSecret)
Connect-AzAccount -ServicePrincipal -Credential $PsCredential -Tenant $tenantId

# Set Azure Subscription
Set-AzContext -Subscription $subscription
# Enable Activity Log Alert
Update-AzActivityLogAlert -ResourceGroupName $resourceGroup -Name $resourceName -Enabled $false
# Update-AzActivityLogAlert -ResourceGroupName $resourceGroup -Name $resourceName -Enabled $true
