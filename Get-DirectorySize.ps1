function Get-DirectorySize {
    <#
    .SYNOPSIS
    Calculates directory size

    .DESCRIPTION
    Calculates directory size (sum of all file sizes) in specified directory and (optionally) all subdirectories

    Default is current directory

    .EXAMPLE
    List directory size of C:\ and every subdirectory

    Get-DirectorySize -directoryPath "c:\"
    #>

    param (
        [parameter(ValueFromPipeline=$True)]
            [string]$directoryPath = ".",
        [boolean]$recurse = $true,
        [parameter(DontShow)]
            [boolean]$firstCall = $true
    )

    #Initialize array, but only on first call
    if ($firstCall) {
        $result = @()
    }

    #This is faster then running "gci -file" then "gci -directory" as file system is scanned only once
    $folder     = gci $directoryPath
    $subFolders = $folder | ? PSIsContainer -eq $true
    $files      = $folder | ? PSIsContainer -eq $false

    #Calculate file size totals
    if ($files) {
        $folderSize = [math]::round(($files | measure -sum -Property Length).sum / 1MB,3)
        $folderName = ($folder[0].PSParentPath -split ("::"))[1]
    } else {
        $folderSize = 0
        $folderName = $directoryPath
    }

    $property = [PSCustomObject]@{
        "SizeInMB" = $folderSize
        "Folder"   = $folderName
    }

    $result += $property

    #If subfolders exist then recursively find their sizes
    if ($recurse) {
        if ($subFolders) {
            $subFolders | % {
                Write-Verbose "Calculating $_"
                Get-DirectorySize $_.FullName -firstCall:$false
            }
        }
    }

    $result
}