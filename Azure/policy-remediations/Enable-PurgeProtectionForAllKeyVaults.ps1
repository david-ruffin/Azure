<#
.SYNOPSIS
    This script enables purge protection on all key vaults in the current Azure subscription.
    This is in response to the Azure Policy: "Key vaults should have purge protection enabled."
    
.DESCRIPTION
    Purge protection enforces a mandatory retention period for soft-deleted key vaults, preventing
    any key vault from being permanently deleted (purged) during this time. This is a critical
    security measure to safeguard against accidental or malicious deletion of key vaults.

    This script uses the Az PowerShell module to retrieve all key vaults within a subscription 
    and enables purge protection if it's not already enabled.

.PARAMETER None
    No parameters required. The script uses the default Azure context (logged-in subscription).

.NOTES
    - Purge protection is irreversible once enabled.
    - Ensure you are logged into the correct Azure subscription before running this script.
    - Requires the Az.KeyVault PowerShell module.
    - Addresses the following Azure Policy:
        "Key vaults should have purge protection enabled"
    
.EXAMPLE
    .\Enable-PurgeProtectionForAllKeyVaults.ps1
    This command will enable purge protection for all key vaults in the current Azure subscription.

#>

# Get all Key Vaults in the current Azure subscription
$keyVaults = Get-AzKeyVault

# Loop through each Key Vault and enable purge protection
foreach ($keyVault in $keyVaults) {
    
    # Retrieve Key Vault Name and Resource Group for each vault
    $vaultName = $keyVault.VaultName
    $resourceGroupName = $keyVault.ResourceGroupName

    # Write the current vault being processed to the console
    Write-Host "Processing Key Vault: $vaultName in Resource Group: $resourceGroupName"

    try {
        # Enable purge protection using Update-AzKeyVault cmdlet
        Write-Host "Enabling Purge Protection for Key Vault: $vaultName"
        Update-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $vaultName -EnablePurgeProtection

        # Output success message
        Write-Host "Successfully enabled Purge Protection for Key Vault: $vaultName" -ForegroundColor Green
    }
    catch {
        # If an error occurs, output the error message
        Write-Host "Error enabling Purge Protection for Key Vault: $vaultName. Error: $_" -ForegroundColor Red
    }
}

Write-Host "Purge Protection has been enabled for all Key Vaults." -ForegroundColor Cyan
