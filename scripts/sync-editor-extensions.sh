#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
allowlist="$repo_dir/tools/editor-extensions.txt"
mode="${1:---check}"

[ "$mode" = "--check" ] || [ "$mode" = "--apply" ] || {
  printf 'usage: %s [--check|--apply]\n' "$0" >&2
  exit 2
}

status=0
for app in code cursor; do
  cli="$(command -v "$app" || true)"
  [ -n "$cli" ] || { printf '%s: skipped (not installed)\n' "$app"; continue; }

  installed="$($cli --list-extensions | LC_ALL=C sort)"
  expected="$(LC_ALL=C sort "$allowlist")"
  if [ "$installed" = "$expected" ]; then
    printf '%s: ok (2 extensions)\n' "$app"
    continue
  fi
  status=1
  [ "$mode" = "--apply" ] || { printf '%s: drift\n' "$app"; continue; }

  metadata="$HOME/.${app/code/vscode}/extensions/extensions.json"
  backup_root="$HOME/.local/state/editor-extension-backups/$app"
  backup_dir="$backup_root/$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$backup_dir"
  "$cli" --list-extensions --show-versions | LC_ALL=C sort > "$backup_dir/extensions.txt"
  shasum -a 256 "$backup_dir/extensions.txt"
  if [ -f "$metadata" ]; then
    cp "$metadata" "$backup_dir/extensions.json"
    shasum -a 256 "$backup_dir/extensions.json"
  fi

  for _ in 1 2 3 4 5; do
    extras="$(comm -23 <($cli --list-extensions | LC_ALL=C sort) <(LC_ALL=C sort "$allowlist"))"
    [ -n "$extras" ] || break
    while IFS= read -r extension; do
      [ -n "$extension" ] || continue
      "$cli" --uninstall-extension "$extension" --force >/dev/null 2>&1 || true
    done <<< "$extras"
  done
  while IFS= read -r extension; do
    [ -n "$extension" ] || continue
    "$cli" --list-extensions | grep -Fxq "$extension" || "$cli" --install-extension "$extension" --force >/dev/null
  done < "$allowlist"

  if [ -d "$backup_root" ]; then
    find "$backup_root" -mindepth 1 -maxdepth 1 -type d \
      | LC_ALL=C sort -r \
      | sed -n '6,$p' \
      | while IFS= read -r old_backup; do rm -r -- "$old_backup"; done
  fi
  printf '%s: applied\n' "$app"
done

[ "$mode" = "--apply" ] || exit "$status"
exec "$0" --check
