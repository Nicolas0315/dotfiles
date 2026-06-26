<#
  profile.ps1 - Windows PowerShell parallel of katala-tooling/config/profile.sh.
  Dot-source from $PROFILE:
      . "$env:USERPROFILE\work\dotfiles\windows\profile.ps1"
  Every integration is guarded by a command/path existence check, so a missing
  tool never breaks shell startup. Secret values are never embedded here; the
  1Password service-account token is loaded from a host-local, untracked file.

  STATUS: not yet verified on a Windows host (authored from macOS). Validate on
  a real Windows node. See dev-env-portability assessment.
#>

# ---- PATH (prepend, dedupe-safe) ----
$prepend = @(
  (Join-Path $HOME 'bin'),
  (Join-Path $HOME '.local\bin'),
  (Join-Path $HOME '.cargo\bin'),
  (Join-Path $HOME 'scoop\shims'),
  (Join-Path $env:APPDATA 'npm')
)
foreach ($p in $prepend) {
  if ((Test-Path $p) -and ($env:PATH -split ';' -notcontains $p)) {
    $env:PATH = "$p;$env:PATH"
  }
}

# ---- Defaults (parity with profile.sh) ----
if (-not $env:EDITOR) { $env:EDITOR = 'vim' }
if (-not $env:VISUAL) { $env:VISUAL = $env:EDITOR }
if (-not $env:GOOGLE_CLOUD_PROJECT)  { $env:GOOGLE_CLOUD_PROJECT  = 'ugc-ai-477208' }
if (-not $env:GOOGLE_CLOUD_LOCATION) { $env:GOOGLE_CLOUD_LOCATION = 'us-central1' }

# ---- Aliases / functions ----
function gs { git status --short --branch @args }
function gd { git diff @args }
function gl { git log --oneline --decorate --graph -20 @args }
if (Get-Command lazygit -ErrorAction SilentlyContinue) { Set-Alias lg lazygit }
if (Get-Command eza -ErrorAction SilentlyContinue) {
  function ll { eza -la --group-directories-first --git @args }
} else {
  function ll { Get-ChildItem -Force @args }
}

# ---- Tool initializations (all guarded) ----
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
if (Get-Command atuin -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (atuin init powershell | Out-String) })
}
if (Get-Command direnv -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (direnv hook pwsh | Out-String) })
}
if ((Get-Command starship -ErrorAction SilentlyContinue) -and ($env:TERM -ne 'dumb')) {
  Invoke-Expression (&starship init powershell)
}

# ---- Host-local secrets (untracked; sets OP_SERVICE_ACCOUNT_TOKEN etc.) ----
$secretsLocal = Join-Path $HOME '.config\dev-env\secrets.local.ps1'
if (Test-Path $secretsLocal) { . $secretsLocal }
