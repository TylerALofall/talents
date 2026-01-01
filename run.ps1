<#
.SYNOPSIS
    Tyler's Talent & Toolbox Thunder
.DESCRIPTION
    Commands: status, scan, approve, create-tool, run
    
    THE CHAIN (one move per scan):
    Scan 1: readme → information.json.pending
    Scan 2: information.json → log/toolbox-menu.json.pending  
    Scan 3: menu → log/toolbox-index.json.pending + DIFF → log.csv
#>

param(
    [Parameter(Position=0)]
    [ValidateSet("status", "scan", "approve", "create-tool", "run")]
    [string]$Command = "status",
    
    [string]$Toolname = "",
    [switch]$Yes,
    [switch]$PerFile
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
if (-not $Root) { $Root = Get-Location }

# Directories
$Cauldron = Join-Path $Root ".cauldron"
$Outbox = Join-Path $Root ".outbox"
$LogDir = Join-Path $Root "log"
$Pending = ".pending"
$Backup = ".bak"

# Ensure dirs
@($Cauldron, $Outbox, $LogDir, (Join-Path $Outbox "_receipts")) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ============================================================================
# HELPERS
# ============================================================================

function Get-Tools {
    Get-ChildItem -Path $Root -Directory | Where-Object {
        $_.Name -notin @(".cauldron", ".outbox", "log") -and -not $_.Name.StartsWith(".")
    }
}

function Get-PendingFiles {
    Get-ChildItem -Path $Root -Recurse -File -Filter "*$Pending" -ErrorAction SilentlyContinue
}

function Extract-ManifestFromReadme {
    param([string]$Path, [string]$Tool)
    
    $content = Get-Content $Path -Raw -Encoding UTF8
    $pattern = "(?s)<<<begin-$Tool-manifest-file_\d+_of_\d+>>>\s*(.*?)\s*<<<end-$Tool-manifest-file_\d+_of_\d+>>>"
    
    if ($content -match $pattern) {
        try {
            return $Matches[1] | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# ============================================================================
# STATUS
# ============================================================================

function Invoke-Status {
    Write-Host "=== TOOLBOX STATUS ===" -ForegroundColor Cyan
    Write-Host "Root: $Root"
    Write-Host ""
    
    $tools = Get-Tools
    Write-Host "Tools: $($tools.Count)" -ForegroundColor Green
    
    foreach ($t in $tools) {
        $name = $t.Name.ToLower()
        $readme = Join-Path $t.FullName "$name-instructions/$name-model-readme.md"
        $info = Join-Path $t.FullName "$name-information.json"
        $infoPending = "$info$Pending"
        
        $state = "???"
        if (Test-Path $infoPending) {
            $state = "info.pending (needs approve)"
        } elseif (Test-Path $info) {
            $state = "ready"
        } elseif (Test-Path $readme) {
            $state = "readme only (needs scan)"
        } else {
            $state = "no readme"
        }
        
        Write-Host "  $name : $state"
    }
    
    Write-Host ""
    $pending = Get-PendingFiles
    if ($pending.Count -gt 0) {
        Write-Host "Pending files: $($pending.Count)" -ForegroundColor Yellow
        foreach ($p in $pending) {
            $rel = $p.FullName.Replace($Root, "").TrimStart("\", "/")
            Write-Host "  $rel"
        }
    } else {
        Write-Host "No pending files." -ForegroundColor Green
    }
    
    # Check log files
    Write-Host ""
    $menuMaster = Join-Path $LogDir "toolbox-menu.json"
    $indexMaster = Join-Path $LogDir "toolbox-index.json"
    $logCsv = Join-Path $LogDir "log.csv"
    
    Write-Host "Log dir:"
    Write-Host "  menu:  $(if (Test-Path $menuMaster) { 'exists' } else { 'not yet' })"
    Write-Host "  index: $(if (Test-Path $indexMaster) { 'exists' } else { 'not yet' })"
    Write-Host "  log:   $(if (Test-Path $logCsv) { 'exists' } else { 'not yet' })"
}

# ============================================================================
# SCAN - ONE MOVE PER SCAN
# ============================================================================

function Invoke-Scan {
    Write-Host "=== SCANNING ===" -ForegroundColor Cyan
    
    $tools = Get-Tools
    $moved = 0
    
    foreach ($t in $tools) {
        $name = $t.Name.ToLower()
        $toolPath = $t.FullName
        
        $readme = Join-Path $toolPath "$name-instructions/$name-model-readme.md"
        $info = Join-Path $toolPath "$name-information.json"
        $infoPending = "$info$Pending"
        
        # STAGE 1: readme exists, no information.json → extract to pending
        if ((Test-Path $readme) -and -not (Test-Path $info) -and -not (Test-Path $infoPending)) {
            $manifest = Extract-ManifestFromReadme -Path $readme -Tool $name
            if ($manifest) {
                $manifest | ConvertTo-Json -Depth 10 | Set-Content $infoPending -Encoding UTF8
                Write-Host "  $name : readme → information.json.pending" -ForegroundColor Yellow
                $moved++
            } else {
                Write-Host "  $name : readme has no valid manifest" -ForegroundColor Red
            }
        }
    }
    
    # STAGE 2: Build menu from all approved information.json files
    $menuMaster = Join-Path $LogDir "toolbox-menu.json"
    $menuPending = "$menuMaster$Pending"
    
    $menuTools = @()
    foreach ($t in $tools) {
        $name = $t.Name.ToLower()
        $info = Join-Path $t.FullName "$name-information.json"
        
        if (Test-Path $info) {
            try {
                $data = Get-Content $info -Raw | ConvertFrom-Json
                $menuTools += [ordered]@{
                    toolname = $name
                    paths = [ordered]@{
                        root = $name
                        instructions = "$name/$name-instructions"
                        examples = "$name/$name-examples"
                    }
                    information = $data
                }
            } catch {
                Write-Host "  $name : bad JSON in information.json" -ForegroundColor Red
            }
        }
    }
    
    # Only create menu.pending if we have tools and menu would be different
    if ($menuTools.Count -gt 0) {
        $newMenu = [ordered]@{
            _generated_at = (Get-Date -Format "o")
            tools = $menuTools
        }
        $newMenuJson = $newMenu | ConvertTo-Json -Depth 20
        
        $currentMenuJson = ""
        if (Test-Path $menuMaster) {
            $currentMenuJson = Get-Content $menuMaster -Raw
        }
        
        # Compare without timestamps
        $newCompare = ($newMenu.tools | ConvertTo-Json -Depth 20 -Compress)
        $oldCompare = ""
        if ($currentMenuJson) {
            try {
                $oldMenu = $currentMenuJson | ConvertFrom-Json
                $oldCompare = ($oldMenu.tools | ConvertTo-Json -Depth 20 -Compress)
            } catch {}
        }
        
        if ($newCompare -ne $oldCompare -and -not (Test-Path $menuPending)) {
            $newMenuJson | Set-Content $menuPending -Encoding UTF8
            Write-Host "  menu : information.json(s) → toolbox-menu.json.pending" -ForegroundColor Yellow
            $moved++
            
            # Also copy to .cauldron for ordering
            $menuCopy = Join-Path $Cauldron "toolbox-menu.json"
            $newMenuJson | Set-Content $menuCopy -Encoding UTF8
        }
    }
    
    # STAGE 3: Menu → Index + DIFF
    $indexMaster = Join-Path $LogDir "toolbox-index.json"
    $indexPending = "$indexMaster$Pending"
    
    if ((Test-Path $menuMaster) -and -not (Test-Path $indexPending)) {
        $menuData = Get-Content $menuMaster -Raw | ConvertFrom-Json
        
        $newIndex = [ordered]@{
            _generated_at = (Get-Date -Format "o")
            _tool_count = $menuData.tools.Count
            tools = $menuData.tools
        }
        $newIndexJson = $newIndex | ConvertTo-Json -Depth 20
        
        # DIFF
        $diffAdded = @()
        $diffRemoved = @()
        $diffModified = @()
        
        if (Test-Path $indexMaster) {
            $oldIndex = Get-Content $indexMaster -Raw | ConvertFrom-Json
            $oldNames = @($oldIndex.tools | ForEach-Object { $_.toolname })
            $newNames = @($menuData.tools | ForEach-Object { $_.toolname })
            
            $diffAdded = $newNames | Where-Object { $_ -notin $oldNames }
            $diffRemoved = $oldNames | Where-Object { $_ -notin $newNames }
            
            foreach ($tool in $menuData.tools) {
                $old = $oldIndex.tools | Where-Object { $_.toolname -eq $tool.toolname }
                if ($old) {
                    $oldJson = $old.information | ConvertTo-Json -Depth 10 -Compress
                    $newJson = $tool.information | ConvertTo-Json -Depth 10 -Compress
                    if ($oldJson -ne $newJson) {
                        $diffModified += $tool.toolname
                    }
                }
            }
        } else {
            $diffAdded = @($menuData.tools | ForEach-Object { $_.toolname })
        }
        
        $hasChanges = ($diffAdded.Count -gt 0) -or ($diffRemoved.Count -gt 0) -or ($diffModified.Count -gt 0)
        
        if ($hasChanges) {
            $newIndexJson | Set-Content $indexPending -Encoding UTF8
            Write-Host "  index : menu → toolbox-index.json.pending" -ForegroundColor Yellow
            if ($diffAdded.Count -gt 0) { Write-Host "    added: $($diffAdded -join ', ')" -ForegroundColor Green }
            if ($diffRemoved.Count -gt 0) { Write-Host "    removed: $($diffRemoved -join ', ')" -ForegroundColor Red }
            if ($diffModified.Count -gt 0) { Write-Host "    modified: $($diffModified -join ', ')" -ForegroundColor Yellow }
            $moved++
            
            # Log to CSV
            $logCsv = Join-Path $LogDir "log.csv"
            $row = [PSCustomObject]@{
                timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
                action = "scan"
                added = ($diffAdded -join ",")
                removed = ($diffRemoved -join ",")
                modified = ($diffModified -join ",")
            }
            if (-not (Test-Path $logCsv)) {
                $row | Export-Csv -Path $logCsv -NoTypeInformation -Encoding UTF8
            } else {
                $row | Export-Csv -Path $logCsv -NoTypeInformation -Encoding UTF8 -Append
            }
        }
    }
    
    Write-Host ""
    if ($moved -eq 0) {
        Write-Host "Nothing to move. Run 'approve' if there are pending files." -ForegroundColor Green
    } else {
        Write-Host "Moved $moved item(s). Run 'approve' to apply." -ForegroundColor Yellow
    }
}

# ============================================================================
# APPROVE
# ============================================================================

function Invoke-Approve {
    $pending = Get-PendingFiles
    
    if ($pending.Count -eq 0) {
        Write-Host "No pending files." -ForegroundColor Green
        return
    }
    
    Write-Host "=== APPROVE ===" -ForegroundColor Cyan
    
    foreach ($p in $pending) {
        $rel = $p.FullName.Replace($Root, "").TrimStart("\", "/")
        $target = $p.FullName.Substring(0, $p.FullName.Length - $Pending.Length)
        
        $doApprove = $false
        
        if ($Yes) {
            $doApprove = $true
        } elseif ($PerFile) {
            $answer = Read-Host "Approve $rel ? (y/n)"
            if ($answer.ToLower() -eq "y") { $doApprove = $true }
        } else {
            Write-Host "  $rel"
        }
        
        if ($doApprove) {
            if (Test-Path $target) {
                Copy-Item $target "$target$Backup" -Force
            }
            Move-Item $p.FullName $target -Force
            Write-Host "  Approved: $rel" -ForegroundColor Green
        }
    }
    
    if (-not $Yes -and -not $PerFile) {
        Write-Host ""
        Write-Host "Use -Yes to approve all, or -PerFile to approve each."
    }
}

# ============================================================================
# CREATE-TOOL
# ============================================================================

function Invoke-CreateTool {
    if ([string]::IsNullOrWhiteSpace($Toolname)) {
        $Toolname = Read-Host "Tool name (lowercase)"
    }
    
    $name = $Toolname.ToLower().Trim() -replace "\s+", "-"
    $toolDir = Join-Path $Root $name
    
    if (Test-Path $toolDir) {
        Write-Error "Already exists: $name"
        return
    }
    
    Write-Host "Creating: $name" -ForegroundColor Cyan
    
    $instrDir = Join-Path $toolDir "$name-instructions"
    $examplesDir = Join-Path $toolDir "$name-examples"
    
    New-Item -ItemType Directory -Path $instrDir -Force | Out-Null
    New-Item -ItemType Directory -Path $examplesDir -Force | Out-Null
    
    # License
    @"
$name
License: MIT
Created: $(Get-Date -Format 'yyyy-MM-dd')
"@ | Set-Content (Join-Path $toolDir "$name-license.txt") -Encoding UTF8
    
    # README template
    @"
# $name

ABSOLUTE TRUTH. Models do not edit this file.

## Definitions
- (your terms here)

## Requirements
- (what goes in .cauldron)

## Outputs
- (what appears in .outbox)

---

<<<begin-$name-manifest-file_1_of_1>>>
{
  "NAME": "$name",
  "Description": "WRITE 100+ WORDS describing what this tool does",
  "Requirements": [],
  "Stacks_with": [],
  "Historical_Runs": [],
  "Common_Uses": [],
  "Needs_Improvements": false,
  "Model_Notes": [],
  "CLASS": "uncategorized",
  "Paired": [],
  "Requested_Edits": []
}
<<<end-$name-manifest-file_1_of_1>>>
"@ | Set-Content (Join-Path $instrDir "$name-model-readme.md") -Encoding UTF8
    
    Write-Host "Created: $name" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  1. Edit $name/$name-instructions/$name-model-readme.md"
    Write-Host "  2. .\run.ps1 scan"
    Write-Host "  3. .\run.ps1 approve -PerFile"
}

# ============================================================================
# RUN (placeholder for now)
# ============================================================================

function Invoke-Run {
    Write-Host "Run not implemented yet. Need order form first." -ForegroundColor Yellow
}

# ============================================================================
# MAIN
# ============================================================================

switch ($Command) {
    "status"      { Invoke-Status }
    "scan"        { Invoke-Scan }
    "approve"     { Invoke-Approve }
    "create-tool" { Invoke-CreateTool }
    "run"         { Invoke-Run }
}
