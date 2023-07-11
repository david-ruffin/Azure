# Download and install sql management studio
# https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16
# Define Variables
$media_path = "C:\path\to\your\directory\SSMS-Setup-ENU.exe"
# Download SSMS setup file
Invoke-WebRequest -Uri "https://aka.ms/ssmsfullsetup" -OutFile $media_path

# Install SSMS
$install_path = "$env:SystemDrive\SSMSto"
$params = "/Install /Quiet SSMSInstallRoot=`"$install_path`""
Start-Process -FilePath $media_path -ArgumentList $params -Wait
