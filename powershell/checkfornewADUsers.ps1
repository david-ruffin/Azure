# When using from linux to windows, the following dependencies must be installed in Powershell on linux
# pwsh -Command 'Install-Module -Name PSWSMan -Force'
# sudo pwsh -Command 'Install-WSMan'

# Declare variables

$file = '/var/lib/rundeck/ad-users.json'
$ADSearchBase = 'OU=Employees,DC=AMTWOUNDCARE,DC=com'
$DCServerName = 'amtdc5.amtwoundcare.com'

# If the file does not exist, create it.
if (-not(Test-Path -Path $file -PathType Leaf)) {
    try {
        Invoke-Command -ComputerName $DCServerName -ScriptBlock {
            Get-ADUser -SearchBase $using:ADSearchBase -Filter { enabled -eq $true } | Where-Object { $_.DistinguishedName -notmatch "admin" }
        }  | Select-Object SamAccountName | Sort-Object -Property SamAccountName | ConvertTo-Json | Out-file $file
        Write-Host "The file [$file] has been created."
    }
    catch {
        throw $_.Exception.Message
    }
}
# If the file already exists, check to see if new users were added to AD
else {
    $get_users = Invoke-Command -ComputerName $DCServerName -ScriptBlock {
        Get-ADUser -SearchBase $using:ADSearchBase -Filter { enabled -eq $true } | Where-Object { $_.DistinguishedName -notmatch "admin" }
    } | Select-Object SamAccountName | Sort-Object -Property SamAccountName # You may need to add credentials to this command
    # Compare Results
    if ($get_users.Count -ne (get-content $file | ConvertFrom-Json).count) {
        
        # There have been new users added to Active Directory and this script will create new file with updated users
        Invoke-Command -ComputerName $DCServerName -ScriptBlock {
            Get-ADUser -SearchBase $using:ADSearchBase -Filter { enabled -eq $true } | Where-Object { $_.DistinguishedName -notmatch "admin" }
        } | Select-Object SamAccountName | Sort-Object -Property SamAccountName | ConvertTo-Json | Out-file $file
        Write-Host "There have been new users added to Active Directory and this script will create new file with updated users"
    }else{
        Write-Host "No new users added. Exiting"
    }
}
