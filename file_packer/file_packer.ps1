<#
.SYNOPSIS
    Packs and unpacks directories to/from a single markdown file with tagged content blocks.
.DESCRIPTION
    PACK MODE: Recursively collects files from a directory and stores them in a single markdown file
    with START-CODE/END-CODE tags. For JSON files, extracts metadata fields.
    
    UNPACK MODE: Reads a packed markdown file and recreates the original directory structure.
    With new features for selective unpacking.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("pack", "unpack", "menu")]
    [string]$Mode = "menu",
    
    [Parameter(Mandatory=$false)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$All,
    
    [Parameter(Mandatory=$false)]
    [string]$Select,
    
    [Parameter(Mandatory=$false)]
    [switch]$NonInteractive
)

$START_TAG_PREFIX = "<<<begin-file-content_"
$START_TAG_SUFFIX = ">>>"
$END_TAG_PREFIX = "<<<end-file-content_"
$END_TAG_SUFFIX = ">>>"
$METADATA_FIELDS = @("NAME", "Description", "CLASS", "Requirements")

function Show-Menu {
    Write-Host "`n=== FILE PACKER TOOL ===" -ForegroundColor Cyan
    Write-Host "Packs directories to markdown files and unpacks them back" -ForegroundColor Gray
    Write-Host ""
    Write-Host "1. Pack Directory (Create single MD file)"
    Write-Host "2. Unpack File (Recreate directory structure)"
    Write-Host "3. Exit"
    Write-Host ""
    $choice = Read-Host "Select an option (1-3)"
    return $choice
}

function Get-UserConfirmation {
    param([string]$Message)
    $response = Read-Host "$Message (Y/N)"
    return $response -eq 'Y' -or $response -eq 'y'
}

function Extract-JsonMetadata {
    param([string]$FilePath)
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $json = $content | ConvertFrom-Json -ErrorAction Stop
        
        $metadata = @()
        foreach ($field in $METADATA_FIELDS) {
            if ($json.PSObject.Properties.Name -contains $field) {
                $value = $json.$field
                $metadata += "$field=$value"
            }
        }
        
        if ($metadata.Count -gt 0) {
            return "METADATA: " + ($metadata -join " | ")
        }
    }
    catch {
        # Not a valid JSON or error reading, return empty
    }
    
    return ""
}

function Pack-Directory {
    param(
        [string]$SourceDir,
        [string]$OutputFile
    )
    
    if (-not (Test-Path $SourceDir)) {
        Write-Error "Source directory does not exist: $SourceDir"
        return $false
    }
    
    $includeSubDirs = Get-UserConfirmation "Include subdirectories?"
    
    Write-Host "`nPacking directory: $SourceDir" -ForegroundColor Green
    Write-Host "Output file: $OutputFile" -ForegroundColor Green
    if ($includeSubDirs) {
        Write-Host "Mode: Recursive (including subdirectories)" -ForegroundColor Yellow
    } else {
        Write-Host "Mode: Non-recursive (top-level only)" -ForegroundColor Yellow
    }
    
    # Create output directory if needed
    $outputDir = Split-Path $OutputFile -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Start building the markdown content
    $markdownContent = @()
    $markdownContent += "# PACKED DIRECTORY: $SourceDir"
    $markdownContent += "# CREATED: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdownContent += "# PACKER VERSION: 1.0"
    $markdownContent += ""
    $markdownContent += "----------------------------------------"
    $markdownContent += ""
    
    # Get files based on recursion preference
    if ($includeSubDirs) {
        $files = Get-ChildItem -Path $SourceDir -File -Recurse
    } else {
        $files = Get-ChildItem -Path $SourceDir -File
    }
    
    $fileCount = 0
    
    foreach ($file in $files) {
        $fileCount++
        $relativePath = $file.FullName.Substring($SourceDir.Length + 1)
        
        Write-Host "Processing: $relativePath" -ForegroundColor Gray
        
        # Build the header tag
        $headerTag = "$START_TAG_PREFIX$relativePath (numbering $fileCount of $($files.Count))$START_TAG_SUFFIX"
        
        # Add to markdown
        $markdownContent += $headerTag
        $markdownContent += ""
        
        # If JSON, extract metadata
        if ($file.Extension -eq ".json") {
            $metadata = Extract-JsonMetadata -FilePath $file.FullName
            if ($metadata) {
                $markdownContent += $metadata
                $markdownContent += ""
            }
        }
        
        # Add file content
        $content = Get-Content -Path $file.FullName -Raw
        $markdownContent += $content
        
        # Add end tag
        $markdownContent += ""
        $markdownContent += "$END_TAG_PREFIX$relativePath (numbering $fileCount of $($files.Count))$END_TAG_SUFFIX"
        $markdownContent += ""
        $markdownContent += "----------------------------------------"
        $markdownContent += ""
    }
    
    # Write the complete markdown file
    $markdownContent | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "`nSuccessfully packed $fileCount files to: $OutputFile" -ForegroundColor Green
    return $true
}

