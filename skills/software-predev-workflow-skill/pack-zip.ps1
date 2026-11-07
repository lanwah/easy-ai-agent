# Pack repo files into software-predev-workflow-skill.zip, honoring .gitignore.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$zipName = 'software-predev-workflow-skill.zip'
$skip = @($zipName, 'pack-zip.bat', 'pack-zip.ps1', '.gitignore')

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git not found in PATH'
}

# Read git output as UTF-8 so Chinese paths (e.g. templates/*.md) are not mangled.
function Get-GitLinesUtf8([string[]]$GitArgs) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'git'
    $psi.Arguments = ($GitArgs | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join ' '
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $p = [System.Diagnostics.Process]::Start($psi)
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) {
        throw "git failed ($($p.ExitCode)): $stderr"
    }
    return @(
        $stdout -split '\r?\n' |
        ForEach-Object { $_.TrimEnd() } |
        Where-Object { $_ }
    )
}

function Test-IgnoredByGitIgnore([string]$RelPath) {
    # --no-index: honor .gitignore even for already-tracked paths
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'git'
    $psi.Arguments = "check-ignore --no-index -q -- `"$RelPath`""
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $null = $p.StandardOutput.ReadToEnd()
    $null = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    return ($p.ExitCode -eq 0)
}

$files = Get-GitLinesUtf8 @(
    '-c', 'core.quotepath=false',
    'ls-files', '--cached', '--others', '--exclude-standard'
)

$files = @(
    $files |
    Where-Object {
        $_ -and
        ($skip -notcontains $_) -and
        -not (Test-IgnoredByGitIgnore $_) -and
        (Test-Path -LiteralPath $_ -PathType Leaf)
    }
)

if ($files.Count -eq 0) {
    throw 'No files to pack'
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipPath = Join-Path $PSScriptRoot $zipName
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

$zip = [System.IO.Compression.ZipFile]::Open(
    $zipPath,
    [System.IO.Compression.ZipArchiveMode]::Create
)
try {
    $n = 0
    foreach ($rel in $files) {
        $full = Join-Path $PSScriptRoot $rel
        $entry = ($rel -replace '\\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip,
            $full,
            $entry,
            [System.IO.Compression.CompressionLevel]::Optimal
        )
        $n++
    }
    Write-Host "Packed $n files -> $zipPath"
}
finally {
    $zip.Dispose()
}
