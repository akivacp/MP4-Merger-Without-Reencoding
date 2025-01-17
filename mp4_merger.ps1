# Prompt for the input folder
Add-Type -AssemblyName System.Windows.Forms
$DefaultInputFolder = Get-Location
$InputFolder = $DefaultInputFolder
while ($true) {
    Write-Host "Default input folder is set to: $InputFolder" -ForegroundColor Cyan
    $FolderResponse = (Read-Host "Is this the correct folder? (y/n/d) [default: y]").ToLower()
    if ([string]::IsNullOrWhiteSpace($FolderResponse)) { $FolderResponse = 'y' }
    if ($FolderResponse -eq 'y') {
        break
    } elseif ($FolderResponse -eq 'd') {
        $InputFolder = $DefaultInputFolder
        continue
    } elseif ($FolderResponse -eq 'n') {
        $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($FolderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $InputFolder = $FolderBrowserDialog.SelectedPath
        } else {
            Write-Host "No folder selected. Defaulting to: $DefaultInputFolder" -ForegroundColor Yellow
            $InputFolder = $DefaultInputFolder
        }
    } else {
        Write-Host "Invalid input. Please enter 'y', 'n', or 'd'." -ForegroundColor Red
    }
}

# Prompt for the output folder
$DefaultOutputFolder = Join-Path -Path (Get-Location) -ChildPath "converted"
$OutputFolder = $DefaultOutputFolder
while ($true) {
    Write-Host "Default output folder is set to: $OutputFolder" -ForegroundColor Cyan
    $FolderResponse = (Read-Host "Is this the correct folder? (y/n/d) [default: y]").ToLower()
    if ([string]::IsNullOrWhiteSpace($FolderResponse)) { $FolderResponse = 'y' }
    if ($FolderResponse -eq 'y') {
        if (-not (Test-Path -Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        }
        break
    } elseif ($FolderResponse -eq 'd') {
        $OutputFolder = $DefaultOutputFolder
        continue
    } elseif ($FolderResponse -eq 'n') {
        $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($FolderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $OutputFolder = $FolderBrowserDialog.SelectedPath
        } else {
            Write-Host "No folder selected. Defaulting to: $DefaultOutputFolder" -ForegroundColor Yellow
            $OutputFolder = $DefaultOutputFolder
        }
    } else {
        Write-Host "Invalid input. Please enter 'y', 'n', or 'd'." -ForegroundColor Red
    }
}

# Get all .mp4 files in the input folder
$Mp4Files = Get-ChildItem -Path $InputFolder -Filter "*.mp4"
if ($Mp4Files.Count -eq 0) {
    Write-Host "No .mp4 files found in the input folder." -ForegroundColor Red
    exit
}

# Extract recording date from metadata and adjust to Eastern Time for GoPro files
$Mp4Files = $Mp4Files | ForEach-Object {
    $RecordingDate = ffmpeg -i "$($_.FullName)" 2>&1 | Select-String "creation_time" | ForEach-Object {
        ($_ -match "creation_time\s*:\s*(.+)") | Out-Null
        [datetime]::Parse($matches[1])
    } | Select-Object -First 1

    if (-not $RecordingDate) {
        $RecordingDate = [datetime]::MinValue  # Use a default value if metadata is missing
    }

    # Adjust time for GoPro files (GH0* prefix)
    if ($_.Name -like "GH0*") {
        $RecordingDate = $RecordingDate.AddHours(4)
    }

    [PSCustomObject]@{
        Name = $_.Name
        Size = if ($_.Length -gt 1GB) {
            "{0:N2} GB" -f ($_.Length / 1GB)
        } else {
            "{0:N2} MB" -f ($_.Length / 1MB)
        }
        RecordingDate = $RecordingDate
        FullPath = $_.FullName
    }
} | Sort-Object RecordingDate

# Display the files to be processed with detailed information in a table format
Write-Host "The following .mp4 files will be processed in the order shown:" -ForegroundColor Cyan
Write-Host "" # Empty line for better readability
Write-Output "Index  Name                           Size        Recording Date"
Write-Output "-----------------------------------------"
$Mp4Files | ForEach-Object -Begin { $i = 0 } -Process {
    "{0,-5} {1,-30} {2,-10} {3}" -f ($i++), $_.Name, $_.Size, $_.RecordingDate
} | Write-Output
Write-Output "-----------------------------------------"

# Allow user to exclude files using a file browser
$RemovedFiles = @()
if ((Read-Host "Do you want to remove files using a file browser? (y/n/q)").ToLower() -eq 'y') {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "MP4 files (*.mp4)|*.mp4"
    $OpenFileDialog.Multiselect = $true
    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $ExcludedFiles = $OpenFileDialog.FileNames
        $RemovedFiles = $Mp4Files | Where-Object { $ExcludedFiles -contains $_.FullPath }
        $Mp4Files = $Mp4Files | Where-Object { $ExcludedFiles -notcontains $_.FullPath }
    }
} elseif ($FolderResponse -eq 'q') {
    while ($true) {
        $QuitConfirmation = (Read-Host "Are you sure you want to quit? (y/n/q)").ToLower()
        if ($QuitConfirmation -eq 'y') {
            Write-Host "Exiting the script." -ForegroundColor Red
            exit
        } elseif ($QuitConfirmation -eq 'n') {
            Write-Host "Returning to file selection..." -ForegroundColor Yellow
            break
        } elseif ($QuitConfirmation -eq 'q') {
            Write-Host "Exiting the script." -ForegroundColor Red
            exit
        } else {
            Write-Host "Invalid input. Please enter 'y', 'n', or 'q'." -ForegroundColor Red
        }
    }
}