function Get-FileListFromMarkdown {
    param([string]$InputFile)
    
    if (-not (Test-Path $InputFile)) {
        Write-Error "Input file does not exist: $InputFile"
        return $null
    }
    
    # Read the markdown file
    $content = Get-Content -Path $InputFile -Raw
    
    # Regex pattern to match file blocks
    $pattern = [regex]::Escape($START_TAG_PREFIX) + '(?<filepath>.*?)' + [regex]::Escape($START_TAG_SUFFIX) + 
               '(?<content>.*?)' + 
               [regex]::Escape($END_TAG_PREFIX) + '(?<endpath>.*?)' + [regex]::Escape($END_TAG_SUFFIX)
    
    $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    $fileList = @()
    $index = 1
    
    foreach ($match in $matches) {
        $filePath = $match.Groups['filepath'].Value.Trim()
        # Remove the numbering suffix if present
        if ($filePath -match '^(.*?)\s+\(numbering\s+\d+\s+of\s+\d+\)$') {
            $filePath = $Matches[1]
        }
        
        $fileList += [PSCustomObject]@{
            Index = $index
            Path = $filePath
            Content = $match.Groups['content'].Value.Trim()
        }
        
        $index++
    }
    
    return $fileList
}

function Select-FilesForUnpacking {
    param(
        [array]$FileList,
        [switch]$All,
        [string]$Select,
        [switch]$NonInteractive
    )
    
    # If -All is specified, return all files
    if ($All) {
        return $FileList
    }
    
    # If -Select is specified, parse the selection
    if ($Select) {
        $selectedIndices = @()
        $selections = $Select -split ','
        
        foreach ($selection in $selections) {
            $selection = $selection.Trim()
            
            # Check if it's a range (e.g., 1-5)
            if ($selection -match '^\d+-\d+$') {
                $rangeParts = $selection -split '-'
                $start = [int]$rangeParts[0]
                $end = [int]$rangeParts[1]
                
                for ($i = $start; $i -le $end; $i++) {
                    if ($i -ge 1 -and $i -le $FileList.Count) {
                        $selectedIndices += $i
                    }
                }
            }
            # Check if it's a single number
            elseif ($selection -match '^\d+$') {
                $index = [int]$selection
                if ($index -ge 1 -and $index -le $FileList.Count) {
                    $selectedIndices += $index
                }
            }
        }
        
        # Return the selected files
        return $FileList | Where-Object { $selectedIndices -contains $_.Index }
    }
    
    # If -NonInteractive is specified, throw an error
    if ($NonInteractive) {
        Write-Error "Non-interactive mode requires either -All or -Select parameter"
        return $null
    }
    
    # Interactive mode - show file list and prompt for selection
    Write-Host "`nFiles in packed archive:" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    foreach ($file in $FileList) {
        Write-Host ("{0,3}: {1}" -f $file.Index, $file.Path) -ForegroundColor Gray
    }
    Write-Host "----------------------------------------"
    Write-Host "`nSelection options:" -ForegroundColor Yellow
    Write-Host "  all          - Extract all files"
    Write-Host "  1,3,7        - Extract specific files"
    Write-Host "  2-5          - Extract a range of files"
    Write-Host "  1,2-4,9      - Extract a combination"
    Write-Host ""
    
    do {
        $selection = Read-Host "Enter your selection (or 'all' for all files)"
        
        if ($selection -eq "all") {
            return $FileList
        }
        
        # Try to parse the selection
        $selectedFiles = Select-FilesForUnpacking -FileList $FileList -Select $selection
        if ($selectedFiles -ne $null) {
            return $selectedFiles
        }
        
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
    } while ($true)
}

