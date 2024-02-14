<#
.SYNOPSIS
This PowerShell script evaluates each repository within a specified Azure Container Registry (ACR) against predefined criteria (having more than three tags, including a 'latest' tag) and identifies images that would be eligible for deletion based on their age (older than 30 days). It lists these findings without performing any actual deletions.

.DESCRIPTION
The script performs the following steps:
1. Connects to Azure and optionally sets the desired Azure subscription context.
2. Retrieves a list of all repositories from the specified ACR.
3. For each repository, it checks if the criteria of having more than three tags and including a 'latest' tag are met.
4. If criteria are met, it then examines each tag to identify images tagged with dates older than 30 days, excluding the 'latest' tag and any tags not following the expected date format.
5. It compiles a summary of actions indicating whether the repository meets the criteria and, if so, how many images are eligible for deletion based on their age.
6. It optionally provides detailed information about each image considered for deletion, including the repository name, tag, creation date, and age.

The script outputs:
- A table summarizing the action for each repository, indicating whether it met the criteria and the number of images eligible for deletion.
- Optionally, a detailed table listing specific images that would be deleted, showing their repository, tag, creation date, and age.

.NOTES
- This script is intended for informational and audit purposes, providing insights into potential cleanup actions without performing any deletions.
- Ensure you are logged into Azure and have the necessary permissions to access the ACR and its repositories before running this script.
- Always review and confirm the script's findings manually before taking any deletion actions, especially in production environments.

.EXAMPLE
# Example usage:
.\list-old-acr-images.ps1
#>

# Declare Variables
$TenantId = "" # Define Azure Tenant ID
$ClientId = "" # Define Azure Client ID
$ClientSecret = "" # Define Azure Client Secret
$Subscription_Id = "" # Define Azure Subscription ID
$registryName = "" # Define the name of the Azure Container Registry

$ClientSecretSecure = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecretSecure

# Authenticate to Azure using Service Principal
Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantId -WarningAction SilentlyContinue | Out-Null

# Set the Azure context to the desired subscription if multiple subscriptions are available
Set-AzContext -Subscription $Subscription_Id

# Dynamically retrieve the list of repositories within the specified Azure Container Registry
$repos = Get-AzContainerRegistryRepository -RegistryName $registryName

# Initialize an array to hold summary action results for each repository
$actionResults = @()
# Initialize an array to hold detailed information about images that would be considered for deletion
$deletionDetails = @()

# Capture the current date and time for comparison against image tags
$currentDate = Get-Date

# Iterate over each repository in the list to evaluate and apply criteria
foreach ($repo in $repos) {
    # Fetch the list of tags for the current repository, ordered by time in descending order
    $tags = az acr repository show-tags --name $registryName --repository $repo --orderby time_desc --output json | ConvertFrom-Json
    # Initialize a counter for the number of images eligible for deletion based on the criteria
    $deletableImagesCount = 0

    # Check the criteria: there must be more than 3 tags, and one of them must be 'latest'
    if ($tags.Count -gt 3 -and $tags -contains 'latest') {
        # If criteria met, iterate over each tag to check if it represents an image older than 30 days
        foreach ($tag in $tags) {
            # Skip processing for 'latest' tag and any tags not following the expected date format
            if ($tag -eq 'latest' -or $tag -notmatch 'utc-\d{8}-\d{4}') {
                continue
            }

            # Convert the tag representing a date into a DateTime object for comparison
            $tagDateStr = $tag -replace 'utc-', '' -replace '-', '/' -replace '(\d{4})(\d{2})(\d{2})/(\d{2})(\d{2})', '$1-$2-$3 $4:$5'
            $tagDate = [datetime]::ParseExact($tagDateStr, 'yyyy-MM-dd HH:mm', $null)
            # Calculate the age of the image in days
            $daysDifference = ($currentDate - $tagDate).Days

            # If the image is older than 30 days, consider it eligible for deletion
            if ($daysDifference -gt 30) {
                $deletableImagesCount++
                # Add detailed information about the image to the deletion details array
                $deletionDetails += [PSCustomObject]@{
                    Repository = $repo
                    TaggedAs = $tag
                    CreatedOn = $tagDateStr
                    DaysOld = $daysDifference
                }
            }
        }

        # After evaluating all tags, add a summary of actions to the action results array
        if ($deletableImagesCount -gt 0) {
            $actionResults += [PSCustomObject]@{
                Repository = $repo
                Action = "Delete $deletableImagesCount images"
            }
        } else {
            # If no images are older than 30 days, note that no deletion is necessary
            $actionResults += [PSCustomObject]@{
                Repository = $repo
                Action = "No images to delete (all images newer than 30 days)"
            }
        }
    } else {
        # If the initial criteria are not met, record the reason in the action results
        $actionResults += [PSCustomObject]@{
            Repository = $repo
            Action = "Criteria not met (less than 4 images or 'latest' tag missing)"
        }
    }
}

# Display the summary action results for each repository in a table format
$actionResults | Format-Table -Property Repository, Action -AutoSize

# Optionally, display detailed information about the images considered for deletion
# Uncomment the line below to view these details
$deletionDetails | Format-Table -Property Repository, TaggedAs, CreatedOn, DaysOld -AutoSize
