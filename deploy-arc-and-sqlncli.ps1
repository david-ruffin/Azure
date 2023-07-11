$creds = Get-Credential
$workspaces = ""

$scriptBlock = {
    # Install azure arc agent
    Set-ExecutionPolicy Unrestricted -Force
    try {
        $servicePrincipalClientId = "";
        $servicePrincipalSecret = "";
        
        $env:SUBSCRIPTION_ID = "";
        $env:RESOURCE_GROUP = "";
        $env:TENANT_ID = "";
        $env:LOCATION = "westus";
        $env:AUTH_TYPE = "principal";
        $env:CORRELATION_ID = "";
        $env:CLOUD = "AzureCloud";
            
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072;
        Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/azcmagent-windows" -TimeoutSec 30 -OutFile "$env:TEMP\install_windows_azcmagent.ps1";
        & "$env:TEMP\install_windows_azcmagent.ps1";
        if ($LASTEXITCODE -ne 0) { exit 1; }
        & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect --service-principal-id "$servicePrincipalClientId" --service-principal-secret "$servicePrincipalSecret" --resource-group "$env:RESOURCE_GROUP" --tenant-id "$env:TENANT_ID" --location "$env:LOCATION" --subscription-id "$env:SUBSCRIPTION_ID" --cloud "$env:CLOUD" --correlation-id "$env:CORRELATION_ID";
    }
    catch {
        $logBody = @{subscriptionId = "$env:SUBSCRIPTION_ID"; resourceGroup = "$env:RESOURCE_GROUP"; tenantId = "$env:TENANT_ID"; location = "$env:LOCATION"; correlationId = "$env:CORRELATION_ID"; authType = "$env:AUTH_TYPE"; operation = "onboarding"; messageType = $_.FullyQualifiedErrorId; message = "$_"; };
        Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) | out-null;
        Write-Host  -ForegroundColor red $_.Exception;
    }
    # Install sqlncli that is saved in azure storage via script https://github.com/david-ruffin/Azure/blob/main/create-download-link.ps2
    Invoke-WebRequest -Uri "https://awsworkspaces336538234.blob.core.windows.net/obdc/sqlncli.msi" -OutFile "$env:USERPROFILE\Downloads\sqlncli.msi"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $env:USERPROFILE\Downloads\sqlncli.msi", "/quiet", "IACCEPTSQLNCLILICENSETERMS=YES" -Wait -NoNewWindow
    if ((Test-Path -Path "$env:SYSTEMROOT\system32\sqlncli11.dll") -and
        (Test-Path -Path "$env:SYSTEMROOT\system32\sqlnclir11.rll") -and
        (Test-Path -Path "$env:SYSTEMROOT\system32\s11ch_sqlncli.chm") -and
        (Test-Path -Path "$env:PROGRAMFILES\Microsoft SQL Server\110\SDK\sqlncli.h") -and
        (Test-Path -Path "$env:PROGRAMFILES\Microsoft SQL Server\110\SDK\sqlncli11.lib") -and
        (Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers" -Name "SQL Server*" -ErrorAction SilentlyContinue)) {
        Write-Output "$env:COMPUTERNAME: SQL Server Native Client is installed."
    }
    else {
        Write-Output "$env:COMPUTERNAME: SQL Server Native Client is not installed."
    }
    if (Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers" | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq "SQL Server Native Client 11.0" }) {
        write-host "$env:COMPUTERNAME: SQL Server Native Client 11.0 is installed"
    }
}

$workspaces | foreach { Invoke-Command -ComputerName $_ -ScriptBlock $scriptBlock -Credential $creds } 
