#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
brewfile="$repo_dir/brew/Brewfile"

if [ ! -f "$brewfile" ]; then
  printf 'missing Brewfile: %s\n' "$brewfile" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'brew not found in PATH\n' >&2
  exit 1
fi

brew bundle check --verbose --file "$brewfile"
