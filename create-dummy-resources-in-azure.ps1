# Script to create dummy resources with dependencies
# Declare Vars
$resourceGroupName = 'test-delete-tags'
$LocationNameName = "westus"

# Get subscriptions all subscriptions
$subs = (get-azsubscription).Name

# Check if resource group exists in all subscriptions
$subs | foreach {
    set-azcontext -subscription $_ 
    Get-AzResourceGroup $resourceGroupName }

# Check existing resources for tags
$subs | foreach {
    set-azcontext -subscription $_ 
    get-azresources -resourceGroup $resourceGroupName

}

# Create dummy resources
$subs | foreach {
    set-azcontext -Subscription $_
    #sleep 5
    New-AzResourceGroup -Name $resourceGroupName -Location $LocationName
    New-AzKeyVault -VaultName ('Vault' + (random)) -ResourceGroupName $resourceGroupName -Location $LocationName
    $saname = (New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name ('wdawdawd2' + (random)) -Location $LocationName -SkuName Standard_GRS).StorageAccountName
    New-AzFunctionApp -Name ('Functtagtestdelete' + (random)) `
        -ResourceGroupName $resourceGroupName `
        -Location $LocationName `
        -StorageAccountName $saname `
        -Runtime PowerShell

    $NetworkName = ("MyNet" + (random))
    $NICName = ("MyNIC" + (random))
    $SubnetName = ("Subnet" + (random))
    $SubnetAddressPrefix = "10.0.0.0/24"
    $VnetAddressPrefix = "10.0.0.0/16"

    $SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
    $Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationNameName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
    $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationNameName -SubnetId $Vnet.Subnets[0].Id
} 
