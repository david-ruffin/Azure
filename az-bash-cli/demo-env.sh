# Variables
RESOURCE_GROUP="VM-Monitoring-Demo-RG"
LOCATION="westus"
VM_NAME="MonDemoVM"
WORKSPACE_NAME="MonitoringDemoWorkspace"
VM_SIZE="Standard_DS2_v2"
IMAGE="Win2022Datacenter"
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD="YourP@ssw0rd123!"
DCR_NAME="MonitoringDemoDCR"
DCR_ASSOCIATION_NAME="DCRAssociation"

az group create --name $RESOURCE_GROUP --location $LOCATION

# 4. Create a Log Analytics Workspace
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $WORKSPACE_NAME \
    --location $LOCATION

# Capture the Workspace ID:
WORKSPACE_RESOURCE_ID=$(az monitor log-analytics workspace show \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $WORKSPACE_NAME \
    --query id -o tsv)


#5. Create the Windows Server VM
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --image $IMAGE \
    --size $VM_SIZE \
    --admin-username $ADMIN_USERNAME \
    --admin-password $ADMIN_PASSWORD \
    --public-ip-sku Standard \
    --output table

# 6. Install and Enable VM Insights
# Install the Dependency Agent and Monitoring Extensions
az vm extension set \
    --resource-group $RESOURCE_GROUP \
    --vm-name $VM_NAME \
    --name DependencyAgentWindows \
    --publisher Microsoft.Azure.Monitoring.DependencyAgent

az vm extension set \
  --resource-group $RESOURCE_GROUP \
  --vm-name $VM_NAME \
  --name AzureMonitorWindowsAgent \
  --publisher Microsoft.Azure.Monitor \
  --protected-settings '{"workspaceId":"'"$WORKSPACE_ID"'"}'

# 7. Create a Data Collection Rule (DCR) configuration JSON
cat <<EOF > dcr-config.json
{
  "location": "$LOCATION",
  "dataSources": {
    "windowsEventLogs": [
      {
        "name": "WindowsSecurityEvents",
        "streams": ["Microsoft-Event"],
        "xPathQueries": [
          "Security!*[System[(Level=1 or Level=2 or Level=3)]]"
        ]
      }
    ]
  },
  "destinations": {
    "logAnalytics": [
      {
        "name": "LogAnalyticsWorkspace",
        "workspaceResourceId": "$WORKSPACE_RESOURCE_ID"
      }
    ]
  },
  "dataFlows": [
    {
      "dataSourceName": "WindowsSecurityEvents",
      "streams": ["Microsoft-Event"],
      "destinations": ["LogAnalyticsWorkspace"]
    }
  ]
}
EOF

# Create the Data Collection Rule (DCR)
az monitor data-collection rule create \
    --resource-group $RESOURCE_GROUP \
    --name $DCR_NAME \
    --location $LOCATION \
    --rule-file dcr-config.json

# Associate the DCR with the Target VM
az monitor data-collection rule association create \
    --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/$VM_NAME" \
    --rule "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/dataCollectionRules/$DCR_NAME" \
    --name "DCRAssociation"

# Install the Dependency Agent and Monitoring Extensions
az vm extension set \
    --resource-group $RESOURCE_GROUP \
    --vm-name $VM_NAME \
    --name DependencyAgentWindows \
    --publisher Microsoft.Azure.Monitoring.DependencyAgent

# 8. Create an Alert Rule
az monitor metrics alert create \
    --name "HighCPUAlert" \
    --resource-group $RESOURCE_GROUP \
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/$VM_NAME" \
    --condition "avg Percentage CPU > 80" \
    --description "CPU usage exceeded 80%."

az policy assignment create \
    --name "EnableAzureMonitorForVMs" \
    --policy-set-definition "b24988ac-6180-42a0-ab88-20f7382dd24c" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
