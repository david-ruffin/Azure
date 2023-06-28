# Add perms to an AD user that has multiple sub-domains
#Check if user exists in sub domain: This requires List Contents permission on the domain or OU. The dsacls command for this is: dsacls $_ /I:S /G "ACME\svc_account:LC;;user"

#If / when user is located, get all users info, group membership, etc: This requires Read All Properties permission on the User object. The dsacls command for this is: dsacls $_ /I:S /G "ACME\svc_account:RP;;user"

#Reset password: You already have this permission with dsacls $_ /I:S /G "ACME\svc_account:CA;Reset Password;User"

#Remove all group membership: This requires Write Property permission on the memberOf attribute of the User object. You already have this permission with dsacls $_ /I:S /G "ACME\svc_account:WP;memberOf;user"

#Move to terminated OU: This requires Delete and Create permissions on the User object. The dsacls command for this is: dsacls $_ /I:S /G "ACME\svc_account:DC;user" and dsacls $_ /I:S /G "ACME\svc_account:CC;user"

#Disable user account: This requires Write Property permission on the userAccountControl attribute of the User object. You already have this permission with dsacls $_ /I:S /G "ACME\svc_account:WP;userAccountControl;user"

#Edit Description property: This requires Write Property permission on the description attribute of the User object. The dsacls command for this is: dsacls $_ /I:S /G "ACME\svc_account:WP;description;user"
#https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771151(v=ws.10)

$AccountOUs = "OU=Accounts,DC=1,DC=ACME,DC=ORG", "OU=Accounts,DC=2,DC=ACME,DC=ORG", "OU=Accounts,DC=3,DC=ACME,DC=ORG", "OU=Accounts,DC=4,DC=ACME,DC=ORG"

$AccountOUs | foreach {
    dsacls $_ /I:S /G "ACME\svc_user:LC;;user"
    dsacls $_ /I:S /G "ACME\svc_user:RP;;user"
    dsacls $_ /I:S /G "ACME\svc_user:CA;Reset Password;User"
    dsacls $_ /I:S /G "ACME\svc_user:WP;memberOf;user"
    dsacls $_ /I:S /G "ACME\svc_user:DC;user"
    dsacls $_ /I:S /G "ACME\svc_user:CC;user"
    dsacls $_ /I:S /G "ACME\svc_user:WP;userAccountControl;user"
    dsacls $_ /I:S /G "ACME\svc_user:WP;description;user"
    } 
