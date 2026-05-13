#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_dir/manifest.tsv"
apply=0
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$HOME/.dotfiles-apply-backups/$timestamp"

usage() {
  cat <<'USAGE'
Usage: scripts/apply.sh [--apply]

Dry-run by default. With --apply, copy allowlisted repo files into $HOME after
backing up existing live files under ~/.dotfiles-apply-backups/<timestamp>/.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      apply=1
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

if [ "$apply" -eq 0 ]; then
  printf 'dry-run: would apply files from %s\n' "$repo_dir"
else
  mkdir -p "$backup_root"
  printf 'backup: %s\n' "$backup_root"
fi

while IFS=$'\t' read -r repo_path home_path; do
  [ -z "${repo_path:-}" ] && continue
  case "$repo_path" in \#*) continue ;; esac

  repo_file="$repo_dir/$repo_path"
  live_file="$HOME/$home_path"

  if [ ! -e "$repo_file" ]; then
    printf 'missing repo file: %s\n' "$repo_path" >&2
    exit 1
  fi

  if [ "$apply" -eq 0 ]; then
    printf 'would apply: %s -> %s\n' "$repo_path" "$live_file"
    continue
  fi

  if [ -e "$live_file" ]; then
    backup_file="$backup_root/$home_path"
    mkdir -p "$(dirname "$backup_file")"
    cp -p "$live_file" "$backup_file"
  fi

  mkdir -p "$(dirname "$live_file")"
  cp -p "$repo_file" "$live_file"
  printf 'applied: %s -> %s\n' "$repo_path" "$live_file"
done < "$manifest"

if [ "$apply" -eq 1 ]; then
  printf 'restore example: cp -a %q/.zshrc %q/.zshrc\n' "$backup_root" "$HOME"
fi
