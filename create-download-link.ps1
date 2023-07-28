# Declare Vars
# Connect to Azure using AZ module

$ResourceGroupName = "rg-prod-westus-aap"
$StorageAccountName = "saansible454e5e4"
$ContainerName = "ansible-automation-platform-aap"
$LocalFilePath = "/Users/tech/Downloads/ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz"
$fileName = Split-Path -Path $LocalFilePath -Leaf

# Check if the resource group exists
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

# If the resource group doesn't exist, create it
if (-not $resourceGroup) {
    New-AzResourceGroup -Name $ResourceGroupName -Location "West US"
}

# Create Storage Account if it doesn't exist
$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
if (!$storageAccount) {
    $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location "West US" -SkuName Standard_LRS -Kind StorageV2
}

# Set Container's public access level to 'Blob'
$ctx = $storageAccount.Context
New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob -ErrorAction SilentlyContinue

# Upload the file to the container
Set-AzStorageBlobContent -File $LocalFilePath -Container $ContainerName -Blob $fileName -Context $ctx

# Generate public URL for the file
$publicUrl = "https://$($storageAccount.StorageAccountName).blob.core.windows.net/$ContainerName/$fileName"

# Display the public URL
Write-Host "The public URL for the file is: $publicUrl"

$localDownloadPath = "$env:USERPROFILE\Downloads\$fileName"

Invoke-WebRequest -Uri $publicUrl -OutFile $localDownloadPath  
