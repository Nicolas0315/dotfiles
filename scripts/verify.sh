#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '## required tools\n'
for tool in bash zsh rg awk; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'missing required tool: %s\n' "$tool" >&2
    exit 1
  }
  printf 'ok: %s\n' "$tool"
done
printf '\n'

printf '## script syntax\n'
bash -n "$repo_dir"/scripts/*.sh
printf 'ok: bash scripts\n\n'

printf '## zsh syntax\n'
zsh -n \
  "$repo_dir/home/.zshrc" \
  "$repo_dir/home/.paths" \
  "$repo_dir/home/.exports" \
  "$repo_dir/home/.functions" \
  "$repo_dir/home/.aliases" \
  "$repo_dir/home/.tooling"
printf 'ok: zsh fragments\n\n'

printf '## manifest allowlist\n'
awk -F '\t' '
  NF == 0 || $1 ~ /^#/ { next }
  NF != 2 { printf "invalid manifest row %d\n", NR > "/dev/stderr"; bad = 1; next }
  $1 == "" || $2 == "" { printf "empty manifest field in row %d\n", NR > "/dev/stderr"; bad = 1 }
  $1 ~ /^\// || $2 ~ /^\// { printf "absolute path in row %d\n", NR > "/dev/stderr"; bad = 1 }
  $1 ~ /\.\./ || $2 ~ /\.\./ { printf "parent traversal in row %d\n", NR > "/dev/stderr"; bad = 1 }
  seen_repo[$1]++ { printf "duplicate repo path in row %d: %s\n", NR, $1 > "/dev/stderr"; bad = 1 }
  seen_home[$2]++ { printf "duplicate home path in row %d: %s\n", NR, $2 > "/dev/stderr"; bad = 1 }
  END { exit bad }
' "$repo_dir/manifest.tsv"
while IFS=$'\t' read -r repo_path home_path; do
  [ -z "${repo_path:-}" ] && continue
  case "$repo_path" in \#*) continue ;; esac
  [ -n "${home_path:-}" ] || continue
  if [ ! -f "$repo_dir/$repo_path" ]; then
    printf 'missing manifest file: %s\n' "$repo_path" >&2
    exit 1
  fi
done < "$repo_dir/manifest.tsv"
printf 'ok: manifest\n\n'

"$repo_dir/scripts/secret-scan.sh"
