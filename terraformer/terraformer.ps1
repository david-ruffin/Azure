 # Terrafomer to scan all resource groups of a subscription and create files based on suppored resources
 #### PreReqs ####
 # Ensure Terraform and Terraformer are installed
 
 
# Using Service Principal with Client Secret
export ARM_SUBSCRIPTION_ID=[SUBSCRIPTION_ID]
export ARM_CLIENT_ID=[CLIENT_ID]
export ARM_TENANT_ID=[TENANT_ID]
export ARM_CLIENT_SECRET=[CLIENT_SECRET]

(get-content .\AzureObjects.txt) | ForEach-Object {terraformer import azure -r $_} 
