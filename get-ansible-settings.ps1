 # Get the current username
$username = [Environment]::UserName
Write-Output "ansible_user: $username"

# The connection method for Windows is always WinRM
Write-Output "ansible_connection: winrm"

# Get the WinRM service configuration
$winrmConfig = winrm get winrm/config

# Determine the WinRM transport method
if ($winrmConfig -match "Kerberos\s+=\s+true") {
    $transport = "kerberos"
} elseif ($winrmConfig -match "CredSSP\s+=\s+true") {
    $transport = "credssp"
} elseif ($winrmConfig -match "Basic\s+=\s+true") {
    $transport = "basic"
} elseif ($winrmConfig -match "Certificate\s+=\s+true") {
    $transport = "ssl"
} else {
    $transport = "ntlm"
}
Write-Output "ansible_winrm_transport: $transport"

# Determine the WinRM server certificate validation method
if ($transport -eq "ssl") {
    $certValidation = "validate"
} else {
    $certValidation = "ignore"
}
Write-Output "ansible_winrm_server_cert_validation: $certValidation"

# Determine the WinRM port
if ($transport -eq "ssl") {
    $port = "5986"
} else {
    $port = "5985"
}
Write-Output "ansible_port: $port"
 
