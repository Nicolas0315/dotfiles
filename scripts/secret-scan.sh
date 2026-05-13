#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '## high-confidence secret scan\n'
findings="$(
  rg -n --hidden -S \
    '(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|-----BEGIN|PRIVATE KEY|password\s*=|api[_-]?key\s*=|token\s*=|secret\s*=|ANTHROPIC_API_KEY=|OPENAI_API_KEY=|GEMINI_API_KEY=)' \
    "$repo_dir" \
    -g '!**/.git/**' \
    -g '!brew/Brewfile' \
    -g '!**/scripts/secret-scan.sh' \
    || true
)"

allowed="$(
  printf '%s\n' "$findings" | rg 'home/\.functions:.*op item get .*--reveal' || true
)"
unexpected="$(
  printf '%s\n' "$findings" | rg -v 'home/\.functions:.*op item get .*--reveal' || true
)"

if [ -n "$allowed" ]; then
  printf 'allowed secret-adjacent lookup:\n%s\n\n' "$allowed"
fi

if [ -n "$unexpected" ]; then
  printf 'unexpected secret-like findings:\n%s\n' "$unexpected" >&2
  exit 1
fi

printf 'ok: no unexpected secret-like findings\n'
