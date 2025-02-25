# https://blog.leitwolf.io/microsoft-graph-powershell-certificate/
# Create certificate
$privateCert = New-SelfSignedCertificate -Subject "MyGraphApp" -CertStoreLocation "cert:\LocalMachine" -NotAfter (Get-Date)
.AddYears(1) -KeySpec KeyExchange

# Export certificate to .cer file
$privateCert | Export-Certificate -FilePath C:\public.cer

# Install the Microsoft.Graph module
Install-Module Microsoft.Graph -Scope AllUsers

# Get certificate from the machine store. Use the thumprint from above
$cert = Get-ChildItem Cert:\LocalMachine\My\09F46C88544572B824467423A14BB3E8948462AC

# Connect to the MS Graph using the client id, tenant id and the certificate
Connect-MgGraph -ClientID "" -TenantId "" -Certificate $cert

# Execute Graph Cmdlets as needed
Get-MgUser 
