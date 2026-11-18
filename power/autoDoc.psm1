# ============================================================
# MODULE: autoDoc.psm1
# Description: Generate documentation (TXT, MD, Doxygen) for code files using Ollama.
# Usage:
#   Import-Module .\autoDoc.psm1
#   Set-OllamaModel -Name "phi3:mini"
#   Invoke-AutoDoc -Path ".\src" -OutputFormat "All" -Recurse
#   Invoke-AutoDoc -Path ".\src\main.cpp" -OutputFormat "md"
# ============================================================

# ===================== GLOBAL CONFIGURATION =====================
$script:OllamaModel  = "phi3:mini"   # Default model, can be changed with Set-OllamaModel
$script:MaxCodeChars = 4000          # Above this size a warning is shown (small models may truncate the input)
$script:Utf8NoBom    = New-Object System.Text.UTF8Encoding $false
$script:Fence        = '```'         # Built from a single-quoted string: backticks are NOT escape chars here
# =================================================================

<#
.SYNOPSIS
    Set the Ollama model to use for documentation generation.
.DESCRIPTION
    Changes the global model name used by Invoke-AutoDoc.
.PARAMETER Name
    Name of the Ollama model (e.g., "phi3:mini", "llama3.2:3b").
.EXAMPLE
    Set-OllamaModel -Name "phi3:mini"
#>
function Set-OllamaModel {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $script:OllamaModel = $Name
    Write-Host "Ollama model set to: $script:OllamaModel" -ForegroundColor Green
}

# ===================== PRIVATE HELPERS =====================

function Get-LanguageFromExtension {
    param([string]$Extension)
    switch ($Extension.ToLowerInvariant()) {
        '.c'                                    { return "C" }
        { $_ -in '.cpp', '.cc', '.h', '.hpp' }  { return "C++" }
        '.java'                                 { return "Java" }
        { $_ -in '.ps1', '.psm1', '.psd1' }     { return "PowerShell" }
        '.py'                                   { return "Python" }
        '.cs'                                   { return "C#" }
        '.js'                                   { return "JavaScript" }
        '.ts'                                   { return "TypeScript" }
        { $_ -in '.sh', '.bash' }               { return "Bash" }
        default                                 { return "General" }
    }
}

function Get-DocCommentStyle {
    param([string]$Language)
    switch ($Language) {
        { $_ -in 'C', 'C++', 'Java', 'C#' }     { return "Use /** ... */ Doxygen comments placed directly above each function, class and struct." }
        'PowerShell'                            { return "Use <# ... #> block comments placed directly above each function." }
        'Python'                                { return "Use triple-quoted docstrings inside each function and class, with Doxygen tags (@brief, @param, @return)." }
        { $_ -in 'JavaScript', 'TypeScript' }   { return "Use /** ... */ comments placed directly above each function and class." }
        'Bash'                                  { return "Use # comment blocks placed directly above each function." }
        default                                 { return "Use the standard comment syntax of the language, placed directly above each function and class." }
    }
}

function New-DoxygenPrompt {
    param([string]$Language, [string]$Code)
    $fence = $script:Fence
    $style = Get-DocCommentStyle -Language $Language
    return @"
You are a code documentation tool. Add Doxygen-style comments to the following $Language code.
CRITICAL RULES:
- Output ONLY the raw code with the added comments.
- Do NOT include any conversational text, explanations, or greetings.
- Do NOT wrap the output in markdown code blocks (like ${fence}cpp or $fence). Just raw code.
- Do NOT change, rename, reorder or remove any existing code.
- $style
- Every function must have a brief description, @param for each parameter, and @return if applicable.

Code:
$Code
"@
}

function New-MarkdownPrompt {
    param([string]$Language, [string]$Code)
    $fence = $script:Fence
    return @"
You are an expert technical writer. Generate professional Markdown documentation for the following $Language code.

CRITICAL RULES:
- Output ONLY the Markdown documentation content.
- Do NOT include conversational text, greetings, or explanations before or after.
- Follow the exact structure specified below. Do not deviate.

Structure:
# Library Overview
- Brief description of what this library/file does
- Key features and capabilities
- Use cases

## Objects & Data Structures
For each struct/class/object defined in the code:

### ObjectName
Brief description of the object.

#### Members
| Member | Type | Description |
|--------|------|-------------|
| member_name | data_type | What this member does |

## Functions
For each function/procedure:

### function_name(parameters)
**Description:** Clear explanation of what the function does.

**Parameters:**
- param1 (type): Description
- param2 (type): Description

**Returns:** Description of return value and type

**Example:**
$fence$Language
(short usage example)
$fence

Code:
$Code
"@
}

