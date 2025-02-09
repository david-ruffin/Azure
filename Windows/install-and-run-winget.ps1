# Set TLS 1.2 to ensure secure connections for downloading resources (required by PSGallery)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Ensure NuGet Provider is Installed Non-Interactively ---
try {
    # Attempt to retrieve the NuGet provider; this will error if it's not installed.
    $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Stop
} catch {
    Write-Output "NuGet provider not found. Installing..."
    # Install the NuGet provider with the required minimum version non-interactively.
    Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force -Scope CurrentUser
    # Import the provider so it's available in the current session.
    Import-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Force
}

# --- Set PSGallery Repository as Trusted ---
try {
    # Set the PowerShell Gallery repository to Trusted to avoid interactive prompts.
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
} catch {
    Write-Output "Unable to set PSGallery trust. Registering PSGallery repository manually..."
    # Register PSGallery manually if the repository cannot be set.
    Register-PSRepository -Name PSGallery -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted
}

# --- Check for winget and Install if Needed ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "winget not found. Installing winget-install script..."
    # Install the winget-install script non-interactively from PSGallery.
    Install-Script -Name winget-install -Force -Scope CurrentUser

    # Retrieve the full command information for the installed winget-install script.
    $scriptCommand = Get-Command winget-install -ErrorAction SilentlyContinue
    if ($scriptCommand) {
        # Execute the winget-install script using its full path to install winget.
        & $scriptCommand.Source
    } else {
        Write-Error "winget-install script not found after installation."
        exit 1
    }
} else {
    Write-Output "winget is already installed."
}

# --- Refresh the PATH Variable ---
# This line updates the current session's PATH environment variable,
# ensuring that newly installed executables (like winget) are immediately available.
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

# --- Run winget Upgrade Command ---
# Upgrade all installed packages non-interactively.
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
