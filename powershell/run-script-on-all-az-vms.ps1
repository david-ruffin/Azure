# Connect to your Azure account
connect-azaccount

# Get all available subscriptions
$subs = (get-azsubscription).Name

# Create an empty array to store the results
$results = @()

# Define the path to the script that will be executed on all VMs
$script = "C:\adminUsers.ps1"

# Iterate through each subscription
$subs | ForEach-Object {
    # Set the current subscription context
    set-azcontext -subscription $_
    
    # Get the list of running Windows VMs in the current subscription
    $vmList = get-azvm | where-object {
        (Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status).Statuses[1].Code -eq 'PowerState/running' -and $_.StorageProfile.OsDisk.OsType -eq "Windows"
    }

    # Iterate through each running Windows VM
    foreach ($vmName in $vmList) {
        # Invoke the adminUsers.ps1 script on the current VM
        $scriptResult = Invoke-AzVmRunCommand `
            -ResourceGroupName $vmName.ResourceGroupName `
            -VMName $vmName.Name `
            -CommandId "RunPowerShellScript" `
            -ScriptPath $script -Verbose

        # Create a custom object with the output information
        $outputObject = [PSCustomObject]@{
            Hostname               = $vmName.Name
            LocalAdminGroupMembers = ($scriptResult[0].Value[0].Message) | Out-String
        }

        # Add the output object to the results array
        $results += $outputObject
    }
}

# Display the results array
$results
