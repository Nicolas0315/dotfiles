<#
.SYNOPSIS
  dev-doctor.ps1 - read-only cross-machine dev-environment health check (Windows).
.DESCRIPTION
  Windows-native parallel of katala-tooling/bin/dev-doctor. Verifies the tools
  in tools/matrix.tsv, the three AI CLIs (claude/codex/gemini), 1Password
  sign-in state, and project .env materialization. It reports presence, short
  versions, and config-file presence only -- it never reads secret values,
  histories, or auth databases. Exit code is non-zero when a required tool or
  AI CLI is missing.

  STATUS: not yet verified on a Windows host (authored from macOS). Validate on
  a real Windows node before relying on it. See dev-env-portability assessment G1.
#>
[CmdletBinding()]
param(
  [string]$MatrixPath = (Join-Path $PSScriptRoot '..\tools\matrix.tsv')
)

$ErrorActionPreference = 'Continue'

function Get-ShortVersion {
  param([string[]]$CommandLine)
  $exe = $CommandLine[0]
  $rest = @()
  if ($CommandLine.Count -gt 1) { $rest = $CommandLine[1..($CommandLine.Count - 1)] }
  try {
    $out = & $exe @rest 2>$null | Select-Object -First 1
    if ($null -ne $out) { return ($out.ToString().Trim()) }
  } catch {}
  return ''
}

$missing = @{ req = 0; ai = 0; rec = 0 }

Write-Output "# dev-doctor (Windows)"
Write-Output ""
Write-Output "host: ``$env:COMPUTERNAME``"
Write-Output "date: ``$(Get-Date -Format o)``"
Write-Output "mode: ``read-only`` (no secret values read)"
Write-Output ""

if (-not (Test-Path $MatrixPath)) {
  Write-Error "matrix not found: $MatrixPath"
  exit 2
}

Write-Output "## Tools"
Write-Output ""
Write-Output "| Tool | Class | Status | Version |"
Write-Output "| --- | --- | --- | --- |"

Get-Content $MatrixPath | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $f = $_ -split "`t"
  if ($f.Count -lt 5) { return }
  $name = $f[0]; $group = $f[1]; $check = $f[4]
  $parts = $check -split '\s+'
  $cmd = $parts[0]
  if (Get-Command $cmd -ErrorAction SilentlyContinue) {
    $ver = Get-ShortVersion -CommandLine $parts
    Write-Output "| ``$name`` | $group | OK | $ver |"
  } else {
    Write-Output "| ``$name`` | $group | MISSING | - |"
    if ($missing.ContainsKey($group)) { $missing[$group]++ }
  }
}

Write-Output ""
Write-Output "## AI CLI configuration"
Write-Output ""
Write-Output "| CLI | Config present | Path |"
Write-Output "| --- | --- | --- |"
$aiCfg = @(
  @{ n = 'claude'; p = (Join-Path $HOME '.claude\settings.json') },
  @{ n = 'codex';  p = (Join-Path $HOME '.codex\config.toml') },
  @{ n = 'gemini'; p = (Join-Path $HOME '.gemini\settings.json') }
)
foreach ($c in $aiCfg) {
  $mark = if (Test-Path $c.p) { 'OK' } else { 'X' }
  Write-Output "| $($c.n) | $mark | ``$($c.p)`` |"
}

Write-Output ""
Write-Output "## Secrets readiness (1Password)"
Write-Output ""
if (Get-Command op -ErrorAction SilentlyContinue) {
  $who = (& op whoami 2>$null | Select-Object -First 1)
  if ($LASTEXITCODE -eq 0 -and $who) {
    Write-Output "- op: signed in ($who)"
  } else {
    Write-Output "- op: **NOT signed in** -- run ``op signin`` (or set OP_SERVICE_ACCOUNT_TOKEN)"
  }
} else {
  Write-Output "- op: CLI not installed"
}

Write-Output ""
Write-Output "## Project .env"
Write-Output ""
if (Test-Path '.env.tmpl') {
  if (Test-Path '.env') { Write-Output "- .env.tmpl present, .env materialized OK" }
  else { Write-Output "- .env.tmpl present, .env **missing** -- run ``op inject -i .env.tmpl -o .env``" }
} elseif ((Test-Path '.env.example') -and -not (Test-Path '.env')) {
  Write-Output "- .env.example present, .env missing (no op template yet)"
} else {
  Write-Output "- no .env.tmpl/.env.example in current directory"
}

Write-Output ""
Write-Output "## Summary"
Write-Output ""
Write-Output "- required missing: $($missing.req)"
Write-Output "- AI CLI missing: $($missing.ai)"
Write-Output "- recommended missing: $($missing.rec)"

if ($missing.req -gt 0 -or $missing.ai -gt 0) {
  Write-Output "- result: **FAIL** (required or AI CLI missing)"
  exit 1
}
Write-Output "- result: **OK**"
exit 0
