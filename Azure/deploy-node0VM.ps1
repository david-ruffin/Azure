# Step 1: Deploy Ubuntu VM with networking and security resources (per GOAL.md)

# Variables from GOAL.md
$resourceGroup = ""
$vmNameBase = "node0VM"
$AllowedPublicIP = ""
$adminPassword = ""
$subnetResourceID = ""
$vnetResourceGroup = ($subnetResourceID -split "/" | Where-Object {$_ -ne ""})[3]
$vnetName = ($subnetResourceID -split "/" | Where-Object {$_ -ne ""})[7]
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroup
$location = $vnet.Location
$vmSize = "Standard_DS2_v2"
$adminUsername = "azureuser"
$diskSizeGB = 40
$image = "Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest"

# Add a unique, safe 4-character alphanumeric suffix for resource names (Linux hostname safe)
$uniqueSuffix = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 4 | % {[char]$_})
$vnetNameShort = $vnetName.Substring(0, [Math]::Min(4, $vnetName.Length))
$finalVMName = "$vmNameBase-$vnetNameShort-$uniqueSuffix"
$nicName = "$finalVMName-nic"
$publicIpName = "$finalVMName-pip"
$nsgName = "$finalVMName-nsg"

# Ensure Resource Group exists (create only if not present)
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location | Out-Null
}

# Always create a new SSH Key resource for each deployment (do not reuse)
# PowerShell Az module does not have a direct "SSH key resource" cmdlet, so this step is omitted. If you need to upload/generate SSH keys, handle them outside or with custom logic.

# Create Public IP
$publicIp = New-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Static -Sku Standard

# Create NSG
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name $nsgName

# Create NSG rule to allow ONLY SSH (port 22) from AllowedPublicIP(s)
$allowedIPs = $AllowedPublicIP -split ",\s*"
$nsgRule = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH-FromWhitelist" -Description "Allow ONLY SSH from whitelisted IP(s)" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $allowedIPs -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$nsg.SecurityRules = @($nsgRule)  # Overwrite SecurityRules to ensure only this rule exists
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

# Create NIC attached to provided subnet, public IP, and NSG
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -Location $location -SubnetId $subnetResourceID -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id

# Prepare credentials (must meet Azure complexity requirements, even if SSH is used)
$securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $securePassword)

# Define VM Tags
$vmTags = @{
    Role = "Node 0 VM deployed for all vnets per John"
}

# --- VM Configuration Object Approach ---
# Create a VM configuration object, including Tags
$vmConfig = New-AzVMConfig -VMName $finalVMName -VMSize $vmSize -Tags $vmTags

# Set OS Profile (including credentials and computer name)
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $finalVMName -Credential $cred

# Set the OS Disk properties
# Assuming managed disk, derive OS disk name from VM name
$osDiskName = "$($finalVMName)_OsDisk"
# When using FromImage, the storage type and size are usually determined by the image.
# Remove -DiskSizeGB parameter.
$vmConfig = Set-AzVMOSDisk -VM $vmConfig -Name $osDiskName -CreateOption FromImage -Caching ReadWrite

# Set the VM Image
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName ($image -split ':')[0] -Offer ($image -split ':')[1] -Skus ($image -split ':')[2] -Version ($image -split ':')[3]

# Add the pre-created Network Interface
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id -Primary

# Disable Boot Diagnostics
$vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable

# --- Create the VM using the configuration object ---
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

# Output public IP (PowerShell Az version)
# Get the IP from the NIC's IP Configuration, as the PIP object might not be fully updated immediately
$publicIpObj = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroup
$publicIp = $publicIpObj.IpAddress
Write-Host "VM deployed. SSH with: ssh -i <your-private-key-path> $adminUsername@$publicIp"

# --- Step 2: Test Custom Script Extension with a sample shell script ---
# This demonstrates how to run a script on the VM via Azure Custom Script Extension.
# Replace this with NodeZero bootstrap logic after confirming this works.

# Path to sample script (ensure this file exists in your current directory)
$sampleScriptPath = "./sample-bootstrap.sh"

if (!(Test-Path $sampleScriptPath)) {
    Write-Error "Sample script not found: $sampleScriptPath"
    exit 1
}

# Bootstrap NodeZero on the VM using official Horizon3 install steps
# Reference: https://docs.horizon3.ai/downloads/ubuntu_to_nodezero/
# This will download and run the NodeZero setup script directly on the VM.

$nodeZeroScript = @"
curl -o ubuntu-build.sh https://downloads.horizon3ai.com/utilities/ubuntu-build.sh
sudo chmod +x ubuntu-build.sh
./ubuntu-build.sh
sudo rm -f ubuntu-build.sh
"@

Invoke-AzVMRunCommand `
    -ResourceGroupName $resourceGroup `
    -Name $finalVMName `
    -CommandId 'RunShellScript' `
    -ScriptString $nodeZeroScript

# --- End of NodeZero Bootstrap ---


# Stop the VM after the script has run
Get-AzVM -ResourceGroupName "" | Where-Object {$_.Tags.Role -eq "Node 0 VM deployed for all vnets per John"} | Stop-AzVM -Force
# Start the VM after the script has run
Get-AzVM -ResourceGroupName "rg-westus-node0deployment-041525" | Where-Object {$_.Tags.Role -eq "Node 0 VM deployed for all vnets per John"} | Start-AzVM
