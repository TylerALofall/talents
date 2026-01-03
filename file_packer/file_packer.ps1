untitled:Untitled-2 {"typeId":""}
Planning / decisions (what I’m changing and why)

Unpack should prompt and let you extract only some files
On unpack, the script will first read the packed file and build an ordered list of entries (in the same order they were packed).
It will print a numbered list of file paths (1..N).
It will prompt you to choose which ones to extract using a simple selection syntax:
all
1,3,7
2-5
1,2-4,9
For automation (called from another script), prompting can break runs, so I’m adding options that still keep only two commands (pack/unpack) but let you bypass prompts:
-All (extract everything, no selection prompt)
-Select "1,3-5" (non-interactive selection)
-NonInteractive (error if it would prompt)
2. Consistent naming: prepend the tool name to extracted file names

On unpack, every extracted file’s leaf name is renamed to: ToolName=OriginalFileName Example: config.ps1 -> VEND=config.ps1
The directory structure under the packed relative path is preserved; only the final file name is changed.
If a file already starts with ToolName= it won’t double-prefix.
3. Each packed stack gets its own output folder automatically

On unpack, by default it will create a subfolder under TargetPath named ToolName, and extract into that: TargetPath\ToolName...
If you don’t want that (because you already pass a tool folder), you can use -NoToolDir.
4. Where ToolName comes from

On pack, you can pass -ToolName "VEND". The packed file stores a readable header line: TOOLNAME: VEND
On unpack, if ToolName is not passed:
It uses TOOLNAME from the packed header if present
Otherwise it prompts you (unless -NonInteractive)
5. Overwrite behavior

pack:
refuses to overwrite the packed output file unless -Force is provided
unpack:
if a destination file already exists:
interactive mode: prompts (Y/N/All/SkipAll)
non-interactive mode: refuses unless -Force is provided
6. Keep it human-readable (no base64) and avoid forcing UTF-8

Content is stored as plain text between markers.
Reads/writes use PowerShell “Default” encoding (not UTF-8) as you requested.
This is text-mode only; it is not for binary files.
7. Markers + numbering requirement

The packed file starts with a single-line marker containing “fuckk”.
The packed file ends with a single-line marker containing “fuckk”.
Each file entry includes “x of y” in both FILE_START and FILE_END lines.
param(
[Parameter(Mandatory=$true, Position=0)]
[ValidateSet('pack','unpack')]
[string]$Command,

[Parameter(Mandatory=$true, Position=1)]
[string]$SourcePath,

[Parameter(Mandatory=$true, Position=2)]
[string]$TargetPath,

[Parameter(Mandatory=$false)]
[string]$ToolName,

[Parameter(Mandatory=$false)]
[switch]$Force,

[Parameter(Mandatory=$false)]
[switch]$All,

[Parameter(Mandatory=$false)]
[string]$Select,

[Parameter(Mandatory=$false)]
[switch]$NoToolDir,

[Parameter(Mandatory=$false)]
[switch]$NonInteractive
)

$GLOBAL_BEGIN_MARKER = "<<<fuckk BEGIN PACKED CONTENT>>>"
$GLOBAL_END_MARKER   = "<<<fuckk END PACKED CONTENT>>>"

