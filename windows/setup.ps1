#requires -Version 7.0
<#
.SYNOPSIS
  setup.ps1 - install the cross-platform dev toolset on Windows from tools/matrix.tsv.
.DESCRIPTION
  Reads the win_pkg column of tools/matrix.tsv and installs each tool via the
  declared manager (winget / scoop / npm). Tools already resolvable on PATH are
  skipped (idempotent). `wsl`-tagged tools are reported as Linux-side only.

  Dry-run by default: it PRINTS the install commands and changes nothing.
  Pass -Apply to actually install.

  Failure and dry-run paths have native Windows regression tests. Successful
  package installation remains a per-host verification step.
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
$PSNativeCommandUseErrorActionPreference = $false
. (Join-Path $PSScriptRoot 'dev-tools.ps1')

try { $matrix = @(Read-DevMatrix $MatrixPath) }
catch { Write-Error 'Tool matrix missing or invalid' -ErrorAction Continue; exit 2 }

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
$matrix | ForEach-Object {
  $name = $_.Name; $grp = $_.Group; $winpkg = $_.Package; $check = $_.Check
  if ($Group -ne 'all' -and $grp -ne $Group) { return }
  if (Test-OnPath $check) { Write-Output "skip  $name ($grp) - already on PATH"; return }

  $spec = Invoke-Install $winpkg
  if ($null -eq $spec) { Write-Output "wsl   $name ($grp) - Linux/WSL side only ($winpkg)"; return }

  $exe = $spec[0]; $cmdArgs = $spec[1]
  $plan += [pscustomobject]@{ Name = $name; Group = $grp; Exe = $exe; Args = $cmdArgs; Check = $check }
  Write-Output "plan  $name ($grp) -> $exe $($cmdArgs -join ' ')"
}

if (-not $Apply) {
  Write-Output ""
  Write-Output "DRY-RUN: $($plan.Count) install(s) planned. Re-run with -Apply to install."
  exit 0
}

$failed = 0
foreach ($p in $plan) {
  if (-not (Get-Command $p.Exe -ErrorAction SilentlyContinue)) {
    Write-Warning "$($p.Exe) not available - cannot install $($p.Name). Install the package manager first."
    $failed++
    continue
  }
  Write-Output "==> installing $($p.Name): $($p.Exe) $($p.Args -join ' ')"
  & $p.Exe @($p.Args)
  $installExit = $LASTEXITCODE
  if ($installExit -ne 0) {
    Write-Warning "$($p.Name): install failed (exit $installExit)"
    $failed++
    continue
  }
  $probe = Invoke-DevProbe $p.Check
  if ($probe.Status -ne 'ok') {
    Write-Warning "$($p.Name): install returned zero but verification is $($probe.Status). A fresh shell may be required."
    $failed++
  }
}

# ghq uses Git's global config. Keep the default root (~/ghq); existing ~/work
# repositories are intentionally not migrated or added as a scan root.
if ($failed -gt 0) {
  Write-Error "setup.ps1: $failed failed or unverified operation(s). Run dev-doctor.ps1 in a fresh shell." -ErrorAction Continue
  exit 1
}
if (Get-Command git -ErrorAction SilentlyContinue) {
  git config --global ghq.user Nicolas0315
  if ($LASTEXITCODE -ne 0) { $failed++ }
  git config --global ghq.defaultHost github.com
  if ($LASTEXITCODE -ne 0) { $failed++ }
}
if ($failed -gt 0) {
  Write-Error "setup.ps1: $failed failed or unverified operation(s). Run dev-doctor.ps1 in a fresh shell."
  exit 1
}
Write-Output "setup.ps1: done. Run dev-doctor.ps1 to verify."
