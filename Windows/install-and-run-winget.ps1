# Set TLS 1.2 to ensure secure connections for downloading resources (required by PSGallery)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Ensure NuGet Provider is Installed Non-Interactively ---
try {
    # Try to retrieve the NuGet provider from the installed package providers.
    # This forces an error if NuGet isn't already installed.
    $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Stop
} catch {
    Write-Output "NuGet provider not found. Installing..."
    # Install the NuGet package provider with the minimum required version non-interactively.
    Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force -Scope CurrentUser
    # Import the provider so it's available in the current session.
    Import-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force
}

# --- Set PSGallery Repository as Trusted ---
try {
    # This sets the PowerShell Gallery repository to a trusted state, which avoids interactive prompts.
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
} catch {
    Write-Output "Unable to set PSGallery trust. Registering PSGallery repository manually..."
    # If the repository doesn't exist or cannot be modified, register it manually.
    Register-PSRepository -Name PSGallery -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted
}

# --- Check for winget and Install if Needed ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "winget not found. Installing winget-install script..."
    # Install the winget-install script non-interactively from PSGallery.
    Install-Script -Name winget-install -Force -Scope CurrentUser
    
    # Retrieve the command information for the installed winget-install script.
    $scriptCommand = Get-Command winget-install -ErrorAction SilentlyContinue
    if ($scriptCommand) {
        # Execute the winget-install script using its full path.
        & $scriptCommand.Source
    } else {
        Write-Error "winget-install script not found after installation."
        exit 1
    }
} else {
    Write-Output "winget is already installed."
}

# --- Run winget Upgrade Command ---
# This command upgrades all installed packages using winget non-interactively.
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
