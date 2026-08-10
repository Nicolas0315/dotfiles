#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '## required tools\n'
for tool in bash zsh awk; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'missing required tool: %s\n' "$tool" >&2
    exit 1
  }
  printf 'ok: %s\n' "$tool"
done
printf '\n'

printf '## script syntax\n'
bash -n "$repo_dir"/scripts/*.sh "$repo_dir/bootstrap.sh"
printf 'ok: bash scripts\n\n'

printf '## zsh syntax\n'
zsh -n \
  "$repo_dir/dot_zshrc" \
  "$repo_dir/dot_zprofile"
printf 'ok: zsh fragments\n\n'

printf '## chezmoi source layout\n'
for f in \
  "$repo_dir/.chezmoiignore" \
  "$repo_dir/.chezmoi.toml.tmpl" \
  "$repo_dir/dot_config/git/config.tmpl" \
  "$repo_dir/dot_config/ghostty/config" \
  "$repo_dir/dot_config/starship.toml" \
  "$repo_dir/dot_config/mise/config.toml" \
  "$repo_dir/symlink_dot_tmux.conf.tmpl" \
  "$repo_dir/docs/new-mac.md" \
  "$repo_dir/brew/Brewfile"; do
  [ -f "$f" ] || { printf 'missing source file: %s\n' "$f" >&2; exit 1; }
done
printf 'ok: source layout\n\n'

printf '## no hardcoded home paths\n'
if grep -rn '/Users/[a-z0-9]' \
  --exclude-dir=.git --exclude-dir=docs --exclude-dir=research \
  "$repo_dir" >&2; then
  printf 'hardcoded /Users/<name> path found; use ~ or {{ .chezmoi.homeDir }}\n' >&2
  exit 1
fi
printf 'ok: no hardcoded home paths\n\n'

printf '## new Mac entrypoint\n'
grep -q 'bootstrap.sh --check' "$repo_dir/docs/new-mac.md"
grep -q 'scripts/verify.sh' "$repo_dir/docs/new-mac.md"
grep -q 'scripts/bootstrap.sh' "$repo_dir/docs/new-mac.md"
printf 'ok: new Mac runbook has preflight, verification, and agent-context setup\n\n'

"$repo_dir/scripts/secret-scan.sh"
