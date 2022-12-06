#Install MSAL.PS module for all users (requires admin rights)
Install-Module MSAL.PS -Scope CurrentUser -Force
 
#Generate Access Token to use in the connection string to MSGraph
$AppId = 'xxx'
$TenantId = 'xxx'
$ClientSecret = 'xxx'
 
Import-Module MSAL.PS -Force
$MsalToken = Get-MsalToken -TenantId $TenantId -ClientId $AppId -ClientSecret ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
 
#Connect to Graph using access token
$Credential = ConvertTo-GraphCredential -MsalToken $MsalToken.AccessToken
$Body = EmailBody {
    EmailText -Text "Hello Dear Reader," -LineBreak
    EmailText -Text "I would like to introduce you to ", "PSWriteHTML", " way of writting emails. " -Color None, SafetyOrange, None -FontWeight normal, bold, normal
    EmailText -Text "You can create standard text, or more advanced text by simply using provided parameters. " -Color Red
    EmailText -Text @(
        "Write your ", "text", " in ", "multiple ways: ", " colors", " or ", "fonts", " or ", "text transformations!"
    ) -Color Blue, Red, Yellow, GoldenBrown, SeaGreen, None, Green, None, SafetyOrange -FontWeight normal, bold, normal, bold, normal, normal, normal, normal, normal -LineBreak
    EmailText -Text "You can create lists, but also a multi-column layout with them: " -LineBreak
    EmailLayout {
        EmailLayoutRow {
            EmailLayoutColumn {
                EmailList {
                    EmailListItem -Text "First item"
                    EmailListItem -Text "Second item"
                    EmailListItem -Text "Third item"
                    EmailList {
                        EmailListItem -Text "Nested item 1"
                        EmailListItem -Text "Nested item 2"
                    }
                } -Type Ordered -FontSize 15
            }
            EmailLayoutColumn {
                EmailList {
                    EmailListItem -Text "First item - but on the right"
                    EmailListItem -Text "Second item - but on the right"
                    EmailListItem -Text "Third item"
                    EmailList {
                        EmailListItem -Text "Nested item 1"
                        EmailListItem -Text "Nested item 2"
                    }
                } -Type Ordered -FontSize 10 -Color RedBerry
            }
        }
        EmailLayoutRow {
            EmailText -Text "Lets see how you can have multiple logos next to each other" -LineBreak
        }
        EmailLayoutRow {
            EmailLayoutColumn {
                EmailImage -Source "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png" -Width 150
            } -PaddingTop 30
            EmailLayoutColumn {
                EmailImage -Source "https://evotec.pl/wp-content/uploads/2015/05/Logo-evotec-012.png" -Width 150
            } -PaddingTop 30
            EmailLayoutColumn {
                EmailImage -Source "https://upload.wikimedia.org/wikipedia/commons/9/96/Microsoft_logo_%282012%29.svg" -Width 150
            } -PaddingTop 30
            EmailLayoutColumn {
                EmailImage -Source "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Pepsi_logo_%282014%29.svg/2560px-Pepsi_logo_%282014%29.svg.png" -Width 150
            } -PaddingTop 30
        }
        EmailLayoutRow {
            EmailText -LineBreak
            EmailText -LineBreak
        }
        EmailLayoutRow {
            EmailText -Text "You can create tables: " -LineBreak
            EmailTable -DataTable (Get-Process | Select-Object -First 5 -Property Name, Id, PriorityClass, CPU, Product) -HideFooter
            EmailText -LineBreak
            EmailText -Text "Everything is customizable. " -Color California -FontStyle italic -TextDecoration underline
            EmailText -Text "You can even add images: " -LineBreak
            EmailImage -Source "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png" #-Width 200 -Height 200
            EmailText -Text "It's all just a command away. " -Color None -FontStyle normal -TextDecoration none
            EmailText -Text "You no longer have to use HTML/CSS, as it will be used for you!"
            EmailText -Text "With regards," -LineBreak
            EmailText -Text "Przemysław Kłys" -TextTransform capitalize -BackGroundColor Salmon
        }
    }
}
Send-EmailMessage -From 'david.ruffin@amtwoundcare.com' -To 'david.ruffin@amtwoundcare.com' -Credential $Credential -HTML $Body -Subject 'This is another test email' -Graph -Verbose -Priority Low -DoNotSaveToSentItems
Save-HTML -FilePath "test.html" -ShowHTML -HTML $Body
