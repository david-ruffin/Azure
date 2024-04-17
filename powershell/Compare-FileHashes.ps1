<#
.SYNOPSIS
    Performs file integrity checks between two servers by comparing SHA256 hashes of file samples.

.DESCRIPTION
    This script defines a script block to execute on each server which collects a sample of files from
    a specified directory, calculates their SHA256 hashes, and then compares these hashes between two
    specified servers to ensure integrity and consistency across server environments.

    The script is designed to be run with parameters for directories, seed for randomness, and credentials
    for accessing the servers.

.PARAMETER directories
    An array of directory paths to be checked across the servers.

.PARAMETER seed
    A numeric value used to seed the random selection of files, ensuring reproducibility of the sample.

.PARAMETER cred
    A PSCredential object containing the credentials used for authentication on the remote servers.

.PARAMETER server1
    The hostname or IP address of the first server where files will be checked.

.PARAMETER server2
    The hostname or IP address of the second server where files will be checked.

.EXAMPLE
    $dirs = @('C:\Files', 'D:\Backup')
    $credential = Get-Credential
    .\Compare-FileHashes.ps1 -directories $dirs -seed 12345 -cred $credential -server1 'Server01' -server2 'Server02'

    This example runs the script for directories 'C:\Files' and 'D:\Backup' across two servers 'Server01' and 'Server02'
    using the same seed for random file selection and user-provided credentials.

.NOTES
    Author: Vyente Ruffin
    Date: 04-17-24
    Last Modified: 04-17-24
    Version: 1.0

    Ensure that both servers have PowerShell remoting enabled and accessible for the user with the provided credentials.
    The user must have sufficient permissions to read files in the specified directories on both servers.

#>
$cred = Get-Credential # Add auth creds
# Define the servers and multiple directory paths
$server1 = "server1@contoso.com"
$server2 = "server2@contoso.com"
$directories = @('c:\crc\autoBid_Project', 'c:\crc\Backorders', 'c:\crc\FEDEX')  # Add array of directories to compare
$seed = 2024  # Set a consistent seed for random selection
$exportLocation = "c:\Results.csv" # Location for exported csv
$samplePercentage = .01 # Set sample percentage

# Define the script block to be executed on remote servers for file integrity checks
$scriptBlock = {
    param($path, $seed)  # Accepts a directory path and a random seed for file sampling

    # Retrieve all files from the specified directory and select a random sample based on the percentage
    $allFiles = Get-ChildItem -Path $path -Recurse -File
    # Calculate sample size as the ceiling value of 1% of the total file count
    $sampleSize = [math]::Ceiling($allFiles.Count * $using:samplePercentage)
    # Select a random subset of files based on the computed sample size and seed
    $randomSourceFiles = $allFiles | Get-Random -Count $sampleSize -SetSeed $seed

    # Initialize a hashtable to store the SHA256 hashes of the selected files
    $hashes = @{}
    foreach ($file in $randomSourceFiles) {
        # Compute and store the SHA256 hash for each file in the sample
        $hashes[$file.FullName] = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
    }
    return $hashes  # Return the hashtable containing file paths and their corresponding hashes
}

# Initialize an array to collect the results of hash comparisons across all directories
$allComparisonResults = @()

# Loop through each directory in a predefined list to perform hash checks
foreach ($directory in $directories) {
    # Execute the script block on the first server, passing the directory and seed
    $sourceHashes = Invoke-Command -ComputerName $server1 -ScriptBlock $scriptBlock -ArgumentList $directory, $seed -Credential $cred
    # Execute the script block on the second server for the same directory and seed
    $destinationHashes = Invoke-Command -ComputerName $server2 -ScriptBlock $scriptBlock -ArgumentList $directory, $seed -Credential $cred

    # Compare the hashes collected from both servers for each file
    $comparisonResults = foreach ($sourcePath in $sourceHashes.Keys) {
        $destinationPath = $sourcePath  # Paths are assumed identical across servers
        $sourceHash = $sourceHashes[$sourcePath]
        $destinationHash = $destinationHashes[$destinationPath]
        # Determine if the hashes match
        $match = $sourceHash -eq $destinationHash

        # Create a custom object to store comparison details for each file
        [PSCustomObject]@{
            SourceServer = $server1
            DestinationServer = $server2
            SourcePath = $sourcePath
            DestinationPath = $destinationPath
            SourceHash = $sourceHash
            DestinationHash = $destinationHash
            Match = if ($match) {'True'} else {'False'}
        }
    }
    # Accumulate the comparison results from each directory into a master list
    $allComparisonResults += $comparisonResults
}

# Output all comparison results in grid view
$allComparisonResults | ogv -PassThru

# Output all comparison results in a formatted table
$allComparisonResults | Export-csv -Path $exportLocation -Force -NoTypeInformation 
