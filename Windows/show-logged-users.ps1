# Run query user and parse the output
$sessionInfo = query user | ForEach-Object {
    $fields = ($_ -split '\s{2,}')
    [PSCustomObject]@{
        Username     = $fields[0]
        SessionName  = $fields[1]
        SessionID    = $fields[2]
        State        = $fields[3]
        IdleTime     = $fields[4]
        LogonTime    = $fields[5]
    }
}

# Display the session information
$sessionInfo | Format-Table -AutoSize