function New-TextPrompt {
    param([string]$Language, [string]$Code)
    return @"
You are a professional technical writer. Generate clean plain text documentation for the following $Language code.

CRITICAL RULES:
- Output ONLY plain ASCII text documentation.
- Do NOT include conversational text, greetings, or markdown wrappers.
- Use text-based formatting strictly as outlined below.

Structure:
LIBRARY OVERVIEW
================
Provide a clear description of what this library/file does and its main purpose.

OBJECTS & DATA STRUCTURES
=========================
For each struct/class/object in the code:

Object: ObjectName
------------------
Description of what this object represents and its purpose.

Members:
  - member_name (type): What this member stores/does

FUNCTIONS
=========
For each function/procedure:

Function: function_name(parameters)
-------------------------------------
Purpose: Clear explanation of what the function does

Parameters:
  - param1 (type): Description

Returns: Description of what is returned and its type

Notes: Any important considerations, edge cases, or usage tips

Code:
$Code
"@
}

# Models often wrap their whole answer in a code fence even when told not to. Remove that wrapper.
function Remove-CodeFence {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
    $trimmed = $Text.Trim()
    if ($trimmed -match '(?s)^```[^\r\n]*\r?\n(.*?)\r?\n?```$') {
        return $Matches[1]
    }
    return $Text
}

# Sends a prompt to Ollama through stdin and returns the answer as ONE string.
function Invoke-OllamaPrompt {
    param([string]$Prompt)
    $output = $Prompt | ollama run $script:OllamaModel
    if ($LASTEXITCODE -ne 0) {
        throw "ollama exited with code $LASTEXITCODE"
    }
    return ($output -join [Environment]::NewLine)
}

# Writes UTF-8 without BOM (Out-File -Encoding UTF8 adds a BOM in Windows PowerShell 5.1).
function Save-DocText {
    param([string]$Text, [string]$Destination)
    [System.IO.File]::WriteAllText($Destination, ($Text.TrimEnd() + [Environment]::NewLine), $script:Utf8NoBom)
}

# Documents ONE file in the requested format(s).
function New-FileDocumentation {
    param(
        [string]$FilePath,
        [string]$OutputFormat,
        [string]$OutputDir,
        [bool]$Overwrite,
        [hashtable]$Stats
    )

    $fileName  = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath)
    $language  = Get-LanguageFromExtension -Extension $extension

    Write-Host "Processing: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Cyan

    try {
        $code = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "  Could not read the file: $($_.Exception.Message)"
        $Stats.Failed++
        return
    }

    if ([string]::IsNullOrWhiteSpace($code)) {
        Write-Warning "  File is empty, skipped."
        $Stats.Skipped++
        return
    }

    if ($code.Length -gt $script:MaxCodeChars) {
        Write-Warning "  File is large ($($code.Length) chars). Small models may exceed their context window and produce incomplete documentation."
    }

    # With 'All', every file gets its own subfolder so the three outputs don't mix
    $fileOutputDir = $OutputDir
    if ($OutputFormat -eq 'All') {
        $fileOutputDir = Join-Path -Path $OutputDir -ChildPath $fileName
    }
    New-Item -ItemType Directory -Force -Path $fileOutputDir | Out-Null

    $jobs = @()
    if ($OutputFormat -in @('doxygen', 'All')) {
        $jobs += [pscustomobject]@{
            Label  = 'Doxygen'
            Path   = Join-Path -Path $fileOutputDir -ChildPath "$fileName$extension"
            Prompt = New-DoxygenPrompt -Language $language -Code $code
        }
    }
    if ($OutputFormat -in @('md', 'All')) {
        $jobs += [pscustomobject]@{
            Label  = 'Markdown'
            Path   = Join-Path -Path $fileOutputDir -ChildPath "$fileName.md"
            Prompt = New-MarkdownPrompt -Language $language -Code $code
        }
    }
    if ($OutputFormat -in @('txt', 'All')) {
        $jobs += [pscustomobject]@{
            Label  = 'Text'
            Path   = Join-Path -Path $fileOutputDir -ChildPath "$fileName.txt"
            Prompt = New-TextPrompt -Language $language -Code $code
        }
    }

    foreach ($job in $jobs) {
        $target = [System.IO.Path]::GetFullPath($job.Path)

        # Never overwrite the source file itself
        if ([string]::Equals($target, $FilePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Warning "  -> $($job.Label): the output path is the source file itself. Use a different -OutputDir."
            $Stats.Skipped++
            continue
        }

        # Check BEFORE calling the model, so existing files don't waste a generation
        if (-not $Overwrite -and (Test-Path -LiteralPath $target)) {
            Write-Host "  -> $($job.Label): file exists (use -Force to overwrite)" -ForegroundColor Yellow
            $Stats.Skipped++
            continue
        }

        try {
            $text = Remove-CodeFence -Text (Invoke-OllamaPrompt -Prompt $job.Prompt)
            if ([string]::IsNullOrWhiteSpace($text)) {
                throw "the model returned an empty response"
            }
            Save-DocText -Text $text -Destination $target
            Write-Host "  -> $($job.Label): $target" -ForegroundColor Green
            $Stats.Written++
        }
        catch {
            Write-Warning "  -> $($job.Label) failed: $($_.Exception.Message)"
            $Stats.Failed++
        }
    }
}