function Ensure-Directory {
param([Parameter(Mandatory=$true)][string]$Path)
if (Test-Path -LiteralPath $Path) { return }
New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Get-RelativePath {
param(
[Parameter(Mandatory=$true)][string]$BasePath,
[Parameter(Mandatory=$true)][string]$FullPath
)

$base = [System.IO.Path]::GetFullPath($BasePath)
if (-not $base.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $base += [System.IO.Path]::DirectorySeparatorChar
}

$full = [System.IO.Path]::GetFullPath($FullPath)

$baseUri = [System.Uri]::new($base)
$fullUri = [System.Uri]::new($full)

$rel = $baseUri.MakeRelativeUri($fullUri).ToString()
[System.Uri]::UnescapeDataString($rel)
}

function Parse-Selection {
param(
[Parameter(Mandatory=$true)][string]$Input,
[Parameter(Mandatory=$true)][int]$Max
)

$s = $Input.Trim()
if ($s -eq "") { return @() }
if ($s -match '^(all|\*)$') { return 1..$Max }

$set = New-Object 'System.Collections.Generic.HashSet[int]'
$parts = $s -split ','

foreach ($pRaw in $parts) {
    $p = $pRaw.Trim()
    if ($p -eq "") { continue }

    if ($p -match '^\d+$') {
        [void]$set.Add([int]$p)
        continue
    }

    if ($p -match '^(?<a>\d+)\s*-\s*(?<b>\d+)$') {
        $a = [int]$Matches['a']
        $b = [int]$Matches['b']
        if ($a -le $b) {
            for ($i=$a; $i -le $b; $i++) { [void]$set.Add($i) }
        } else {
            for ($i=$a; $i -ge $b; $i--) { [void]$set.Add($i) }
        }
        continue
    }

    throw "Invalid selection token: '$p'"
}

$arr = $set.ToArray() | Sort-Object
$arr = @($arr | Where-Object { $_ -ge 1 -and $_ -le $Max })
return $arr
}

function Get-ToolNameFromHeader {
param([Parameter(Mandatory=$true)][string]$PackedText)

$m = [regex]::Match($PackedText, '(?m)^\s*TOOLNAME:\s*(?<t>.+?)\s*$')
if ($m.Success) { return $m.Groups['t'].Value.Trim() }
return $null
}

function Pack-Path {
param(
[Parameter(Mandatory=$true)][string]$Source,
[Parameter(Mandatory=$true)][string]$OutputFile,
[Parameter(Mandatory=$false)][string]$Tool
)

if (-not (Test-Path -LiteralPath $Source)) {
    throw "SourcePath does not exist: $Source"
}

$outputFull = [System.IO.Path]::GetFullPath($OutputFile)
if ((Test-Path -LiteralPath $outputFull) -and (-not $Force)) {
    throw "Refusing to overwrite existing packed file: $outputFull (use -Force to overwrite)"
}

$outputParent = Split-Path -Parent $outputFull
if ($outputParent) { Ensure-Directory -Path $outputParent }

$sourceItem = Get-Item -LiteralPath $Source
$baseDir = $null
$files = @()

if ($sourceItem.PSIsContainer) {
    $baseDir = [System.IO.Path]::GetFullPath($sourceItem.FullName)
    $files = @(Get-ChildItem -LiteralPath $baseDir -File -Recurse | Sort-Object FullName)
} else {
    $baseDir = [System.IO.Path]::GetFullPath((Split-Path -Parent $sourceItem.FullName))
    $files = @($sourceItem)
}

$files = @($files | Where-Object { [System.IO.Path]::GetFullPath($_.FullName) -ne $outputFull })
$total = $files.Count

$writer = New-Object System.IO.StreamWriter($outputFull, $false, [System.Text.Encoding]::Default)
try {
    $writer.WriteLine($GLOBAL_BEGIN_MARKER)
    if ($Tool -and $Tool.Trim() -ne "") {
        $writer.WriteLine("TOOLNAME: $($Tool.Trim())")
    }
    $writer.WriteLine()

    for ($i = 0; $i -lt $total; $i++) {
        $file = $files[$i]
        $seq = "$($i + 1) of $total"
        $rel = Get-RelativePath -BasePath $baseDir -FullPath $file.FullName

        $writer.WriteLine("<<<FILE_START $seq>>> $rel")

        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding Default
        $writer.Write($content)

        $writer.WriteLine()
        $writer.WriteLine("<<<FILE_END $seq>>> $rel")
        $writer.WriteLine()
    }

    $writer.WriteLine($GLOBAL_END_MARKER)
}
finally {
    $writer.Dispose()
}

Write-Host "Packed $total file(s) to: $outputFull"
}

function Unpack-PackedFile {
param(
[Parameter(Mandatory=$true)][string]$InputFile,
[Parameter(Mandatory=$true)][string]$OutputDir
)

if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) {
    throw "Input packed file does not exist: $InputFile"
}

$inputFull = [System.IO.Path]::GetFullPath($InputFile)
$outRoot = [System.IO.Path]::GetFullPath($OutputDir)
Ensure-Directory -Path $outRoot

$text = Get-Content -LiteralPath $inputFull -Raw -Encoding Default

$firstLine = ($text -split "\r?\n", 2)[0]
if ($firstLine -ne $GLOBAL_BEGIN_MARKER) {
    throw "Missing/invalid top marker. Expected first line: $GLOBAL_BEGIN_MARKER"
}

$textNoTrailingNewlines = $text.TrimEnd("`r","`n")
$lastLine = ($textNoTrailingNewlines -split "\r?\n")[-1]
if ($lastLine -ne $GLOBAL_END_MARKER) {
    throw "Missing/invalid bottom marker. Expected last line: $GLOBAL_END_MARKER"
}

$toolFromHeader = Get-ToolNameFromHeader -PackedText $text
if (-not $ToolName -or $ToolName.Trim() -eq "") {
    if ($toolFromHeader) {
        $ToolName = $toolFromHeader
    } else {
        if ($NonInteractive) {
            throw "ToolName not provided and not found in packed header. Provide -ToolName or pack with TOOLNAME header."
        }
        $ToolName = (Read-Host "Enter ToolName to prefix extracted files (example: VEND)").Trim()
        if ($ToolName -eq "") { throw "ToolName cannot be empty." }
    }
} else {
    $ToolName = $ToolName.Trim()
}

$finalOut = $outRoot
if (-not $NoToolDir) {
    $finalOut = Join-Path -Path $outRoot -ChildPath $ToolName
}
Ensure-Directory -Path $finalOut

$pattern = '^<<<FILE_START\s+(?<seq>\d+\s+of\s+\d+)>>>\s+(?<path>[^\r\n]+)\r?\n(?<content>.*?)\r?\n^<<<FILE_END\s+(?<seq2>\d+\s+of\s+\d+)>>>\s+(?<path2>[^\r\n]+)\s*$'
$options = [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
$matches = [System.Text.RegularExpressions.Regex]::Matches($text, $pattern, $options)

if ($matches.Count -eq 0) {
    throw "No file entries found in packed file."
}

$entries = @()
for ($i=0; $i -lt $matches.Count; $i++) {
    $m = $matches[$i]
    $seq1 = $m.Groups['seq'].Value
    $seq2 = $m.Groups['seq2'].Value
    $path1 = $m.Groups['path'].Value
    $path2 = $m.Groups['path2'].Value

    if ($seq1 -ne $seq2 -or $path1 -ne $path2) {
        throw "Mismatched markers for an entry. Start: '$seq1 $path1' End: '$seq2 $path2'"
    }

    $entries += [pscustomobject]@{
        Index   = $i + 1
        Seq     = $seq1
        RelPath = $path1
        Content = $m.Groups['content'].Value
    }
}

$chosen = @()

if ($All) {
    $chosen = 1..$entries.Count
} elseif ($Select -and $Select.Trim() -ne "") {
    $chosen = Parse-Selection -Input $Select -Max $entries.Count
    if ($chosen.Count -eq 0) { throw "Selection resulted in 0 files." }
} else {
    if ($NonInteractive) {
        throw "No selection provided. Use -All or -Select when -NonInteractive is set."
    }

    Write-Host ""
    Write-Host "Packed entries (in order):"
    foreach ($e in $entries) {
        Write-Host ("{0,4}. {1}" -f $e.Index, $e.RelPath)
    }
    Write-Host ""
    $inp = Read-Host "Which files to extract? (all | 1,3-5 | 2-4,9)"
    $chosen = Parse-Selection -Input $inp -Max $entries.Count
    if ($chosen.Count -eq 0) {
        Write-Host "No files selected. Nothing extracted."
        return
    }
}

$overwriteAll = $false
$skipAll = $false
$extracted = 0

foreach ($idx in $chosen) {
    $e = $entries[$idx - 1]

    $rel = $e.RelPath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $dirPart = Split-Path -Parent $rel
    $leaf = Split-Path -Leaf $rel

    if (-not $leaf.StartsWith("$ToolName=")) {
        $leaf = "$ToolName=$leaf"
    }

    $destDir = if ($dirPart) { Join-Path -Path $finalOut -ChildPath $dirPart } else { $finalOut }
    Ensure-Directory -Path $destDir

    $destFull = Join-Path -Path $destDir -ChildPath $leaf

    if (Test-Path -LiteralPath $destFull) {
        if ($Force) {
            # overwrite
        } elseif ($skipAll) {
            continue
        } elseif ($overwriteAll) {
            # overwrite
        } elseif ($NonInteractive) {
            throw "Refusing to overwrite existing file: $destFull (use -Force to overwrite)"
        } else {
            Write-Host ""
            Write-Host "File exists: $destFull"
            $ans = Read-Host "Overwrite? (Y)es/(N)o/(A)ll overwrite/(S)kip all"
            switch ($ans.Trim().ToLower()) {
                'y' { }
                'n' { continue }
                'a' { $overwriteAll = $true }
                's' { $skipAll = $true; continue }
                default { continue }
            }
        }
    }

    Set-Content -LiteralPath $destFull -Value $e.Content -Encoding Default -NoNewline
    $extracted++
}

Write-Host "Unpacked $extracted file(s) to: $finalOut"
}

try {
switch ($Command) {
'pack' {
Pack-Path -Source $SourcePath -OutputFile $TargetPath -Tool $ToolName
}
'unpack' {
Unpack-PackedFile -InputFile $SourcePath -OutputDir $TargetPath
}
}
}
catch {
Write-Error $_
exit 1