# Azure Hub-Spoke Network Setup Script
#
# This script sets up a hub-and-spoke network topology in Azure across different subscriptions.
# It performs the following steps:
# 1. Sets the context to the target (spoke) subscription.
# 2. Creates a new resource group in the target subscription.
# 3. Creates a new VNet in the target resource group with a specified address space.
# 4. Creates five subnets within the target VNet.
# 5. Retrieves the resource ID of the target VNet.
# 6. Switches the context to the hub subscription.
# 7. Retrieves the resource ID of the hub VNet.
# 8. Creates a VNet peering from the hub to the spoke, allowing resources in the hub to communicate with resources in the spoke.
# 9. Switches the context back to the target subscription.
# 10. Creates a VNet peering from the spoke to the hub, allowing resources in the spoke to communicate with resources in the hub.
#
# Usage:
# - Define the necessary variables at the beginning of the script.
# - Run the script in an Azure CLI environment.
#
# Note:
# - Ensure that the specified VNets and resource groups exist or are unique to avoid conflicts.
# - Adjust the address spaces, subnet names, and other parameters as needed to fit your environment.

# Define Variables
hub_subscription=""
hub_resourceGroup=""
hub_vnetName=""
target_subscription=""
target_resourceGroup=""
target_vnetName=""
addressSpace=""

# Set target subscription/subnet context
az account set --subscription $target_subscription

# Create target resource group
az group create --name $target_resourceGroup --location westus

# Create target vnet
az network vnet create \
    --name $target_vnetName \
    --resource-group $target_resourceGroup \
    --address-prefix $addressSpace \
    --location westus

# Create target subnets
az network vnet subnet create \
    --name snet-infra \
    --vnet-name $target_vnetName \
    --resource-group $target_resourceGroup \
    --address-prefixes 10.12.1.0/27

az network vnet subnet create \
    --name snet-app \
    --vnet-name $target_vnetName \
    --resource-group $target_resourceGroup \
    --address-prefixes 10.12.1.32/27

az network vnet subnet create \
    --name snet-dmz \
    --vnet-name $target_vnetName \
    --resource-group $target_resourceGroup \
    --address-prefixes 10.12.1.64/27

az network vnet subnet create \
    --name snet-db \
    --vnet-name $target_vnetName \
    --resource-group $target_resourceGroup \
    --address-prefixes 10.12.1.96/27

az network vnet subnet create \
    --name snet-bastion \
    --vnet-name $target_vnetName \
    --resource-group $target_resourceGroup \
    --address-prefixes 10.12.1.128/27

# Get the resource ID of the spoke VNet
target_vnetId=$(az network vnet show --name $target_vnetName --resource-group $target_resourceGroup --query id -o tsv)

# Set hub subscription/subnet context
az account set --subscription $hub_subscription

# Get the resource ID of the hub VNet
hub_vnetId=$(az network vnet show --name $hub_vnetName --resource-group $hub_resourceGroup --query id -o tsv)

# Peering from Hub to Spoke
az network vnet peering create \
    --name HubToSpokePeering \
    --resource-group $hub_resourceGroup \
    --vnet-name $hub_vnetName \
    --remote-vnet $target_vnetId \
    --allow-vnet-access

# Set target subscription/subnet context
az account set --subscription $target_subscription

# And then from Spoke to Hub
az network vnet peering create \
    --name SpokeToHubPeering \
    --resource-group $target_resourceGroup \
    --vnet-name $target_vnetName \
    --remote-vnet $hub_vnetId \
    --allow-vnet-access
