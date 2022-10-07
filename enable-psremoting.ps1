# Enable psremoting for domain joined computers
# Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineA,machineB'

Enable-PSRemoting -Force -Confirm:$false
Set-Item WSMan:localhost\client\trustedhosts -value 'AD.ruffin.com,rundeck.ruffin.com' -Force

