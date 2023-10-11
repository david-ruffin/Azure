<#
.SYNOPSIS
This script performs the following operations in Azure:
1. Imports the required Az module.
2. Establishes an Azure session by prompting the user for credentials.
3. Switches context to the hub subscription and retrieves the existing hub Virtual Network (VNet) information.
4. Switches context back to the spoke subscription and creates a new Resource Group in the specified location.
5. Defines subnet configurations for the new VNet based on specified address prefixes.
6. Creates a new VNet in the specified resource group, with the defined subnets and address space.
7. Sets up VNet peering from the hub to the spoke and from the spoke to the hub.

.DESCRIPTION
This script is designed to set up VNet peering between an existing hub VNet and a new spoke VNet. 
It first switches context to the hub subscription to retrieve the hub VNet information, 
then switches back to the spoke subscription to create a new resource group and VNet with specified subnets. 
Finally, it sets up VNet peering in both directions between the hub and spoke VNets.

#>

# Import the Az module to enable Azure cmdlets
Import-Module Az

# Sign in to your Azure account to establish a session
# Note: The Connect-AzAccount cmdlet will prompt you for your credentials
Connect-AzAccount

# Define variables
$spokeSubscriptionName = "Contoso1"  # Name of the spoke subscription
$resourceGroupName = "rg-westus-network"  # Name of the resource group to be created
$location = "westus"  # Azure region where the resource group and VNet will be created
$vnetName = "vn-westus-vnet"  # Name of the new VNet to be created
$vnetAddressSpace = "10.110.0.0/16"  # Address space for the new VNet
$snetInfra = "10.110.10.0/24"  # Address prefix for the Infrastructure subnet
$snetApp = "10.110.20.0/24"  # Address prefix for the Application subnet
$snetDmz = "10.110.30.0/24"  # Address prefix for the DMZ subnet
$snetDb = "10.110.40.0/24"  # Address prefix for the Database subnet
$snetBastion = "10.110.11.0/26"  # Address prefix for the Bastion subnet
$hubVnetName = "vn-prod-westus3"  # Name of the existing hub VNet
$hubResourceGroupName = "rg-prod-westus3-fw"  # Name of the resource group where the hub VNet resides
$hubSubscriptionName = "Contoso Networking"  # Name of the hub subscription

# Switch context to hub subscription and retrieve the existing hub VNet information
Set-AzContext -Subscription $hubSubscriptionName
$hubVnet = Get-AzVirtualNetwork -ResourceGroupName $hubResourceGroupName -Name $hubVnetName

# Switch context back to spoke subscription and create a new Resource Group in the specified location
Set-AzContext -Subscription $spokeSubscriptionName
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Define subnet configurations for the new VNet based on the specified address prefixes
$snetInfraConfig = New-AzVirtualNetworkSubnetConfig -Name "snet-infra" -AddressPrefix $snetInfra
$snetAppConfig = New-AzVirtualNetworkSubnetConfig -Name "snet-app" -AddressPrefix $snetApp
$snetDmzConfig = New-AzVirtualNetworkSubnetConfig -Name "snet-dmz" -AddressPrefix $snetDmz
$snetDbConfig = New-AzVirtualNetworkSubnetConfig -Name "snet-db" -AddressPrefix $snetDb
$snetBastionConfig = New-AzVirtualNetworkSubnetConfig -Name "snet-bastion" -AddressPrefix $snetBastion

# Create a new Virtual Network with the defined subnets
$newVnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -Location $location -AddressPrefix $vnetAddressSpace -Subnet $snetInfraConfig, $snetAppConfig, $snetDmzConfig, $snetDbConfig, $snetBastionConfig

# Peer Hub to Spoke.
Set-AzContext -Subscription $hubSubscriptionName
Add-AzVirtualNetworkPeering -Name 'LinkHubToSpoke' -VirtualNetwork $hubVnet -RemoteVirtualNetworkId $newVnet.Id

# Peer Spoke to Hub.
Set-AzContext -Subscription $spokeSubscriptionName
Add-AzVirtualNetworkPeering -Name 'LinkSpokeToHub' -VirtualNetwork $newVnet -RemoteVirtualNetworkId $hubVnet.Id
