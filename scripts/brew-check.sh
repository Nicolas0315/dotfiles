#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
brewfile="$repo_dir/brew/Brewfile"
strict=0

usage() {
  cat <<'USAGE'
Usage: scripts/brew-check.sh [--strict]

Read-only Brewfile check.

Default mode matches the workstation apply gate and ignores outdated packages.
Use --strict to also fail on outdated packages.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      strict=1
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

if [ ! -f "$brewfile" ]; then
  printf 'missing Brewfile: %s\n' "$brewfile" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'brew not found in PATH\n' >&2
  exit 1
fi

export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
export HOMEBREW_NO_ENV_HINTS="${HOMEBREW_NO_ENV_HINTS:-1}"

check_args=(--verbose --file "$brewfile")
if [ "$strict" -eq 0 ]; then
  check_args+=(--no-upgrade)
fi

brew bundle check "${check_args[@]}"
