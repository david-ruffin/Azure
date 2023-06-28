# Add perms to an AD user that has multiple sub-domains
#https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771151(v=ws.10)

$AccountOUs = "OU=Accounts,DC=1,DC=ACME,DC=ORG", "OU=Accounts,DC=2,DC=ACME,DC=ORG", "OU=Accounts,DC=3,DC=ACME,DC=ORG", "OU=Accounts,DC=4,DC=ACME,DC=ORG"

$AccountOUs | foreach {
    dsacls $_ /I:S /G "ACME\svc_account:SDRCWDWO;;user"
    dsacls $_ /I:S /G "ACME\svc_account:WP;memberOf;user"
    dsacls $_ /I:S /G "ACME\svc_account:WP;userAccountControl;user"
    dsacls $_ /I:S /G "ACME\svc_account:CA;Reset Password;User"
    } 
