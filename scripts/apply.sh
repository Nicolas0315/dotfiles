#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_dir/manifest.tsv"
apply=0
backup_keep="${DOTFILES_BACKUP_KEEP:-10}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_parent="$HOME/.dotfiles-apply-backups"
backup_root="$backup_parent/$timestamp"

usage() {
  cat <<'USAGE'
Usage: scripts/apply.sh [--apply] [--keep-backups N]

Dry-run by default. With --apply, copy allowlisted repo files into $HOME after
backing up existing live files under ~/.dotfiles-apply-backups/<timestamp>/.
Backup retention defaults to the 10 newest backup sets.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      apply=1
      ;;
    --keep-backups)
      if [ "$#" -lt 2 ]; then
        printf 'missing value for --keep-backups\n' >&2
        usage >&2
        exit 2
      fi
      backup_keep="$2"
      shift
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

case "$backup_keep" in
  ''|*[!0-9]*)
    printf 'backup retention must be a positive integer: %s\n' "$backup_keep" >&2
    exit 2
    ;;
esac
if [ "$backup_keep" -lt 1 ]; then
  printf 'backup retention must be at least 1\n' >&2
  exit 2
fi

prune_backups() {
  [ -d "$backup_parent" ] || return
  find "$backup_parent" -mindepth 1 -maxdepth 1 -type d -print \
    | while IFS= read -r backup_dir; do
        backup_name="${backup_dir##*/}"
        case "$backup_name" in
          [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9])
            printf '%s\n' "$backup_dir"
            ;;
        esac
      done \
    | sort -r \
    | awk -v keep="$backup_keep" -v current="$backup_root" '$0 == current { next } NR > keep' \
    | while IFS= read -r stale_backup; do
        rm -rf "$stale_backup"
        printf 'pruned backup: %s\n' "$stale_backup"
      done
}

if [ "$apply" -eq 0 ]; then
  printf 'dry-run: would apply files from %s\n' "$repo_dir"
  printf 'backup retention: keep %s newest sets under %s\n' "$backup_keep" "$backup_parent"
else
  mkdir -p "$backup_root"
  printf 'backup: %s\n' "$backup_root"
  printf 'backup retention: keep %s newest sets under %s\n' "$backup_keep" "$backup_parent"
fi

line_no=0
while IFS=$'\t' read -r repo_path home_path; do
  line_no=$((line_no + 1))
  [ -z "${repo_path:-}${home_path:-}" ] && continue
  case "$repo_path" in \#*) continue ;; esac

  if [ -z "${repo_path:-}" ] || [ -z "${home_path:-}" ]; then
    printf 'empty manifest field in row %s\n' "$line_no" >&2
    exit 1
  fi

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
  prune_backups
  printf 'restore example: cp -a %q/.zshrc %q/.zshrc\n' "$backup_root" "$HOME"
fi
