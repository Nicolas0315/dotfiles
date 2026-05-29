# Dotfiles Repo Instructions

Shared baseline: `~/work/agent-context/AGENTS.MD`. This file only records repo-specific rules for this private dotfiles checkout.

## Scope

- This repo stores copy-based macOS dotfiles for the Company Mac CLI environment.
- Keep it private unless the user explicitly approves a public release review.
- Do not add raw tokens, SSH keys, API keys, auth databases, shell histories, MCP secret files, browser profiles, or generated backup directories.

## Validation

- CI gate: `scripts/verify.sh`
- Local Mac gate: `scripts/validate.sh`
- Secret gate: `scripts/secret-scan.sh`
- Apply dry-run: `scripts/apply.sh`

`scripts/validate.sh` checks live tools and macOS app state, so do not use it as a portable GitHub Actions gate.

## Mutation Rules

- `scripts/snapshot.sh` writes live dotfiles into the repo; run it only when refreshing the repo from the current Mac is the intended task.
- `scripts/apply.sh --apply` writes repo files back into `$HOME`; it requires explicit user approval.
- `scripts/apply.sh --apply` backs up replaced files under `~/.dotfiles-apply-backups/<timestamp>/`, keeps the newest 10 backup sets by default, and prunes older sets in the same run.
- Do not commit generated backups, `.env*`, `*.secret`, `*.local`, or machine-private temporary files.
