# Disable public access for storage account
Set-AzStorageAccount -ResourceGroupName "" -name "" -PublicNetworkAccess Disabled 
