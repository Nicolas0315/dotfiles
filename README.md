# Katala OS Dotfiles

Local, private dotfiles for the Company Mac Katala OS CLI environment.

This repository is intentionally copy-based. It does not replace live files with
symlinks, so a broken checkout cannot break shell startup by itself.

## Managed Files

The allowlist lives in `manifest.tsv`.

- `~/.zshrc`
- `~/.paths`
- `~/.exports`
- `~/.functions`
- `~/.aliases`
- `~/.tooling`
- `~/.tmux.conf`
- `~/.config/ghostty/config`
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/.config/zellij/layouts/ghostty-vscode.kdl`
- `~/.config/zellij/layouts/ai-dev.kdl`
- `~/.config/zellij/layouts/multi-agent.kdl`
- `~/.config/starship.toml`

## Workflow

Snapshot the current live files into this repo:

```sh
./scripts/snapshot.sh
```

Include a Homebrew package snapshot:

```sh
./scripts/snapshot.sh --with-brew
```

Check whether the Brewfile is currently satisfied without installing anything,
using the workstation `--no-upgrade` gate:

```sh
./scripts/brew-check.sh
```

`brew-check.sh` disables Homebrew auto-update by default so this check does not
refresh tap metadata just to report drift.

To also fail on outdated formulae and casks:

```sh
./scripts/brew-check.sh --strict
```

Compare repo files with live files:

```sh
./scripts/diff-live.sh
```

Validate repo syntax and the current live shell:

```sh
./scripts/validate.sh
```

Run the portable CI gate:

```sh
./scripts/verify.sh
```

Scan for raw secret-like values:

```sh
./scripts/secret-scan.sh
```

Ghostty validation uses `ghostty` from `PATH` when available, otherwise it falls
back to `/Applications/Ghostty.app/Contents/MacOS/ghostty`.

Review AI-agent tool candidates:

```sh
less research/ai-agent-tools.md
```

Apply repo files back to the live home directory:

```sh
./scripts/apply.sh --apply
```

`apply.sh` is dry-run by default. With `--apply`, it copies the current live
files to `~/.dotfiles-apply-backups/<timestamp>/` before replacing anything.
It keeps the newest 10 backup sets by default and prunes older sets in the same
run. Override the count with `--keep-backups <N>` or `DOTFILES_BACKUP_KEEP=<N>`.

## Secret Handling

Do not add raw tokens, SSH keys, API keys, auth databases, shell histories, or
MCP secret files to this repo.

The Gemini wrapper in `~/.functions` uses 1Password lookup on demand. The repo
may contain the 1Password item identifier, but it must not contain the revealed
secret value.

## Current Shell Policy

- nvm Node v22 is the preferred Node/npm/AI CLI provider.
- nvm is lazy-loaded in `~/.zprofile_local_minimal` (host-local, not tracked
  here): the `nvm` command triggers `nvm.sh` on first use; node/npm/npx run
  directly from PATH. This removed ~0.9s from login shell startup
  (1.82s -> 0.60s together with the compinit daily-cache guard in `~/.zshrc`).
- APM runtime remains a fallback only.
- `typeset -U path PATH` deduplicates PATH while preserving first occurrence.
- Aliases live in `~/.aliases`; do not append duplicate aliases directly to
  `~/.zshrc`.
- `zoxide` state is machine-local and learned over time. An empty or sparse
  zoxide database is not a dotfiles failure.
- zsh bracketed paste should be bound. If a terminal ever gets stuck emitting
  raw paste markers, run `printf '\e[?2004l'` in that terminal.
- Ghostty should render the terminal; zellij should own local pane layout.
- `atuin` owns Ctrl-R history search (initialized after fzf in `~/.tooling`);
  Up arrow stays native via `--disable-up-arrow`.
- `starship` renders the prompt; `~/.config/starship.toml` only raises
  `command_duration` min_time to suppress short-command timing noise.
- tmux remains available for persistence and remote work.
- `EDITOR` and `VISUAL` default to `vim` because `nvim` is not installed on
  this host.

## Installation Gates

These are intentionally not applied by `validate.sh`.

- `./scripts/brew-check.sh` is read-only and uses `--no-upgrade` by default.
  If it fails, decide whether to run
  `HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file ~/dotfiles/brew/Brewfile --no-upgrade`
  as a separate apply gate.
- `./scripts/brew-check.sh --strict` additionally reports outdated packages.
- `direnv` is already part of the Homebrew snapshot.
- `mise` and `neovim` remain future opt-in gates. `starship` and `atuin` are
  now enabled (see `~/.config/starship.toml` and the atuin init in
  `~/.tooling`).
