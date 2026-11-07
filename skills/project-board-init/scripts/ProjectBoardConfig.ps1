# Shared config helpers for Install-ProjectBoard.ps1 and Test-ProjectBoard.ps1.
# Dot-source only; do not execute this file directly.

function ConvertTo-ProjectBoardMap {
  param($Object)
  $map = @{}
  if ($null -eq $Object) { return $map }
  if ($Object -is [System.Collections.IDictionary]) {
    foreach ($key in $Object.Keys) {
      $map[$key] = ConvertTo-ProjectBoardMapValue $Object[$key]
    }
    return $map
  }
  foreach ($prop in $Object.PSObject.Properties) {
    $map[$prop.Name] = ConvertTo-ProjectBoardMapValue $prop.Value
  }
  return $map
}

function ConvertTo-ProjectBoardMapValue {
  param($Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [System.Collections.IDictionary]) {
    return (ConvertTo-ProjectBoardMap $Value)
  }
  if ($Value -is [string] -or $Value -is [System.Array] -or $Value -is [System.ValueType]) {
    return ,$Value
  }
  if ($Value.PSObject.Properties.Count -gt 0) {
    return (ConvertTo-ProjectBoardMap $Value)
  }
  return ,$Value
}

function Merge-ProjectBoardHashtable {
  param(
    [hashtable]$Base,
    [hashtable]$Overlay
  )
  foreach ($key in $Overlay.Keys) {
    $baseVal = $Base[$key]
    $overVal = $Overlay[$key]
    if ($baseVal -is [System.Collections.IDictionary] -and $overVal -is [System.Collections.IDictionary]) {
      Merge-ProjectBoardHashtable -Base $baseVal -Overlay $overVal | Out-Null
    } else {
      $Base[$key] = $overVal
    }
  }
  return $Base
}

function Get-ProjectBoardConfig {
  param(
    [Parameter(Mandatory = $true)][string]$DefaultsPath,
    [string]$LocalPath
  )
  if (-not (Test-Path -LiteralPath $DefaultsPath -PathType Leaf)) {
    throw "Defaults config not found: $DefaultsPath"
  }
  $base = ConvertTo-ProjectBoardMap (
    Get-Content -LiteralPath $DefaultsPath -Raw -Encoding UTF8 | ConvertFrom-Json
  )
  if ($LocalPath -and (Test-Path -LiteralPath $LocalPath -PathType Leaf)) {
    $overlay = ConvertTo-ProjectBoardMap (
      Get-Content -LiteralPath $LocalPath -Raw -Encoding UTF8 | ConvertFrom-Json
    )
    $base = Merge-ProjectBoardHashtable -Base $base -Overlay $overlay
  }
  return $base
}

function Get-ProjectBoardValue {
  param(
    [hashtable]$Map,
    [string]$Key,
    $Default = $null
  )
  if ($null -ne $Map -and $Map.ContainsKey($Key) -and $null -ne $Map[$Key]) {
    return $Map[$Key]
  }
  return $Default
}

function Assert-ProjectBoardRelativePath {
  param(
    [string]$Path,
    [string]$Name
  )
  if ([string]::IsNullOrWhiteSpace($Path) -or
      [System.IO.Path]::IsPathRooted($Path) -or
      $Path -match '(^|[\\/])\.\.([\\/]|$)' -or
      $Path -match '(^|[\\/])\.([\\/]|$)' -or
      $Path -match '[<>:"|?*]' -or
      $Path -match '[\\/\s]$') {
    throw "Invalid relative path in config ($Name): $Path"
  }
}
function Get-ProjectBoardStringList {
  param($Value)
  if ($null -eq $Value) { return @() }
  $list = @()
  foreach ($item in @($Value)) {
    if ($null -ne $item -and [string]$item -ne '') {
      $list += , ([string]$item)
    }
  }
  return $list
}
