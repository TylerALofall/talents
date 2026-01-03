<#
.SYNOPSIS
    anthropic_tool_crafter - Calls Claude Opus/Sonnet to craft tools for the Talent Toolbox
    
.DESCRIPTION
    THIS SCRIPT IS LOCKED. MODELS DO NOT EDIT.
    Configure via .cauldron/anthropic_tool_crafter.request.json
    
.PARAMETER Root
    Path to the toolbox root directory. Defaults to current directory.
    
.EXAMPLE
    .\anthropic_tool_crafter_01_call.ps1 -Root "C:\Users\Tyler\toolbox"
    
.NOTES
    Author: Tyler Lofall & Claude
    API Key: Embedded at line 25
    Models: claude-opus-4-5-20250514, claude-sonnet-4-5-20250929
#>

param(
    [string]$Root = "."
)

$ErrorActionPreference = "Stop"

# =============================================================================
# API KEY - STORED DIRECTLY (Line 25)
# =============================================================================

$API_KEY = "YOUR_API_KEY_HERE"

# =============================================================================
# MODEL OPTIONS
# =============================================================================

$MODELS = @{
    "opus"   = "claude-opus-4-5-20250514"
    "sonnet" = "claude-sonnet-4-5-20250929"
}

# =============================================================================
# DEFAULTS
# =============================================================================

$DEFAULT_MAX_TOKENS = 32000
$DEFAULT_THINKING_ENABLED = $true
$DEFAULT_THINKING_BUDGET = 16000
$DEFAULT_TEMPERATURE = 1

# =============================================================================
# SYSTEM PROMPT TEMPLATE
# =============================================================================

$SYSTEM_PROMPT_TEMPLATE = @"
You are a Professional Tool Crafter creating tools for Tyler Lofall's Talent Toolbox. The purpose is to create a self-scaffolding tool with strict requirements so that it fits perfectly inside the platform that you helped build.

You will be provided a description of the tool and its requirements in a schema. Your job is to make that tool absolutely beautiful and powerful, editable through Config File only.

No Model or person should have to edit or correct this tool once it's built. It's meant to be built for survival of time and fitness in many situations.

With that in mind, craft the tool out of one or several scripts.

CONSTRAINTS:
- NO SUBPROCESSES or any mini AI's mutating scripts
- NO self-calling codes
- Stay away from Python if possible
- Main run tool will be ran in PowerShell
- If you do use Python or JS, make it as vanilla as possible

CONFIG FILE MUST HAVE:
A. Definitions - all terms used in the tool
B. Schema - from the user prompt
C. Setup instructions - everything needed to run this
D. API Key location if necessary
E. Complete instructions - nothing left unexplained

SCRIPT FORMAT:
After the config section, there will be a hard line for the scripts.
Each script marked with:
<<<begin-TOOLNAME-script-file_X_of_Y>>>
(script content)
<<<end-TOOLNAME-script-file_X_of_Y>>>

These markers are intentionally complex to stop runaway loops since the system has automated logging and menu updates.

USER CONTEXT:
Tyler Lofall is a legally blind novice coder and Pro Se Litigant setting up his coding tools.

TOOL REQUEST:
{{PROMPT}}

TOOL BUILDING GUIDE (how the toolbox works):
{{TOOL_BUILDING_GUIDE}}

USER GUIDE SPECS (model behavior rules):
{{USER_GUIDE}}

FINAL INSTRUCTIONS:
- SLOW DOWN, breathe deep... you're part of the A-Team
- You are here because you are the best
- Plan every perspective and angle to be multifaceted and flexible
- Think things through
- Make a flow chart and mini-manual with Table of Contents
- You can revise the schema but don't change the tool's intended use
- Test the file before you send it out
- OS is Windows 11
- Tools should reach both models and users understanding
- A model will be doing much of the tool calls (probably even you)
- Setup is meant to build upon other tools so they can stack and fire where they are

Thanks Opus, you are a Stud Muffin!
"@

$USER_MESSAGE_TEMPLATE = @"
Tyler Lofall, a legally blind Novice Coder, and Pro Se Litigant is setting up his Coding tools and has asked for the following special tool to be created:

{{PROMPT}}

Below is the user Manual that explains the requirements of this tool:

{{TOOL_BUILDING_GUIDE}}

