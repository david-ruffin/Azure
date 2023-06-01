Import-Module AWSPowerShell
Set-AWSCredential -accesskey 'sef' -SecretKey 'sef' -StoreAs default
Set-DefaultAWSRegion -Region us-west-2
# Get all Workspaces
$workspaces = Get-WKSWorkspace -Region us-west-2 -workspaceid "ws-1", "ws-2"

# Set workspaces to ALWAYS_ON
$workspaces | ForEach-Object {Edit-WKSWorkspaceProperty -WorkspaceId $_.WorkspaceId -Region $Region -WorkspaceProperties_RunningMode ALWAYS_ON}

# Display results of workspace with Running Mode
$workspaces | foreach {
    $runningState = (Get-WKSWorkspace -Region us-west-2 -WorkSpaceId $_.WorkspaceId).WorkspaceProperties.RunningMode
    New-Object -Type PSObject -Property @{
        Username = $_.Username
        WorkspaceID = $_.WorkspaceId
        RunningState = $runningState
    }
} | Sort-Object Username | Format-Table -AutoSize
