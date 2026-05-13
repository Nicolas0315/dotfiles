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

## Workflow

Snapshot the current live files into this repo:

```sh
./scripts/snapshot.sh
```

Include a Homebrew package snapshot:

```sh
./scripts/snapshot.sh --with-brew
```

Check whether the Brewfile is currently satisfied without installing anything:

```sh
./scripts/brew-check.sh
```

Compare repo files with live files:

```sh
./scripts/diff-live.sh
```

Validate repo syntax and the current live shell:

```sh
./scripts/validate.sh
```

Scan for raw secret-like values:

```sh
./scripts/secret-scan.sh
```

Ghostty validation uses `ghostty` from `PATH` when available, otherwise it falls
back to `/Applications/Ghostty.app/Contents/MacOS/ghostty`.

Apply repo files back to the live home directory:

```sh
./scripts/apply.sh --apply
```

`apply.sh` is dry-run by default. With `--apply`, it copies the current live
files to `~/.dotfiles-apply-backups/<timestamp>/` before replacing anything.

## Secret Handling

Do not add raw tokens, SSH keys, API keys, auth databases, shell histories, or
MCP secret files to this repo.

The Gemini wrapper in `~/.functions` uses 1Password lookup on demand. The repo
may contain the 1Password item identifier, but it must not contain the revealed
secret value.

## Current Shell Policy

- nvm Node v22 is the preferred Node/npm/AI CLI provider.
- APM runtime remains a fallback only.
- `typeset -U path PATH` deduplicates PATH while preserving first occurrence.
- Ghostty should render the terminal; zellij should own local pane layout.
- tmux remains available for persistence and remote work.