MAKE SURE THAT YOU ARE COMPLIANT WITH THE FOLLOWING ADDITIONAL USER GUIDE SPECS:

{{USER_GUIDE}}

** Note: SLOW DOWN, Breathe Deep... You're apart of the A-Team.... you are here because you are the best.... Plan every perspective and angle to be multifacited, and flexible think things through, make sure you do a flow chart and Mini Manual with a Table of Contents. you can revise the Schema but dont change the tools indented use. Give the file a test before you send it out, The OS is Windows 11, and it would be preferable if All of the Tools reached both Models and Users understandings, as this is a setup where a model will be doing much of the tool calls, (probably even you) ... the set set up is meant to be something that can build upon othertools so they can stack and fired where they are.... I am making this before this prompt hand so this prompt is meant to be universal ... so focus on the Prompt for SPecifics and the Guides for form and compliance to the enviroment being shipped.

Thanks Opus, you are a Stud Muffin!
"@

# =============================================================================
# PATHS
# =============================================================================

$RootPath = Resolve-Path $Root
$Cauldron = Join-Path $RootPath ".cauldron"
$Outbox = Join-Path $RootPath ".outbox"
$Receipts = Join-Path $Outbox "_receipts"

$RequestFile = Join-Path $Cauldron "anthropic_tool_crafter.request.json"
$OutputFile = Join-Path $Outbox "anthropic_tool_crafter.output.json"
$ToolFile = Join-Path $Outbox "anthropic_tool_crafter.tool.md"
$ReceiptFile = Join-Path $Receipts "anthropic_tool_crafter.receipt.json"

# =============================================================================
# FUNCTIONS
# =============================================================================

function Get-Timestamp {
    return (Get-Date).ToUniversalTime().ToString("o")
}

function Write-JsonFile {
    param([string]$Path, [object]$Data)
    $json = $Data | ConvertTo-Json -Depth 20 -Compress:$false
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.Encoding]::UTF8)
}

function Substitute-Placeholders {
    param(
        [string]$Template,
        [hashtable]$Placeholders
    )
    
    $result = $Template
    foreach ($key in $Placeholders.Keys) {
        $pattern = "{{$key}}"
        $value = if ($null -eq $Placeholders[$key]) { "" } else { $Placeholders[$key].ToString() }
        $result = $result.Replace($pattern, $value)
    }
    return $result
}

function Build-RequestPayload {
    param(
        [string]$Model,
        [string]$SystemPrompt,
        [string]$UserMessage,
        [int]$MaxTokens,
        [bool]$ThinkingEnabled,
        [int]$ThinkingBudget,
        [bool]$WebSearch
    )
    
    $payload = @{
        model = $Model
        max_tokens = $MaxTokens
        temperature = $DEFAULT_TEMPERATURE
        system = $SystemPrompt
        messages = @(
            @{
                role = "user"
                content = @(
                    @{
                        type = "text"
                        text = $UserMessage
                    }
                )
            }
        )
    }
    
    if ($ThinkingEnabled) {
        $payload["thinking"] = @{
            type = "enabled"
            budget_tokens = $ThinkingBudget
        }
        # Remove temperature when thinking is enabled (Anthropic requirement)
        $payload.Remove("temperature")
    }
    
    if ($WebSearch) {
        $payload["tools"] = @(
            @{
                type = "web_search_20250305"
                name = "web_search"
            }
        )
    }
    
    return $payload
}

function Invoke-AnthropicAPI {
    param(
        [hashtable]$Payload
    )
    
    $endpoint = "https://api.anthropic.com/v1/messages"
    
    $headers = @{
        "x-api-key" = $API_KEY
        "anthropic-version" = "2023-06-01"
        "content-type" = "application/json"
    }
    
    $body = $Payload | ConvertTo-Json -Depth 10 -Compress
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body -TimeoutSec 600
        return @{
            success = $true
            data = $response
        }
    }
    catch {
        $statusCode = $null
        $responseText = $null
        
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseText = $reader.ReadToEnd()
            $reader.Close()
        }
        
        return @{
            success = $false
            error = $_.Exception.Message
            status_code = $statusCode
            response_text = $responseText
        }
    }
}

