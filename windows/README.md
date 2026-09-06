# Windows dev-environment parity

Windows-side parallel of the macOS dotfiles. Goal: a machine can be brought up
to the same tool/AI-CLI/secret state as a Mac, without fleet-style sync.

The doctor and setup failure paths have native Windows regression tests.
Profile initialization and successful package installation still need per-host
verification. See [the Mac/Windows contract](../docs/cross-platform.md).

## Files

- `setup.ps1` — installs the toolset from `../tools/matrix.tsv` (winget/scoop/npm).
  Dry-run by default; `-Apply` to install. `-Group req|ai|rec` to scope.
- `profile.ps1` — shell init parallel of `config/profile.sh` (PATH, aliases,
  zoxide/atuin/direnv/starship, host-local secrets). Dot-source from `$PROFILE`.
- `dev-doctor.ps1` — read-only health check parallel of `katala-tooling/bin/dev-doctor`.
  Requires PowerShell 7+. `-Json` emits version, executable path, status and exit
  code per tool; `-TimeoutSeconds` defaults to 15. It never signs in or starts WSL.
  Exit 0 covers required/AI version probes only; inspect recommended failures too.
- `sync-editor-extensions.ps1` — checks the shared two-extension allowlist;
  `-Apply` backs up metadata, converges VS Code/Cursor, and verifies the result.

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
agy      # login flow (Google seat)

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
- Editor pruning covers the default local store only. Profiles, Remote SSH/WSL,
  containers, and Settings Sync remain separate; restore from the newest
  `extensions.txt` under `.local\state\editor-extension-backups`.
