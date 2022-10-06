# Enable psremoting for domain joined computers

Enable-PSRemoting -Force -Confirm:$false
Set-Item WSMan:localhost\client\trustedhosts -value AD.ruffin.com -Force
