# Log in to Azure
Connect-AzAccount

# Retrieve all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an array to hold the VM details
$vmDetails = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Select the current subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Retrieve all VMs in the current subscription
    $vms = Get-AzVM

    # Collect VM information
    foreach ($vm in $vms) {
        # Get the hostname and OS information of the VM
        $hostname = $vm.OSProfile.ComputerName
        $osPlatform = $vm.StorageProfile.OsDisk.OsType
        $osVersion = $vm.StorageProfile.ImageReference.Sku

        # Create a custom object with subscription name, VM resource name, hostname, OS platform, and OS version
        $vmDetail = [PSCustomObject]@{
            SubscriptionName    = $subscription.Name
            AzureVMResourceName = $vm.Name
            DNSHostname         = $hostname
            OSPlatform          = $osPlatform
            OSVersion           = $osVersion
        }

        # Add the details to the array
        $vmDetails += $vmDetail
    }
}

# Output the results as a table
$vmDetails | Format-Table -AutoSize
