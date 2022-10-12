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
Connect-MgGraph -ClientID f0cc343a-ac2e-43b2-93be-63376e9e7629 -TenantId 79f812cc-f0c6-4ac1-bc6d-e8120d4cc6cd -Certificate $cert

# Execute Graph Cmdlets as needed
Get-MgUser 
