# When using from linux to windows, the following dependencies must be installed in Powershell on linux
# pwsh -Command 'Install-Module -Name PSWSMan -Force'
# sudo pwsh -Command 'Install-WSMan'
# Also note, you may need to get authentication for domain controller

# Declare variables

$file = '/var/lib/rundeck/ad-users.json'
$ADSearchBase = 'OU=Employees,DC=AMTWOUNDCARE,DC=com'
$DCServerName = 'amtdc5.amtwoundcare.com'

# Declare variables
$file = 'c:\users.json'
$ADSearchBase = 'OU=Employees,DC=AMTWOUNDCARE,DC=com'
$DCServerName = 'amtdc5.amtwoundcare.com'

# If the file does not exist, create it.
if (-not(Test-Path -Path $file -PathType Leaf)) {
    try {
        (Invoke-Command -ComputerName $DCServerName -ScriptBlock {
            Get-ADUser -SearchBase $using:ADSearchBase -Filter { Enabled -eq $true } | `
                Where-Object { $_.DistinguishedName -notmatch "admin" } | Select-Object SamAccountName
        } -Credential $creds | Sort-Object -Property SamAccountName).SamAccountName | ConvertTo-Json | Out-file $file -Force

        Write-Host "The file [$file] has been created."
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, check to see if new users were added to AD
else {
    $get_users = (Invoke-Command -ComputerName $DCServerName -ScriptBlock {
            Get-ADUser -SearchBase $using:ADSearchBase -Filter { Enabled -eq $true } | `
                Where-Object { $_.DistinguishedName -notmatch "admin" } | `
                Select-Object SamAccountName
        } -Credential $creds | Sort-Object -Property SamAccountName).SamAccountName
    if ($get_users.Count -ne (Get-Content $file | ConvertFrom-Json).count) {
        
        # There have been new users added to Active Directory and this script will create new file with updated users
        (Invoke-Command -ComputerName $DCServerName -ScriptBlock {
            Get-ADUser -SearchBase $using:ADSearchBase -Filter { Enabled -eq $true } | `
                Where-Object { $_.DistinguishedName -notmatch "admin" } | Select-Object SamAccountName
        } -Credential $creds | Sort-Object -Property SamAccountName).SamAccountName | ConvertTo-Json | Out-file $file -Force
        Write-Host "There have been new users added to Active Directory and this script will create new file with updated users"
    }
    else {
        Write-Host "No new users added. Exiting"
    }
}
