$vaultName = "YourKeyVaultName"

# Retrieve all secret names
$secretNames = (Get-AzKeyVaultSecret -VaultName $vaultName).Name

# Initialize an array to hold the secret details
$secretDetails = @()

# Loop through each secret name to get its value and metadata
foreach ($name in $secretNames) {
    $secretValue = Get-AzKeyVaultSecret -VaultName $vaultName -Name $name -AsPlainText
    $secretMetadata = Get-AzKeyVaultSecret -VaultName $vaultName -Name $name

    # Format the LastModified date to show only the date part
    $lastModifiedDate = $secretMetadata.Attributes.Updated.ToString("yyyy-MM-dd")

    # Create a custom object with the secret name, value, and last modified date
    $secretObject = [PSCustomObject]@{
        Name         = $name
        SecretValue  = $secretValue
        LastModified = $lastModifiedDate
    }
    # Add the custom object to the array
    $secretDetails += $secretObject
}

# Display the results
$secretDetails | Format-Table -AutoSize