# Allow user to add new files using a file browser
$AddedFiles = @()
if ((Read-Host "Do you want to add more files to the process? (y/n/q)").ToLower() -eq 'y') {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "MP4 files (*.mp4)|*.mp4"
    $OpenFileDialog.Multiselect = $true
    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $AdditionalFiles = $OpenFileDialog.FileNames | ForEach-Object { Get-Item $_ }
        $AddedFiles = $AdditionalFiles | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Size = if ($_.Length -gt 1GB) {
                    "{0:N2} GB" -f ($_.Length / 1GB)
                } else {
                    "{0:N2} MB" -f ($_.Length / 1MB)
                }
                RecordingDate = [datetime]::MinValue  # Default value, as metadata may not be fetched here
                FullPath = $_.FullName
            }
        }
        $Mp4Files += $AddedFiles
    }
} elseif ($FolderResponse -eq 'q') {
    while ($true) {
        $QuitConfirmation = (Read-Host "Are you sure you want to quit? (y/n/q)").ToLower()
        if ($QuitConfirmation -eq 'y') {
            Write-Host "Exiting the script." -ForegroundColor Red
            exit
        } elseif ($QuitConfirmation -eq 'n') {
            Write-Host "Returning to file selection..." -ForegroundColor Yellow
            break
        } elseif ($QuitConfirmation -eq 'q') {
            Write-Host "Exiting the script." -ForegroundColor Red
            exit
        } else {
            Write-Host "Invalid input. Please enter 'y', 'n', or 'q'." -ForegroundColor Red
        }
    }
}

# Display the updated list of files with changes
Write-Host "Updated list of files to be processed:" -ForegroundColor Cyan
if ($RemovedFiles.Count -gt 0) {
    Write-Host "Removed files:" -ForegroundColor Yellow
    $RemovedFiles | ForEach-Object {
        "{0,-30} {1,-10}" -f $_.Name, $_.Size
    }
}
if ($AddedFiles.Count -gt 0) {
    Write-Host "Added files:" -ForegroundColor Green
    $AddedFiles | ForEach-Object {
        "{0,-30} {1,-10}" -f $_.Name, $_.Size
    }
}
Write-Host "" # Empty line for better readability
Write-Output "Index  Name                           Size        Recording Date"
Write-Output "-----------------------------------------"
$Mp4Files | ForEach-Object -Begin { $i = 0 } -Process {
    "{0,-5} {1,-30} {2,-10} {3}" -f ($i++), $_.Name, $_.Size, $_.RecordingDate
} | Write-Output
Write-Output "-----------------------------------------"

while ($true) {
    $Response = (Read-Host "Do you want to proceed with these files? (y/n/q)").ToLower()
    if ($Response -eq 'y') {
        break
    } elseif ($Response -eq 'n') {
        Write-Host "Returning to file selection for further changes." -ForegroundColor Yellow
    } elseif ($Response -eq 'q') {
        while ($true) {
            $QuitConfirmation = (Read-Host "Are you sure you want to quit? (y/n/q)").ToLower()
            if ($QuitConfirmation -eq 'y') {
                Write-Host "Exiting the script." -ForegroundColor Red
                exit
            } elseif ($QuitConfirmation -eq 'n') {
                Write-Host "Returning to the previous question..." -ForegroundColor Yellow
                break
            } elseif ($QuitConfirmation -eq 'q') {
                Write-Host "Exiting the script." -ForegroundColor Red
                exit
            } else {
                Write-Host "Invalid input. Please enter 'y', 'n', or 'q'." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Invalid input. Please enter 'y', 'n', or 'q'." -ForegroundColor Red
    }
}

# Convert each .mp4 file to .ts using FFmpeg
$TsFiles = @()
foreach ($File in $Mp4Files) {
    $TsFile = Join-Path -Path $OutputFolder -ChildPath (($File.Name -replace ".mp4$", ".ts"))
    ffmpeg -i "$($File.FullPath)" -c copy -bsf:v h264_mp4toannexb "$TsFile" -y
    if (-not $?) {
        Write-Host "Error converting $($File.Name) to .ts" -ForegroundColor Red
        exit
    }
    $TsFiles += $TsFile
}

# Create a list file for FFmpeg input
$ListFilePath = Join-Path -Path $OutputFolder -ChildPath "file_list.txt"
$TsFiles | ForEach-Object { "file '$($_)'" } | Set-Content -Path $ListFilePath

# Generate output file name based on input folder name and timestamp
$InputFolderName = Split-Path -Path $InputFolder -Leaf
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$OutputFileName = "$InputFolderName`_$Timestamp.mp4"
$OutputFilePath = Join-Path -Path $OutputFolder -ChildPath $OutputFileName

# Merge .ts files into a single .mp4 file using FFmpeg
ffmpeg -f concat -safe 0 -i "$ListFilePath" -c copy "$OutputFilePath" -y
if ($?) {
    Write-Host "Successfully created $OutputFilePath" -ForegroundColor Green
} else {
    Write-Host "Error creating the merged .mp4 file" -ForegroundColor Red
        exit
}

# Ask if .ts files should be deleted
$DeleteTsFiles = (Read-Host "Do you want to delete the temporary .ts files? (y/n)").ToLower()
if ($DeleteTsFiles -eq 'y') {
    Remove-Item -Path $TsFiles -Force
    Write-Host "Temporary .ts files have been deleted." -ForegroundColor Green
} else {
    Write-Host "Temporary .ts files have been retained." -ForegroundColor Yellow
}

# Clean up the list file
Remove-Item -Path $ListFilePath -Force
Write-Host "Temporary file list has been cleaned up." -ForegroundColor Green
