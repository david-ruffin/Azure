# Variables
$msiUrl = "https://<storage_account_name>.blob.core.windows.net/<container_name>/ScreenConnect.ClientSetup.msi?<SAS_token>" # Replace with your URL
$destinationPath = "$env:TEMP\ScreenConnect.ClientSetup.msi" # Temporary location to store MSI

# Download the MSI from Azure Storage
Write-Host "Downloading MSI from Azure Storage..."
Invoke-WebRequest -Uri $msiUrl -OutFile $destinationPath

# Check if the file was downloaded
if (-Not (Test-Path -Path $destinationPath)) {
    Write-Error "Failed to download MSI file."
    exit 1
}

Write-Host "Download complete. Installing MSI..."

# Run the MSI installer
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$destinationPath`" ALLUSERS=1 /qn /norestart /log output.log" -Wait -NoNewWindow

# Check exit code for errors
if ($LASTEXITCODE -ne 0) {
    Write-Error "MSI installation failed with exit code $LASTEXITCODE."
    exit 1
}

Write-Host "Installation completed successfully."
