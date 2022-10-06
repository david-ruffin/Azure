$URL = "file location"
$Path = "c:\installer_vista_win7_win8-64-3.8.0.684.msi"
Invoke-WebRequest -URI $URL -OutFile $Path
installer_vista_win7_win8-64-3.8.0.684.msi /qn /norestart COMPANY_CODE=sefsefsef POLICY_NAME=POLICY
