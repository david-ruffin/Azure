# Output directory for the running services results
$outputDir = "$HOME\Documents\VM_Running_Services"

# Create the directory if it doesn't exist
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

# PowerShell script to retrieve running services
$serviceScript = 'Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, DisplayName'

# Get all Azure subscriptions
$subscriptions = Get-AzSubscription

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    Write-Host "Checking subscription: $($subscription.Name)" -ForegroundColor Cyan
    Set-AzContext -Subscription $subscription.Id

    # Get all VMs in the current subscription
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        # Check if the VM is in the list of VMs you are tracking
        if ($vmList -contains $vm.Name) {
            $vmName = $vm.Name
            $resourceGroupName = $vm.ResourceGroupName

            Write-Host "Checking running services on VM: $vmName in subscription: $($subscription.Name)"

            # Run the script on the VM to get the list of running services
            try {
                $runCommand = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptString $serviceScript

                # Get the output from the run command
                $servicesOutput = $runCommand.Value[0].Message

                # Write the output to a file named after the VM
                $outputFile = "$outputDir\$vmName-RunningServices.txt"
                $servicesOutput | Out-File -FilePath $outputFile

                Write-Host "Running services for VM: $vmName have been saved to $outputFile" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to retrieve services for VM: $vmName" -ForegroundColor Red
            }
        }
    }
}

Write-Host "Script completed. Check the output files in: $outputDir"
