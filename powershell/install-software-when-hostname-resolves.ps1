# Accept a list of hostnames as input
param (
  [string[]]$hostnames
)

# Declare variables
$hostname = "example.com" # Replace with desired hostname
$software = 'C:\IT\installer_vista_win7_win8-64-3.8.0.684.msi' # Replace with path to MSI file

# Check if hostname resolves every minute
while ($true) {
  # Try to resolve the hostname
  try {
    $ip = [System.Net.Dns]::GetHostAddresses($hostname)
  }
  catch {
    Write-Host "Error resolving hostname: $($_.Exception.Message)"
    $ip = $null
  }
  
  # If hostname resolves, proceed with checking if host is online and installing software
  if ($ip) {
    # Check if host is online by pinging it
    if (Test-Connection -ComputerName $hostname -Count 1 -Quiet) {
      # Install software
      $command = {
        Start-Process -Wait -FilePath $software -ArgumentList '/qn /norestart COMPANY_CODE=TZ725OTDWDCT4NOSD6Z POLICY_NAME=AWS' -PassThru -WorkingDirectory 'C:\IT\'
      }
      Invoke-Command -ComputerName $hostname -ScriptBlock $command -ErrorAction Stop -AsJob
      
      # Confirm that software was installed
      $installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Carbon Black Cloud Sensor 64-bit" }
      if ($installed) {
        Write-Host "Software installed successfully"
      }
      else {
        Write-Host "Error installing software"
      }
      
      # Exit loop
      break
    }
  }
  
  # Wait for one minute before checking again
  Start-Sleep -Seconds 60
}
