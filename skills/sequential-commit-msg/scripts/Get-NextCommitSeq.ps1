#Requires -Version 5.1
<#
.SYNOPSIS
  Print the next sequential commit number for a repo (max #N in recent subjects + 1).

.PARAMETER ProjectRoot
  Target repository root (default: current directory).

.PARAMETER Lookback
  How many recent commit subjects to scan (default: 200).
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $ProjectRoot = (Get-Location).Path,

    [Parameter()]
    [ValidateRange(1, 5000)]
    [int] $Lookback = 200
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
Push-Location -LiteralPath $root
try {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not a git repository: $root"
    }

    $subjects = git log --format=%s -n $Lookback 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Empty repo / no commits yet
        Write-Output '1'
        return
    }

    $max = 0
    $pattern = '^#\s*(\d+)\s'
    foreach ($line in $subjects) {
        if ($null -eq $line) { continue }
        $m = [regex]::Match([string]$line, $pattern)
        if ($m.Success) {
            $n = [int]$m.Groups[1].Value
            if ($n -gt $max) { $max = $n }
        }
    }

    Write-Output ([string]($max + 1))
}
finally {
    Pop-Location
}
