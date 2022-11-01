# get files over 1 year old and sort them by size
$folder = 'E:\Appeals Batches'
$oldfiles = Get-ChildItem -Recurse -Path $folder | Where-Object {$_.LastWriteTime -lt (Get-Date).AddYears(-1)}
$Results = foreach ($FL_Item in $oldfiles)
    {
    [PSCustomObject]@{
        Name = $FL_Item.Name
        Location = $FL_Item.Directory
        Size_MB = '{0,7:N2}' -f ($FL_Item.Length / 1MB)
        }
    }
$Results | sort-object -Property Size_MB -Descending
