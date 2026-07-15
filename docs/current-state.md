# Current State - 2026-07-15

Repo: `~/work/dotfiles`
Mode: public chezmoi-managed dotfiles repo under GitHub Flow.

## Structure Contract

- Canonical dotfiles tree: chezmoi source state (`dot_*`, `symlink_*`, `.chezmoi.toml.tmpl`, `.chezmoiignore`).
- The legacy copy-based tree (`home/`, `config/`, `app-support/`, `manifest.tsv`, `scripts/{snapshot,apply,diff-live}.sh`) was removed on 2026-07-15 after confirming it had drifted far behind live files; history retains it.
- `brew/Brewfile` is a full `brew bundle dump` snapshot of the machine inventory (taps, brew, cask, mas, vscode, uv, npm, cargo).
- Zellij layouts were dropped: `~/.config/zellij/` no longer exists live; tmux (via `katala-tooling`) owns multiplexing.
- `~/.aliases`, `~/.exports`, `~/.functions` are dead live files (nothing sources them; aliases/tool init live in `katala-tooling` `profile.sh`), so they are not tracked here. A company AWS SAML helper found in the old copy was moved to machine-local `~/.functions.local` on 2026-07-15.

## Public-Release Sanitization - 2026-07-15

- Full-history secret scan: `gitleaks git .` clean; `scripts/secret-scan.sh` clean.
- No hardcoded `/Users/<name>` paths in tracked files; `dot_config/git/config.tmpl` and `symlink_dot_tmux.conf.tmpl` use `{{ .chezmoi.homeDir }}`.
- Machine asset tag removed from config comments.
- Committed identity data (git author name/email, SSH public key in `allowed_signers`, 1Password item identifiers) is intentional and public-safe.

## Verification

- CI runs `scripts/verify.sh` (syntax, source layout, path hygiene, secret scan).
- Local Mac behavior changes should also run `scripts/validate.sh`.
- `chezmoi apply` is the only live-`$HOME` mutation gate and requires explicit approval.
