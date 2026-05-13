#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_dir/manifest.tsv"
with_brew=0

usage() {
  cat <<'USAGE'
Usage: scripts/snapshot.sh [--with-brew]

Copy allowlisted live dotfiles from $HOME into this repository.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-brew)
      with_brew=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

while IFS=$'\t' read -r repo_path home_path; do
  [ -z "${repo_path:-}" ] && continue
  case "$repo_path" in \#*) continue ;; esac

  src="$HOME/$home_path"
  dst="$repo_dir/$repo_path"
  if [ ! -e "$src" ]; then
    printf 'skip missing: %s\n' "$src" >&2
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
  printf 'snapshotted: %s -> %s\n' "$src" "$repo_path"
done < "$manifest"

if [ "$with_brew" -eq 1 ]; then
  if command -v brew >/dev/null 2>&1; then
    mkdir -p "$repo_dir/brew"
    brew bundle dump --file="$repo_dir/brew/Brewfile" --force
    printf 'snapshotted: Homebrew -> brew/Brewfile\n'
  else
    printf 'brew not found; skipped Homebrew snapshot\n' >&2
  fi
fi
