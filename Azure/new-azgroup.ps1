# This script creates multiple groups in Azure AD

# List of groups to create
$groupsToCreate = @("Group1", "Group2", "Group3") # Add group names as needed

# Initialize an array to hold the results
$results = @()

foreach ($groupName in $groupsToCreate) {
    # Creating the Azure AD Group
    try {
        $adGroup = New-AzADGroup -DisplayName $groupName -MailNickname $groupName.Replace(" ", "") -Description "Description of $groupName"
        $results += New-Object PSObject -Property @{
            GroupName = $groupName
            GroupId   = $adGroup.Id
        }
        Write-Output "Azure AD group '$($adGroup.DisplayName)' created successfully."
    } catch {
        Write-Error "Error creating Azure AD group '$groupName': $_"
    }
}

# Display results in a table
$results | Format-Table -Property GroupName, GroupId