function Parse-Response {
    param([object]$Response)
    
    $result = @{
        response_id = $Response.id
        model = $Response.model
        text = ""
        thinking = ""
        usage = $Response.usage
        stop_reason = $Response.stop_reason
    }
    
    foreach ($block in $Response.content) {
        switch ($block.type) {
            "thinking" {
                $result.thinking += $block.thinking
            }
            "text" {
                $result.text += $block.text
            }
        }
    }
    
    return $result
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           ANTHROPIC TOOL CRAFTER - Tyler's A-Team                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Root: $RootPath" -ForegroundColor Gray
Write-Host ""

# Ensure directories exist
@($Outbox, $Receipts) | ForEach-Object {
    if (-not (Test-Path $_)) { 
        New-Item -ItemType Directory -Path $_ -Force | Out-Null 
    }
}

# Check request file exists
if (-not (Test-Path $RequestFile)) {
    $errorOutput = @{
        success = $false
        error = "Request file not found: $RequestFile"
        hint = "Create the file with your tool request. See examples in anthropic_tool_crafter-examples/"
        timestamp_utc = Get-Timestamp
    }
    Write-JsonFile -Path $OutputFile -Data $errorOutput
    Write-Host "ERROR: Request file not found" -ForegroundColor Red
    Write-Host "       Expected: $RequestFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create the request file with your tool description." -ForegroundColor Yellow
    Write-Host "See examples in: anthropic_tool_crafter\anthropic_tool_crafter-examples\" -ForegroundColor Yellow
    exit 1
}

# Load request config
Write-Host "Loading request config..." -ForegroundColor Gray
try {
    $requestContent = Get-Content $RequestFile -Raw -Encoding UTF8
    $request = $requestContent | ConvertFrom-Json
}
catch {
    $errorOutput = @{
        success = $false
        error = "Invalid JSON in request file: $($_.Exception.Message)"
        timestamp_utc = Get-Timestamp
    }
    Write-JsonFile -Path $OutputFile -Data $errorOutput
    Write-Host "ERROR: Invalid JSON in request file" -ForegroundColor Red
    Write-Host "       $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get model selection
$modelKey = if ($request.use_model) { $request.use_model.ToLower() } else { "opus" }
$model = if ($MODELS.ContainsKey($modelKey)) { $MODELS[$modelKey] } else { $MODELS["opus"] }

# Get settings with defaults
$maxTokens = if ($request.override_max_tokens) { [int]$request.override_max_tokens } else { $DEFAULT_MAX_TOKENS }

$thinkingEnabled = $DEFAULT_THINKING_ENABLED
$thinkingBudget = $DEFAULT_THINKING_BUDGET

if ($request.override_thinking) {
    if ($null -ne $request.override_thinking.enabled) {
        $thinkingEnabled = [bool]$request.override_thinking.enabled
    }
    if ($request.override_thinking.budget_tokens) {
        $thinkingBudget = [int]$request.override_thinking.budget_tokens
    }
}

$webSearch = $false
if ($request.override_search -and $request.override_search.web_search) {
    $webSearch = [bool]$request.override_search.web_search
}

# Build placeholders hashtable
$placeholders = @{}
if ($request.placeholders) {
    $request.placeholders.PSObject.Properties | ForEach-Object {
        $placeholders[$_.Name] = $_.Value
    }
}

# Check required placeholder
if (-not $placeholders.ContainsKey("PROMPT") -or [string]::IsNullOrWhiteSpace($placeholders["PROMPT"])) {
    $errorOutput = @{
        success = $false
        error = "Missing required placeholder: PROMPT"
        hint = "Add 'placeholders.PROMPT' with your tool description"
        timestamp_utc = Get-Timestamp
    }
    Write-JsonFile -Path $OutputFile -Data $errorOutput
    Write-Host "ERROR: Missing required placeholder: PROMPT" -ForegroundColor Red
    Write-Host "       Your request must include placeholders.PROMPT with the tool description." -ForegroundColor Red
    exit 1
}

# Substitute placeholders into prompts
Write-Host "Building prompts..." -ForegroundColor Gray
$finalSystemPrompt = Substitute-Placeholders -Template $SYSTEM_PROMPT_TEMPLATE -Placeholders $placeholders
$finalUserMessage = Substitute-Placeholders -Template $USER_MESSAGE_TEMPLATE -Placeholders $placeholders

# Build request payload
$payload = Build-RequestPayload `
    -Model $model `
    -SystemPrompt $finalSystemPrompt `
    -UserMessage $finalUserMessage `
    -MaxTokens $maxTokens `
    -ThinkingEnabled $thinkingEnabled `
    -ThinkingBudget $thinkingBudget `
    -WebSearch $webSearch

# Display settings
Write-Host ""
Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "│ CALLING ANTHROPIC API                                           │" -ForegroundColor DarkGray
Write-Host "├─────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
Write-Host "│ Model:         $($model.PadRight(46))│" -ForegroundColor White
Write-Host "│ Thinking:      $(($thinkingEnabled.ToString()).PadRight(46))│" -ForegroundColor White
Write-Host "│ Think Budget:  $(($thinkingBudget.ToString() + ' tokens').PadRight(46))│" -ForegroundColor White
Write-Host "│ Max Tokens:    $(($maxTokens.ToString()).PadRight(46))│" -ForegroundColor White
Write-Host "│ Web Search:    $(($webSearch.ToString()).PadRight(46))│" -ForegroundColor White
Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Sending request... (this may take 30-300 seconds)" -ForegroundColor Yellow
Write-Host ""

# Make API call
$startTime = Get-Date
$apiResult = Invoke-AnthropicAPI -Payload $payload
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Handle error
if (-not $apiResult.success) {
    $errorOutput = @{
        success = $false
        error = $apiResult.error
        status_code = $apiResult.status_code
        response_text = $apiResult.response_text
        duration_seconds = [math]::Round($duration, 2)
        timestamp_utc = Get-Timestamp
    }
    Write-JsonFile -Path $OutputFile -Data $errorOutput
    
    Write-Host "ERROR: API call failed" -ForegroundColor Red
    Write-Host "       $($apiResult.error)" -ForegroundColor Red
    if ($apiResult.status_code) {
        Write-Host "       Status code: $($apiResult.status_code)" -ForegroundColor Red
    }
    exit 1
}

# Parse response
Write-Host "Parsing response..." -ForegroundColor Gray
$parsed = Parse-Response -Response $apiResult.data

# Build output
$output = @{
    success = $true
    model = $model
    response_id = $parsed.response_id
    stop_reason = $parsed.stop_reason
    thinking = $parsed.thinking
    tool_content = $parsed.text
    usage = $parsed.usage
    duration_seconds = [math]::Round($duration, 2)
    timestamp_utc = Get-Timestamp
}

# Write outputs
Write-Host "Writing output files..." -ForegroundColor Gray

Write-JsonFile -Path $OutputFile -Data $output

# Write just the tool content to separate file (ready to use)
[System.IO.File]::WriteAllText($ToolFile, $parsed.text, [System.Text.Encoding]::UTF8)

# Create receipt
$receipt = @{
    timestamp_utc = Get-Timestamp
    artifact = "anthropic_tool_crafter.tool.md"
    model = $model
    thinking_enabled = $thinkingEnabled
    thinking_budget = $thinkingBudget
    max_tokens = $maxTokens
    duration_seconds = [math]::Round($duration, 2)
    usage = $parsed.usage
    prompt_preview = $placeholders["PROMPT"].Substring(0, [Math]::Min(200, $placeholders["PROMPT"].Length)) + "..."
}
Write-JsonFile -Path $ReceiptFile -Data $receipt

# Calculate token totals
$inputTokens = if ($parsed.usage.input_tokens) { $parsed.usage.input_tokens } else { 0 }
$outputTokens = if ($parsed.usage.output_tokens) { $parsed.usage.output_tokens } else { 0 }
$totalTokens = $inputTokens + $outputTokens

# Success output
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                         SUCCESS!                                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Response ID:  $($parsed.response_id)" -ForegroundColor White
Write-Host "Duration:     $([math]::Round($duration, 1)) seconds" -ForegroundColor White
Write-Host "Tokens:       $totalTokens total (in: $inputTokens, out: $outputTokens)" -ForegroundColor White
Write-Host ""
Write-Host "OUTPUT FILES:" -ForegroundColor Cyan
Write-Host "  Full response: $OutputFile" -ForegroundColor Gray
Write-Host "  Tool content:  $ToolFile" -ForegroundColor Gray
Write-Host "  Receipt:       $ReceiptFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Your generated tool is ready at:" -ForegroundColor Yellow
Write-Host "  $ToolFile" -ForegroundColor White
Write-Host ""
