# Deep-merge config.defaults.json with optional config.local.json; print effective JSON.
param(
  [Parameter(Mandatory = $true)]
  [string]$DefaultsPath,

  [string]$LocalPath
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Convert PSCustomObject / Hashtable into a mergeable Hashtable tree
function ConvertTo-Mergeable($Value) {
  if ($null -eq $Value) { return $null }
  if ($Value -is [System.Collections.IDictionary]) {
    $map = [ordered]@{}
    foreach ($key in $Value.Keys) {
      $map[$key] = ConvertTo-Mergeable $Value[$key]
    }
    return $map
  }
  if ($Value -is [psobject] -and -not ($Value -is [string])) {
    $map = [ordered]@{}
    foreach ($p in $Value.PSObject.Properties) {
      $map[$p.Name] = ConvertTo-Mergeable $p.Value
    }
    return $map
  }
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $list = @()
    foreach ($item in $Value) {
      $list += , (ConvertTo-Mergeable $item)
    }
    return $list
  }
  return $Value
}

# Deep merge: base <- override; recurse on objects, replace scalars/arrays
function Merge-Deep($Base, $Override) {
  if ($null -eq $Override) { return $Base }
  $baseIsMap = $Base -is [System.Collections.IDictionary]
  $overIsMap = $Override -is [System.Collections.IDictionary]
  if (-not $baseIsMap -or -not $overIsMap) {
    return $Override
  }
  $result = [ordered]@{}
  foreach ($key in $Base.Keys) {
    $result[$key] = $Base[$key]
  }
  foreach ($key in $Override.Keys) {
    if ($result.Contains($key)) {
      $result[$key] = Merge-Deep $result[$key] $Override[$key]
    } else {
      $result[$key] = $Override[$key]
    }
  }
  return $result
}

# Read JSON file; return $null if missing/empty
function Read-JsonObject([string]$Path) {
  if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $null }
  $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  return ConvertTo-Mergeable (ConvertFrom-Json -InputObject $raw)
}

if (-not (Test-Path -LiteralPath $DefaultsPath)) {
  Write-Error "Defaults file not found: $DefaultsPath"
  exit 1
}

if (-not $LocalPath) {
  $LocalPath = Join-Path (Split-Path -Parent $DefaultsPath) 'config.local.json'
}

$defaults = Read-JsonObject $DefaultsPath
if ($null -eq $defaults) { $defaults = [ordered]@{} }

$local = Read-JsonObject $LocalPath
$merged = Merge-Deep $defaults $local

$merged | ConvertTo-Json -Depth 32
