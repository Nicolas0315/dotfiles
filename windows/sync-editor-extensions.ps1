[CmdletBinding()]
param([switch]$Apply)

$ErrorActionPreference = 'Stop'
$AllowlistPath = Join-Path $PSScriptRoot '..\tools\editor-extensions.txt'
$Expected = @(Get-Content -LiteralPath $AllowlistPath | Where-Object { $_ } | Sort-Object)
$Drift = $false

foreach ($App in @('code', 'cursor')) {
  $Cli = Get-Command $App -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $Cli) { Write-Output "$App`: skipped (not installed)"; continue }

  $Installed = @(& $Cli.Source --list-extensions | Sort-Object)
  if (($Installed -join "`n") -eq ($Expected -join "`n")) {
    Write-Output "$App`: ok (2 extensions)"
    continue
  }
  $Drift = $true
  if (-not $Apply) { Write-Output "$App`: drift"; continue }

  $ExtensionRoot = if ($App -eq 'code') { '.vscode' } else { '.cursor' }
  $Metadata = Join-Path $env:USERPROFILE "$ExtensionRoot\extensions\extensions.json"
  $BackupRoot = Join-Path $env:USERPROFILE ".local\state\editor-extension-backups\$App"
  $BackupDir = Join-Path $BackupRoot ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
  New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
  $Manifest = Join-Path $BackupDir 'extensions.txt'
  & $Cli.Source --list-extensions --show-versions |
    Sort-Object |
    Set-Content -LiteralPath $Manifest -Encoding utf8
  Get-FileHash -Algorithm SHA256 -LiteralPath $Manifest
  if (Test-Path -LiteralPath $Metadata) {
    $BackupFile = Join-Path $BackupDir 'extensions.json'
    Copy-Item -LiteralPath $Metadata -Destination $BackupFile
    Get-FileHash -Algorithm SHA256 -LiteralPath $BackupFile
  }

  for ($Round = 0; $Round -lt 5; $Round++) {
    $Installed = @(& $Cli.Source --list-extensions)
    $Extras = @($Installed | Where-Object { $_ -and $_ -notin $Expected })
    if ($Extras.Count -eq 0) { break }
    foreach ($Extension in $Extras) {
      try { & $Cli.Source --uninstall-extension $Extension --force *> $null } catch {}
    }
  }
  $Installed = @(& $Cli.Source --list-extensions)
  foreach ($Extension in $Expected) {
    if ($Extension -notin $Installed) { & $Cli.Source --install-extension $Extension --force *> $null }
  }

  if (Test-Path -LiteralPath $BackupRoot) {
    Get-ChildItem -LiteralPath $BackupRoot -Directory |
      Sort-Object Name -Descending |
      Select-Object -Skip 5 |
      Remove-Item -Recurse -Force
  }
  Write-Output "$App`: applied"
}

if (-not $Apply -and $Drift) { exit 1 }
if ($Apply) { & $PSCommandPath; exit $LASTEXITCODE }
