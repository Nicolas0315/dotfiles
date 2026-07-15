<#
.SYNOPSIS
  setup.ps1 - install the cross-platform dev toolset on Windows from tools/matrix.tsv.
.DESCRIPTION
  Reads the win_pkg column of tools/matrix.tsv and installs each tool via the
  declared manager (winget / scoop / npm). Tools already resolvable on PATH are
  skipped (idempotent). `wsl`-tagged tools are reported as Linux-side only.

  Dry-run by default: it PRINTS the install commands and changes nothing.
  Pass -Apply to actually install.

  STATUS: not yet verified on a Windows host (authored from macOS). Review the
  printed dry-run plan before running -Apply. See dev-env-portability assessment.
.EXAMPLE
  pwsh -File setup.ps1            # dry-run: show the plan
  pwsh -File setup.ps1 -Apply     # install missing tools
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [ValidateSet('all', 'req', 'ai', 'rec')] [string]$Group = 'all',
  [string]$MatrixPath = (Join-Path $PSScriptRoot '..\tools\matrix.tsv')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MatrixPath)) { Write-Error "matrix not found: $MatrixPath"; exit 2 }

function Test-OnPath { param([string]$CommandLine)
  $cmd = ($CommandLine -split '\s+')[0]
  [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Invoke-Install { param([string]$WinPkg)
  $mgr, $id = $WinPkg -split ':', 2
  switch ($mgr) {
    'winget' { return @('winget', @('install', '--id', $id, '-e', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements')) }
    'scoop'  { return @('scoop',  @('install', $id)) }
    'npm'    { return @('npm',    @('install', '-g', $id)) }
    'wsl'    { return $null }
    default  { return $null }
  }
}

$plan = @()
Get-Content $MatrixPath | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $f = $_ -split "`t"
  if ($f.Count -lt 5) { return }
  $name = $f[0]; $grp = $f[1]; $winpkg = $f[3]; $check = $f[4]
  if ($Group -ne 'all' -and $grp -ne $Group) { return }
  if (Test-OnPath $check) { Write-Output "skip  $name ($grp) - already on PATH"; return }

  $spec = Invoke-Install $winpkg
  if ($null -eq $spec) { Write-Output "wsl   $name ($grp) - Linux/WSL side only ($winpkg)"; return }

  $exe = $spec[0]; $cmdArgs = $spec[1]
  $plan += [pscustomobject]@{ Name = $name; Group = $grp; Exe = $exe; Args = $cmdArgs }
  Write-Output "plan  $name ($grp) -> $exe $($cmdArgs -join ' ')"
}

if (-not $Apply) {
  Write-Output ""
  Write-Output "DRY-RUN: $($plan.Count) install(s) planned. Re-run with -Apply to install."
  exit 0
}

foreach ($p in $plan) {
  if (-not (Get-Command $p.Exe -ErrorAction SilentlyContinue)) {
    Write-Warning "$($p.Exe) not available - cannot install $($p.Name). Install the package manager first."
    continue
  }
  Write-Output "==> installing $($p.Name): $($p.Exe) $($p.Args -join ' ')"
  & $p.Exe @($p.Args)
}
Write-Output "setup.ps1: done. Run dev-doctor.ps1 to verify."
