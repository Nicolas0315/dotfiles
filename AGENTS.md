# Dotfiles Repo Instructions

Shared baseline: `~/work/agent-context/AGENTS.MD`. This file only records repo-specific rules for this dotfiles checkout.

## Scope

- This repo stores chezmoi-managed macOS dotfiles plus a full tool inventory (`brew/Brewfile`) and a one-shot bootstrap (`bootstrap.sh`).
- This repo is public. Never add raw tokens, SSH private keys, API keys, auth databases, shell histories, MCP secret files, browser profiles, hostnames/asset tags, or generated backup directories.
- Secret references are allowed only as 1Password item identifiers or `op://` URIs; the revealed value must never appear.
- No hardcoded `/Users/<name>` paths; use `~` or `{{ .chezmoi.homeDir }}` templates. `scripts/verify.sh` enforces this.

## Validation

- CI gate: `scripts/verify.sh`
- Local Mac gate: `scripts/validate.sh`
- Secret gate: `scripts/secret-scan.sh`
- Apply dry-run: `chezmoi apply --dry-run --verbose`

`scripts/validate.sh` checks live tools and macOS app state, so do not use it as a portable GitHub Actions gate.

## Mutation Rules

- `chezmoi re-add <file>` refreshes the repo source from live `$HOME` files; run it only when snapshotting the current Mac is the intended task.
- `chezmoi apply` writes source files into `$HOME`; it requires explicit user approval. chezmoi keeps per-file state, and `chezmoi diff` must be reviewed first.
- Do not commit generated backups, `.env*`, `*.secret`, `*.local`, or machine-private temporary files.
