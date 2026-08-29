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

# 1Password/Keychain lookup と、値が変数参照($始まり)の代入は許容する。
# 不変条件: 右辺が変数参照なら平文の秘密値はその行に存在しえない。生のリテラル値のみ警告。
allow_re='op item get .*--reveal|security (find|add)-generic-password|=[[:space:]]*"?\$\{?[A-Za-z_]|[A-Za-z_][A-Za-z0-9_]*=op://'
allowed="$(
  printf '%s\n' "$findings" | rg "$allow_re" || true
)"
unexpected="$(
  printf '%s\n' "$findings" | rg -v "$allow_re" || true
)"

if [ -n "$allowed" ]; then
  printf 'allowed secret-adjacent lookup:\n%s\n\n' "$allowed"
fi

if [ -n "$unexpected" ]; then
  printf 'unexpected secret-like findings:\n%s\n' "$unexpected" >&2
  exit 1
fi

printf 'ok: no unexpected secret-like findings\n'
