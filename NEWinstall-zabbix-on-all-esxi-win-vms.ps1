$creds = (Get-Credential)
Connect-VIServer "<vmware server> -Credential $creds
$vms = get-vm | Where-Object {$_.Powerstate -eq "PoweredOn" -and $_.GuestID -like "win*"}
 
$results = @()
Write-Output "Below are the vms that will install app"
$vms
$URL = "https://samgmtzabbixinstaller.blob.core.windows.net/zabbix/zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
$Path = "$env:TEMP\zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -URI $URL -OutFile $Path
$vms | ForEach-Object {
    # Check if app is installed
    $CheckInstalled = Invoke-VMScript -VM $_ -ScriptText { Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "zabbix agent*" } } -GuestCredential $creds -ScriptType Powershell
    # If app is not installed ...
    if ($CheckInstalled.ScriptOutput -eq "") {
        # Install app
        # Copy exe to vm
        Copy-VMGuestFile -Source $Path -Destination $Path -LocalToGuest -VM $_ -GuestCredential $creds -Force -Verbose
        $status = Invoke-VMScript -VM $_ -ScriptText {
            # Install app
            $HOSTMETADATA = "windows_datacenter"
            $InstallLocation = $env:TEMP
            $MSIFile = "zabbix_agent2-6.2.3-windows-amd64-openssl.msi"
            $exe = "msiexec.exe"
            $ZabbixServer = "zabbix.amtwoundcare.com"
            $hostFQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName
            $PSKIDENTITY = "AMTAgentPSK"
            $PSKKEY = "<key>"
            $Arguments = "/i $InstallLocation\$MSIFile HOSTNAME=$hostFQDN SERVER=$ZabbixServer HOSTMETADATA=$HOSTMETADATA SERVERACTIVE=$ZabbixServer ENABLEPATH=TRUE TLSCONNECT=psk TLSACCEPT=psk TLSPSKIDENTITY=$PSKIDENTITY TLSPSKVALUE=$PSKKEY /qn /norestart"
            Start-Process -FilePath $exe -ArgumentList $Arguments -Wait
            Start-Sleep 5

            # Confirm Zabbix is running
            $ServiceName = 'Zabbix Agent 2'
            $zabbix_Service = Get-Service -Name $ServiceName
            if ($zabbix_Service.Status -eq 'Running') {
                Write-Output "$_ Service is now Running"
                exit 0
            }
            else {
                Write-Output "$_ Service is not Running"
                exit 1
            }
        } -GuestCredential $creds -ScriptType Powershell
        $status.ScriptOutput
        if (($status.ScriptOutput).Trim() -eq "$_ Service is now Running" ) {
            $update = "Zabbix install success"
            $sarr = new-object psobject -Property @{
                hostname = ($_)
                status   = ($update)
            }
        }
        else {
            $update = "Investigate further"
            $sarr = new-object psobject -Property @{
                hostname = ($_)
                status   = ($update)
            }
            $results += $sarr
        }
    }
    else {
        # app is already installed
        Write-Output "$_ Zabbix is already installed. Exiting..."
        $update = "Zabbix was previously installed"
        $sarr = new-object psobject -Property @{
            hostname = ($_)
            status   = ($update)
        }
        $results += $sarr
    }        
}
$results | Select-Object hostname, status 
Disconnect-VIServer -Force -Confirm:$false 
