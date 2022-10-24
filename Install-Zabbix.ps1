# Download Zabbix agent to local machine
$URL = "https://samgmtzabbixinstaller.blob.core.windows.net/zabbix/zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
$Path = "$env:TEMP\zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
Invoke-WebRequest -URI $URL -OutFile $Path

# Install Zabbix
$InstallLocation = $env:TEMP
$MSIFile = "zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
$exe = "msiexec.exe"
$ZabbixServer = "zabbix.amtwoundcare.com"
$hostFQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName
$PSKIDENTITY="AMTAgentPSK"
$PSKKEY="<key>"
$Arguments = "/i $InstallLocation\$MSIFile HOSTNAME=$hostFQDN SERVER=$ZabbixServer SERVERACTIVE=$ZabbixServer ENABLEPATH=TRUE TLSCONNECT=psk TLSACCEPT=psk TLSPSKIDENTITY=$PSKIDENTITY TLSPSKVALUE=$PSKKEY /qn /norestart"
Start-Process -FilePath $exe -ArgumentList $Arguments -Wait
$AgentVersion = "6.2.3"

# Confirm Zabbix is running
$ServiceName = 'Zabbix Agent 2'
$zabbix_Service = Get-Service -Name $ServiceName
if ($zabbix_Service.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
        exit 0
    }
    else
    {
        Write-Host 'Service is not Running'
        exit 1
    } 
