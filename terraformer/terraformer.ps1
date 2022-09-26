# Terrafomer to scan all resource groups of a subscription and create files based on suppored resources
#### PreReqs ####
# Ensure Terraform and Terraformer are installed
# https://github.com/GoogleCloudPlatform/terraformer/blob/master/docs/azure.md
 
# Using Service Principal with Client Secret
export ARM_SUBSCRIPTION_ID=[SUBSCRIPTION_ID]
export ARM_CLIENT_ID=[CLIENT_ID]
export ARM_TENANT_ID=[TENANT_ID]
export ARM_CLIENT_SECRET=[CLIENT_SECRET]

# Connect to azure ad
Connect-azaccount
# Select subscriptions (if multiple subscriptions)
Set-AzContext -Subscription "sub-staging" 

(get-content .\supported-azure-objects.txt) | ForEach-Object {terraformer import azure -r $_} 
