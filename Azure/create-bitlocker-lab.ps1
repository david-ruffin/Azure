# https://learn.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-powershell-quickstart
$rgName = "rg-westus-it-bitlocker"
$loc = "westus"
$kv = "kv-westus-it-bitlocker"
$vm = "bitlockertest"
$cred = Get-Credential

# Create a new resource group
New-AzResourceGroup -Name $rgName -Location $loc

# Create a new VM
New-AzVM -Name $vm -Credential $cred -ResourceGroupName $rgName -Image win2016datacenter -Size Standard_D2S_V3 -Location $loc
# Create a new key vault
New-AzKeyvault -name $kv -ResourceGroupName $rgName -Location $loc -EnabledForDiskEncryption
# Enable the key vault for disk encryption
$KeyVault = Get-AzKeyVault -VaultName $kv -ResourceGroupName $rgName
# Encrypt the VM
Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgName -VMName $vm -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId -Force
# Get the disk encryption status
Get-AzVmDiskEncryptionStatus -VMName $vm -ResourceGroupName $rgName
