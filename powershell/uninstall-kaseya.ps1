# Define the service names for Kaseya Agent and Kaseya Agent Endpoint
# sourced from https://patrickdomingues.com/2023/04/23/how-to-uninstall-kaseya-using-powershell/
$agentService = "Kaseya Agent"
$endpointService = "Kaseya Agent Endpoint"

# Stop the Kaseya services if they are running
Write-Output "Stopping Kaseya services..."
if (Get-Service -Name $agentService -ErrorAction SilentlyContinue) {
    Stop-Service -Name $agentService -Force
}
if (Get-Service -Name $endpointService -ErrorAction SilentlyContinue) {
    Stop-Service -Name $endpointService -Force
}

# Get the specific Kaseya agent directory name
$kdir = Get-ChildItem 'C:\Program Files (x86)\Kaseya' | Select-Object -ExpandProperty Name

# Silently uninstall Kaseya Agent
Write-Output "Uninstalling Kaseya Agent..."
Start-Process -FilePath "C:\Program Files (x86)\Kaseya\$kdir\KASetup.exe" -ArgumentList "/s", "/r", "/g $kdir", "/l %temp%\kasetup.log" -Wait

# Delete leftover performance counters
$csvfiles = Get-ChildItem 'C:\kworking\Klogs' | Select-Object -ExpandProperty Name | ForEach-Object { $_.replace('.csv', '') }
$counters = foreach ($a in $csvfiles) { $a.replace('KLOG', 'KCTR') }
foreach ($i in $counters) {
    Write-Output "Removing performance counter $i..."
    & logman.exe stop $i
    & logman.exe delete $i
}

# Remove the kworking folder
Write-Output "Removing kworking folder..."
& cmd.exe /c rd /s /q c:\kworking

Write-Output "Kaseya Agent uninstallation and cleanup complete."
