# Chunky Moe's File Finder Version 1.1
# Date: 01/19/2025 
# Copyright 2025, All Rights Reserved, Chunky Moe
# https://x.com/Chunky_Moes
# ----------------------------------------------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
# Function to create clickable hyperlinks
function Format-Hyperlink {
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri] $Uri,
        [Parameter(Mandatory=$false, Position = 1)]
        [string] $Label
    )
    if (($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) -and -not $Env:WT_SESSION) {
        # Fallback for Windows users not inside Windows Terminal
        if ($Label) {
            return "$Label ($Uri)"
        }
        return "$Uri"
    }
    if ($Label) {
        return "`e]8;;$Uri`e\$Label`e]8;;`e\"
    }
    return "$Uri"
}

# Set console colors
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "Yellow"
# Clear the screen at the start
Clear-Host
# Play startup sound
[console]::Beep(1000, 200)  # Beep
[console]::Beep(500, 200)   # Boop
[console]::Beep(1000, 200)  # Beep
# Set title
$Host.UI.RawUI.WindowTitle = "Chunky Moe's Fast File Finder 1.1 - Copyright 2025"
# Announce program start
Write-Host "Chunky Moe's File Finder 1.1" -ForegroundColor Gray -BackgroundColor DarkBlue
Write-Host "Released 01/19/2025 - All Rights Reserved" -ForegroundColor Gray -BackgroundColor DarkBlue
Write-Host (Format-Hyperlink -Uri "https://x.com/Chunky_Moes" -Label "Chunky_Moes on X") -ForegroundColor Gray -BackgroundColor DarkBlue
Write-Host "" -ForegroundColor Yellow -BackgroundColor DarkBlue
do {
    # Ask user for file extension or pattern to search
    Write-Host " Use * as a wildcard. *dog will find all files named either just 'dog' or end in the word dog. " -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host " For example, hotdog and dog will be found, but doggone will not."
     Write-Host " To find any file with the word dog anywhere in it, use *dog*."
     Write-Host " This would return dog, hotdog, doggone, bun.dog and so on."
     Write-Host " "
     Write-Host " "
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "White"
    $filePattern = Read-Host "Enter the file pattern to search for (e.g., *.jpg, *dog*)"  
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "Yellow"
    # Validate the pattern
    if (-not $filePattern) {
        Write-Host "No file pattern specified. Exiting script." -ForegroundColor White -BackgroundColor Red
        exit
    }
    # Get all local drives
    $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    # Array to store job objects
    $jobs = @()
    # Total number of drives to scan
    $totalDrives = $drives.Count
    $processedDrives = 0
    # Start jobs for each drive
    foreach ($drive in $drives) {
        $job = Start-Job -ScriptBlock {
            param($driveLetter, $pattern)
            function Find-Files {
                param([string]$directory, [string]$pattern)
                try {
                    return Get-ChildItem -Path $directory -Recurse -Include $pattern -File -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Host "`n  - Error accessing directory: $directory" -ForegroundColor White -BackgroundColor Red
                    return @()
                }
            }
            $count = 0
            $directoryCounts = @{}
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "Yellow"
            Write-Host "`nScanning drive $($driveLetter):"
            $allFiles = @()
            try {
                $files = Find-Files -directory $driveLetter -pattern $pattern
                foreach ($file in $files) {
                    $allFiles += [PSCustomObject]@{
                        Name = $file.Name
                        FullPath = $file.FullName
                    }
                    $count++
                    $directory = [System.IO.Path]::GetDirectoryName($file.FullName)
                    if ($directoryCounts.ContainsKey($directory)) {
                        $directoryCounts[$directory]++
                    } else {
                        $directoryCounts[$directory] = 1
                    }
                }
                foreach ($dir in $directoryCounts.GetEnumerator()) {
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "Yellow"
                    Write-Host "    - $($dir.Key) : $($dir.Value) matching files"
                }
                Write-Host "  - Total matching files on $($driveLetter): $count"
            }
            catch {
                Write-Host "  - Error scanning drive $($driveLetter): $_" -ForegroundColor White -BackgroundColor Red
            }
            return [PSCustomObject]@{
                TotalCount = $count
                FilesFound = $allFiles
                DriveLetter = $driveLetter  
            }
        } -ArgumentList $drive.DeviceID, $filePattern
        $jobs += $job
    }
    # Progress indicator while waiting for jobs to complete
    while ($jobs.State -contains 'Running') {
        $completedJobs = @($jobs | Where-Object { $_.State -eq 'Completed' }).Count
        $percentComplete = [math]::Round(($completedJobs / $totalDrives) * 100, 2)
        # Reset colors before Write-Progress
        $Host.UI.RawUI.BackgroundColor = "DarkBlue"
        $Host.UI.RawUI.ForegroundColor = "Yellow"
        Write-Progress -Activity "Scanning Drives" -Status "Completed: $completedJobs of $totalDrives drives" -PercentComplete $percentComplete
        # Reset colors after Write-Progress if needed
        $Host.UI.RawUI.BackgroundColor = "DarkBlue"
        $Host.UI.RawUI.ForegroundColor = "Yellow"
        Start-Sleep -Seconds 1
    }
    # Sum up the results and prepare for logging
    $totalFiles = 0
    $cleanPattern = $filePattern -replace '\*', ''
    $logFile = "$(Get-Date -Format 'MM-dd-yyyy_HH.mm.ss') - $cleanPattern.log"
    $logContent = @()
    $logContent += "Search term: $filePattern"
    foreach ($job in $jobs) {
        $result = Receive-Job -Job $job
        $driveLetter = if ($job.Arguments -and $job.Arguments.Count -gt 1) { $job.Arguments[0] } else { $result.DriveLetter }
        $logContent += "`nScanning drive $($driveLetter):"
	Write-Host ""
        $logContent += "  - Total matching files on $($driveLetter): $($result.TotalCount)"
	Write-Host ""
        foreach ($file in $result.FilesFound) {
            $logContent += "    - $($file.Name) : $($file.FullPath)"
        }
        $totalFiles += $result.TotalCount
        $processedDrives++
    }
    # Set console colors
    $Host.UI.RawUI.BackgroundColor = "DarkBlue"
    $Host.UI.RawUI.ForegroundColor = "Yellow"
    # Add a blank line with correct color
    Write-Host ""
    # Clear the progress bar after all jobs are done
    Write-Progress -Activity "Scanning Drives" -Status "Completed" -Completed
    # Display total count
    Write-Host "`nTotal matching files across all drives: $totalFiles"
    # Write to log file
    $logContent += "`nTotal matching files across all drives: $totalFiles"
    $logContent | Out-File -FilePath $logFile
    # Play completion sound
    [console]::Beep(800, 300)  # A pleasant beep
    Write-Host ""
    Write-Host "Results have been logged to $logFile"
    # Ask if the user wants to perform another search
    Write-Host ""
    $continue = Read-Host "Do you want to perform another search? (yes/y/no/n)"
    $continue = $continue.ToLower()  # Convert to lowercase for case insensitivity
    if ($continue -in @('yes', 'y')) {
        # Clear the screen for the next iteration
        Clear-Host
    }
} while ($continue -in @('yes', 'y'))
# Announce program exit
Write-Host ""
[console]::Beep(800, 300)  # A pleasant beep
Write-Host "Thank you for using Chunky Moe's File Finder"