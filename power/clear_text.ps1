<#
.SYNOPSIS
    Cleans ANSI escape sequences and terminal artifacts from text or markdown files.
    For every artifact found, the single word that comes immediately before it is removed too.
.EXAMPLE
    .\clear_text.ps1 -isDirectory $false -FilePath ".\Documentation\main.md"
.EXAMPLE
    .\clear_text.ps1 -isDirectory $true -FilePath ".\Documentation"
#>
param(
    [Parameter(Mandatory=$true)]
    [boolean]$isDirectory,
    [string]$FilePath,

    [string]$OutputPath = ""
)

# File types processed when cleaning a whole directory
$supportedExtensions = @(".md", ".txt", ".doc")

# 1. Regex for standard ANSI escape sequences (e.g., \x1B[...m)
$ansiPattern = "\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"

# 2. Regex for literal "ESC[...K" text artifacts if they were printed as raw strings
$literalEscPattern = "ESC\[[0-9;]*[a-zA-Z]"

# 3. One or more artifacts in a row, optionally preceded by ONE word.
#    - The word is any run of non-whitespace characters (it never crosses a line break).
#    - Spaces/tabs between the word and the artifact are removed together with the word.
#    - If the artifact is at the start of a line (no word before it), only the artifact is removed.
#    - Several artifacts back-to-back count as one error, so only one word is removed.
$artifact = "(?:$ansiPattern|$literalEscPattern)"
$cleanPattern = "(?:[^\s\x1B]+[ \t]*)?(?:$artifact)+"

function Clear-TextArtifacts {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    return ($Text -replace $cleanPattern, "")
}

# Detects real binary Word files (.doc = OLE2 header, .docx = ZIP header).
# Rewriting those as plain text would corrupt them, so they are skipped.
function Test-BinaryDocument {
    param([string]$Path)

    $buffer = New-Object byte[] 4
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $read = $stream.Read($buffer, 0, 4)
    }
    finally {
        $stream.Close()
    }
    if ($read -lt 4) { return $false }

    $isOle = ($buffer[0] -eq 0xD0 -and $buffer[1] -eq 0xCF -and $buffer[2] -eq 0x11 -and $buffer[3] -eq 0xE0)
    $isZip = ($buffer[0] -eq 0x50 -and $buffer[1] -eq 0x4B -and $buffer[2] -eq 0x03 -and $buffer[3] -eq 0x04)
    return ($isOle -or $isZip)
}

if (-not (Test-Path $FilePath)) {
    Write-Error "Path not found: $FilePath"
    return
}

if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = $FilePath # Overwrites the original file by default
}

if ($isDirectory) {
    if (-not (Test-Path $FilePath -PathType Container)) {
        Write-Error "Directory not found: $FilePath"
        return
    }

    # Process all supported files in the directory recursively
    Get-ChildItem -Path $FilePath -Recurse -File |
        Where-Object { $supportedExtensions -contains $_.Extension } |
        ForEach-Object {
            if (Test-BinaryDocument -Path $_.FullName) {
                Write-Host "Skipped (binary Word file, not plain text): $($_.FullName)" -ForegroundColor Yellow
                return   # inside ForEach-Object, 'return' moves on to the next file
            }
            $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
            Clear-TextArtifacts -Text $content | Out-File -FilePath $_.FullName -Encoding UTF8
            Write-Host "Cleaned: $($_.FullName)" -ForegroundColor Cyan
        }

    Write-Host "Finished processing the directory." -ForegroundColor Green
    return
}

# Single file: read, clean, save
if (Test-BinaryDocument -Path $FilePath) {
    Write-Warning "This looks like a binary Word file, not plain text. Skipped to avoid corrupting it: $FilePath"
    return
}

$content = Get-Content -Path $FilePath -Raw -Encoding UTF8
$cleanedContent = Clear-TextArtifacts -Text $content
$cleanedContent | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "File cleaned successfully: $OutputPath" -ForegroundColor Green