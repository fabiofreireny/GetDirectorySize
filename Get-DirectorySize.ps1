function Get-DirectorySize {
    <#
    .SYNOPSIS
    Calculates directory size and file count

    .DESCRIPTION
    Calculates directory size (sum of all file sizes) and file count in specified directory and (by default) all subdirectories

    Default is current directory

    .EXAMPLE
    List directory size of C:\ and every subdirectory

    Get-DirectorySize -directoryPath "c:\"
    #>

    param (
        [parameter(ValueFromPipeline=$True)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
            [string]$directoryPath = ".",
        [boolean]$recurse = $true
    )
    function doWork {
        param (
            [string]$directoryPath,
            [boolean]$recurse
        )

        #This is faster then running "gci -file" then "gci -directory" as file system is scanned only once
        $folder     = gci $directoryPath
        $subFolders = $folder | ? PSIsContainer -eq $true
        $files      = $folder | ? PSIsContainer -eq $false

        #If subfolders exist then recursively find their sizes
        if ($recurse) {
            if ($subFolders) {
                $subFolders | % {
                    Write-Verbose "Calculating $_"
                    doWork -directoryPath $_.FullName -recurse:$recurse
                }
            }
        }

        #Calculate file size totals
        if ($files) {
            $fileCount  = ($files | measure).Count
            $folderSize = [math]::round(($files | measure -sum -Property Length).sum / 1MB,3)
            $folderName = ($folder[0].PSParentPath -split ("::"))[1]
        } else {
            $fileCount  = 0
            $folderSize = 0
            $folderName = $directoryPath
        }

        $property = [PSCustomObject]@{
            "FileCount" = $fileCount
            "SizeInMB"  = $folderSize
            "Folder"    = $folderName
        }

        $property
    }

    #In case a relative path is provided
    $directoryPath = (Convert-Path -path $directoryPath)

    doWork -directoryPath $directoryPath -recurse:$recurse

}