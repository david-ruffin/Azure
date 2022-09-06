 # Get current list of users that dont have MFA enabled and store in variable
$users = C:\Scripts\Get-MgMFAStatus.ps1 -withOutMFAOnly
#$users = Import-Csv "c:\scripts\MFAStatus-Sep-05-2022.csv"
# Get list of service account users that need to be removed from the final list
$service_accounts = (Get-ADUser -Filter * -SearchBase 'DC=amtwoundcare,DC=com' | 
    Where-Object { $_.DistinguishedName -like '*OU=Service Accounts,*' }).UserPrincipalName | sort
# Create ArrayList because you're not able to remove items from Array
[System.Collections.ArrayList]$demoArrayList= @()
# Convert Array to Arraylist object
$demoArrayList = $users
# Check
foreach ($i in 0..$service_accounts.count)
    {
    if ($service_accounts["$i"] -eq (($demoArrayList | where { $_.UserPrincipalName -eq $service_accounts["$i"] }).UserPrincipalName))
        {
            echo $service_accounts["$i"]
            
            $delete = $demoArrayList | where { $_.UserPrincipalName -eq $service_accounts["$i"] }
            $demoArrayList.Remove($delete)
        }
    
    }

$demoArrayList | ogv 
