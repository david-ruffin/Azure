# Enable psremoting for domain joined computers
# Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'machineA,machineB'

Enable-PSRemoting -Force -Confirm:$false
Set-Item WSMan:localhost\client\trustedhosts -value 'AD.ruffin.com,rundeck.ruffin.com' -Force

Enable-PSRemoting -Force -Confirm:$false -SkipNetworkProfileCheck
Set-Item WSMan:localhost\client\trustedhosts -value 'ansible.amtwoundcare.com,amtprocess01.amtwoundcare.com,amtprocess02.amtwoundcare.com,rundeck.amtwoundcare.com' -Force 
