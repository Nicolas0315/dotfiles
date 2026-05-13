#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_dir/manifest.tsv"
had_diff=0

while IFS=$'\t' read -r repo_path home_path; do
  [ -z "${repo_path:-}" ] && continue
  case "$repo_path" in \#*) continue ;; esac

  repo_file="$repo_dir/$repo_path"
  live_file="$HOME/$home_path"

  if [ ! -e "$repo_file" ]; then
    printf 'repo missing: %s\n' "$repo_path"
    had_diff=1
    continue
  fi
  if [ ! -e "$live_file" ]; then
    printf 'live missing: %s\n' "$live_file"
    had_diff=1
    continue
  fi

  if ! diff -u "$repo_file" "$live_file"; then
    had_diff=1
  fi
done < "$manifest"

exit "$had_diff"
