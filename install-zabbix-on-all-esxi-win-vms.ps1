$creds = (Get-Credential)
Connect-VIServer amtvc1.amtwoundcare.com -Credential $creds
# Get Windows vms that are powered on and store in var
$vms = get-vm | Where-Object {$_.Powerstate -eq "PoweredOn" -and $_.GuestID -like "win*"}


$results = $null
$vms | foreach {
   
   $status = Invoke-VMScript -VM $_ -ScriptText {
   # Check if Zabbix is installed
    $CheckInstalled = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "zabbix agent*"}
    if ($null -eq $CheckInstalled){
        # Download Zabbix agent to local machine
        $URL = "https://samgmtzabbixinstaller.blob.core.windows.net/zabbix/zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
        $Path = "$env:TEMP\zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
        Invoke-WebRequest -URI $URL -OutFile $Path
        $HOSTMETADATA = "windows_datacenter"

        # Install Zabbix
        $InstallLocation = $env:TEMP
        $MSIFile = "zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
        $exe = "msiexec.exe"
        $ZabbixServer = "zabbix.amtwoundcare.com"
        $hostFQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName
        $PSKIDENTITY="AMTAgentPSK"
        $PSKKEY="<key>"
        $Arguments = "/i $InstallLocation\$MSIFile HOSTNAME=$hostFQDN SERVER=$ZabbixServer HOSTMETADATA=$HOSTMETADATA SERVERACTIVE=$ZabbixServer ENABLEPATH=TRUE TLSCONNECT=psk TLSACCEPT=psk TLSPSKIDENTITY=$PSKIDENTITY TLSPSKVALUE=$PSKKEY /qn /norestart"
        Start-Process -FilePath $exe -ArgumentList $Arguments -Wait
        $AgentVersion = "6.2.3"
        sleep 5

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
        }else{
            Write-Host "Zabbix is already installed. Exiting..."}

   } -GuestCredential $creds -ScriptType Powershell
   $status.ScriptOutput
   if (($status.ScriptOutput).Trim() -eq 'Service is now Running' ){
        $results += Write-Output "$_ : Zabbix install success"
        }elseif(($status.ScriptOutput).Trim() -eq "Zabbix is already installed. Exiting..."){
        $results += Write-Output "$_ : Zabbix was previously installed"
        }else{$results += Write-Output " $_ : You may need to investigate"}
   } 
