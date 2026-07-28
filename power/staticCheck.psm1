# PowerShell wrapper for cppcheck static analysis
# Provides wrappers similar to staticCheck.bash functions

function Invoke-CCheckLib {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $IncludeDir,
        [Parameter(Mandatory=$true)] [string] $TargetDir
    )

    $exe = 'cppcheck'
    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
        Throw "'$exe' not found in PATH. Install cppcheck or add it to PATH."
    }

    $args = @(
        '--std=c11',
        '--enable=warning,style,performance,portability',
        '-I', $IncludeDir,
        '--suppress=unusedFunction',
        '--suppress=missingInclude',
        '--suppress=missingIncludeSystem',
        $TargetDir
    )

    & $exe @args
}

function Invoke-CxxCheckLib {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $IncludeDir,
        [Parameter(Mandatory=$true)] [string] $TargetDir
    )

    $exe = 'cppcheck'
    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
        Throw "'$exe' not found in PATH. Install cppcheck or add it to PATH."
    }

    $args = @(
        '--std=c++20',
        '--enable=warning,style,performance,portability',
        '-I', $IncludeDir,
        '--suppress=unusedFunction',
        '--suppress=missingInclude',
        '--suppress=missingIncludeSystem',
        $TargetDir
    )

    & $exe @args
}

function Invoke-CppCheckLib {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string[]] $Includes,
        [Parameter(Mandatory=$true)] [string] $Target
    )

    $exe = 'cppcheck'
    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
        Throw "'$exe' not found in PATH. Install cppcheck or add it to PATH."
    }

    $args = @('--std=c++20', '--enable=warning,style,performance,portability')
    foreach ($dir in $Includes) {
        $args += '-I'
        $args += $dir
    }

    $args += '--suppress=unusedFunction'
    $args += '--suppress=missingInclude'
    $args += '--suppress=missingIncludeSystem'
    $args += $Target

    & $exe @args
}

Export-ModuleMember -Function Invoke-CCheckLib, Invoke-CxxCheckLib, Invoke-CppCheckLib
