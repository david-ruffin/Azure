# Enable WinRM
Enable-PSRemoting -Force

# Create self-signed certificate
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "Cert:\LocalMachine\My"

# Create HTTPS listener
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force

# Open firewall port for HTTPS
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow

# Enable Basic authentication
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

# Allow local accounts to use WinRM
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Value 1 -Type DWord