function Unpack-Markdown {
    param(
        [string]$InputFile,
        [string]$OutputDir,
        [switch]$All,
        [string]$Select,
        [switch]$NonInteractive
    )
    
    if (-not (Test-Path $InputFile)) {
        Write-Error "Input file does not exist: $InputFile"
        return $false
    }
    
    Write-Host "`nUnpacking file: $InputFile" -ForegroundColor Green
    Write-Host "Output directory: $OutputDir" -ForegroundColor Green
    
    # Create output directory
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Get file list from markdown
    $fileList = Get-FileListFromMarkdown -InputFile $InputFile
    
    if ($fileList -eq $null -or $fileList.Count -eq 0) {
        Write-Error "No files found in packed archive"
        return $false
    }
    
    # Select files to unpack
    $selectedFiles = Select-FilesForUnpacking -FileList $fileList -All:$All.IsPresent -Select $Select -NonInteractive:$NonInteractive.IsPresent
    
    if ($selectedFiles -eq $null) {
        return $false
    }
    
    $fileCount = 0
    
    foreach ($fileInfo in $selectedFiles) {
        $filePath = $fileInfo.Path
        $fileContent = $fileInfo.Content
        
        $fullPath = Join-Path $OutputDir $filePath
        
        Write-Host "Extracting: $filePath" -ForegroundColor Gray
        
        # Create directory if needed
        $dir = Split-Path $fullPath -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Remove metadata line if present
        if ($fileContent -match "^METADATA: .+?`r?`n`r?`n") {
            $fileContent = $fileContent -replace "^METADATA: .+?`r?`n`r?`n", ""
        }
        
        # Write file content
        $fileContent | Out-File -FilePath $fullPath -Encoding UTF8 -NoNewline
        
        $fileCount++
    }
    
    Write-Host "`nSuccessfully extracted $fileCount files to: $OutputDir" -ForegroundColor Green
    return $true
}

# Main execution
switch ($Mode) {
    "menu" {
        while ($true) {
            $choice = Show-Menu
            
            switch ($choice) {
                "1" {
                    $source = Read-Host "`nEnter source directory path"
                    $target = Read-Host "Enter output markdown file path (e.g., C:\backup\files.md)"
                    Pack-Directory -SourceDir $source -OutputFile $target
                    Read-Host "`nPress Enter to continue..."
                }
                "2" {
                    $source = Read-Host "`nEnter packed markdown file path"
                    $target = Read-Host "Enter output directory path"
                    
                    # Check if we have non-interactive parameters
                    if ($All -or $Select -or $NonInteractive) {
                        Unpack-Markdown -InputFile $source -OutputDir $target -All:$All.IsPresent -Select $Select -NonInteractive:$NonInteractive.IsPresent
                    } else {
                        Unpack-Markdown -InputFile $source -OutputDir $target
                    }
                    Read-Host "`nPress Enter to continue..."
                }
                "3" {
                    Write-Host "Goodbye!" -ForegroundColor Cyan
                    exit
                }
                default {
                    Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    }
    "pack" {
        if (-not $SourcePath -or -not $TargetPath) {
            Write-Error "SourcePath and TargetPath are required for pack mode"
            exit 1
        }
        Pack-Directory -SourceDir $SourcePath -OutputFile $TargetPath
    }
    "unpack" {
        if (-not $SourcePath -or -not $TargetPath) {
            Write-Error "SourcePath and TargetPath are required for unpack mode"
            exit 1
        }
        Unpack-Markdown -InputFile $SourcePath -OutputDir $TargetPath -All:$All.IsPresent -Select $Select -NonInteractive:$NonInteractive.IsPresent
    }
}