# ===================== PUBLIC FUNCTIONS =====================

<#
.SYNOPSIS
    Generate documentation for code files using Ollama.
.DESCRIPTION
    Supports TXT, MD, Doxygen, or All formats. Works on a single file or a folder.
.PARAMETER Path
    Path to a file or folder.
.PARAMETER OutputFormat
    Format of the output: 'txt', 'md', 'doxygen', or 'All' (generates all three).
.PARAMETER OutputDir
    Directory where generated documentation will be saved.
.PARAMETER Recurse
    If Path is a folder, process all matching files recursively.
.PARAMETER Extensions
    File extensions to include (e.g., @('.cpp','.h','.ps1')). Default includes common languages.
    Only used when Path is a folder; a single file is always processed.
.PARAMETER Force
    Overwrite existing output files.
.EXAMPLE
    Invoke-AutoDoc -Path ".\main.cpp" -OutputFormat "doxygen"
.EXAMPLE
    Invoke-AutoDoc -Path ".\src" -OutputFormat "All" -Recurse -Extensions @('.cpp','.h')
#>
function Invoke-AutoDoc {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [ValidateSet('txt', 'md', 'doxygen', 'All')]
        [string]$OutputFormat = "doxygen",

        [string]$OutputDir = ".\Documentation",

        [switch]$Recurse,

        [string[]]$Extensions = @('.cpp', '.c', '.h', '.hpp', '.java', '.ps1', '.psm1', '.py', '.cs', '.js', '.ts', '.bash'),

        [switch]$Force
    )

    # Accept both 'cpp' and '.cpp'
    $Extensions = @($Extensions | ForEach-Object { if ($_.StartsWith('.')) { $_ } else { ".$_" } })

    # 1. Validate the input first, before touching anything else
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Error "Path not found: $Path"
        return
    }

    # 2. Check Ollama
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Error "Ollama is not installed or not in PATH. Please install Ollama first."
        return
    }

    $installed = @(ollama list | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\s+')[0] })
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not talk to Ollama. Is the Ollama server running?"
        return
    }

    $hasModel = ($installed -contains $script:OllamaModel) -or ($installed -contains "$($script:OllamaModel):latest")
    if (-not $hasModel) {
        Write-Host "Model '$($script:OllamaModel)' not found locally. Pulling now..." -ForegroundColor Yellow
        ollama pull $script:OllamaModel
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to pull model '$($script:OllamaModel)'."
            return
        }
    }

    # 3. Output directory (resolved to a full path so .NET file APIs behave correctly)
    $OutputDirFull = (New-Item -ItemType Directory -Force -Path $OutputDir).FullName

    # 4. Make sure UTF-8 is used both when sending the code to Ollama and when reading its answer
    #    (Windows PowerShell 5.1 defaults to ASCII, which turns non-English text into '?')
    $OutputEncoding = $script:Utf8NoBom
    $previousConsoleEncoding = $null
    try {
        $previousConsoleEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = $script:Utf8NoBom
    }
    catch { }

    $stats = @{ Written = 0; Skipped = 0; Failed = 0 }

    try {
        $item = Get-Item -LiteralPath $Path

        if (-not $item.PSIsContainer) {
            # ----- Single file -----
            New-FileDocumentation -FilePath $item.FullName -OutputFormat $OutputFormat `
                -OutputDir $OutputDirFull -Overwrite ([bool]$Force) -Stats $stats
        }
        else {
            # ----- Folder -----
            $getParams = @{
                LiteralPath = $item.FullName
                File        = $true
            }
            if ($Recurse) { $getParams.Recurse = $true }

            # Skip the output folder itself, otherwise generated files would be documented again on the next run
            $outPrefix = $OutputDirFull.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar

            $files = @(Get-ChildItem @getParams | Where-Object {
                ($Extensions -contains $_.Extension) -and
                (-not $_.FullName.StartsWith($outPrefix, [System.StringComparison]::OrdinalIgnoreCase))
            })

            if ($files.Count -eq 0) {
                Write-Warning "No files with extensions ($($Extensions -join ', ')) found in $Path"
                return
            }

            foreach ($file in $files) {
                New-FileDocumentation -FilePath $file.FullName -OutputFormat $OutputFormat `
                    -OutputDir $OutputDirFull -Overwrite ([bool]$Force) -Stats $stats
            }
        }
    }
    finally {
        if ($previousConsoleEncoding) {
            try { [Console]::OutputEncoding = $previousConsoleEncoding } catch { }
        }
    }

    Write-Host ""
    Write-Host "Documentation completed. Written: $($stats.Written), skipped: $($stats.Skipped), failed: $($stats.Failed)" -ForegroundColor Green
    Write-Host "Output saved to: $OutputDirFull" -ForegroundColor Green
}

# Export the public functions (helpers above stay private)
Export-ModuleMember -Function Set-OllamaModel, Invoke-AutoDoc