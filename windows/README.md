# Windows dev-environment parity

Windows-side parallel of the macOS dotfiles. Goal: a machine can be brought up
to the same tool/AI-CLI/secret state as a Mac, without fleet-style sync.

> **Status: authored on macOS, not yet verified on a Windows host.**
> Review dry-run output before applying. Validate on a real Windows node and
> record results in `~/work/docs/dev-env-portability/`.

## Files

- `setup.ps1` — installs the toolset from `../tools/matrix.tsv` (winget/scoop/npm).
  Dry-run by default; `-Apply` to install. `-Group req|ai|rec` to scope.
- `profile.ps1` — shell init parallel of `config/profile.sh` (PATH, aliases,
  zoxide/atuin/direnv/starship, host-local secrets). Dot-source from `$PROFILE`.
- `dev-doctor.ps1` — read-only health check parallel of `katala-tooling/bin/dev-doctor`.

## Bring-up (Windows, PowerShell 7+)

```powershell
# 1. package managers (one-time): winget ships with Windows; scoop optional
#    irm get.scoop.sh | iex

# 2. install tools (review the plan first)
pwsh -File windows\setup.ps1            # dry-run
pwsh -File windows\setup.ps1 -Apply     # install

# 3. shell init
Add-Content $PROFILE '. "$env:USERPROFILE\work\dotfiles\windows\profile.ps1"'

# 4. AI CLIs auth
claude   # login flow
codex auth login
gemini   # login flow

# 5. secrets: op signin, then per-repo
op signin
op inject -i .env.tmpl -o .env

# 6. verify
pwsh -File windows\dev-doctor.ps1
```

`ghq`は`winget:x-motemen.ghq`から導入し、新規cloneだけを既定の
`$HOME\ghq\<host>\<owner>\<repo>`へ置きます。既存`$HOME\work`は移動しません。

## Notes

- `tools/matrix.tsv` is the single source of truth shared with macOS. Update it
  there, not per-OS.
- `wsl`-tagged tools (tmux, semgrep) install on the Linux/WSL side.
- Secrets follow the same rule as macOS: only `op://` references are committed;
  real values stay in 1Password and are materialized locally.
