#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '## high-confidence secret scan\n'
# Case-insensitive on purpose: uppercase env forms (DB_PASSWORD=, AWS_SESSION_TOKEN=)
# must not slip past this CI gate. Do not use rg -S here (smart-case + uppercase
# literals would force the whole pattern case-sensitive).
findings="$(
  rg -n --hidden -i \
    '(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN|PRIVATE KEY|password\s*=|api[_-]?key\s*=|token\s*=|secret\s*=|ANTHROPIC_API_KEY=|OPENAI_API_KEY=|GEMINI_API_KEY=|AWS_SESSION_TOKEN=|AKIA[0-9A-Z]{16}|xox[baprs]-|AIza[0-9A-Za-z_-]{20,})' \
    "$repo_dir" \
    -g '!**/.git/**' \
    -g '!brew/Brewfile' \
    -g '!**/scripts/secret-scan.sh' \
    || true
)"

# Allow only non-literal secret-adjacent lines:
# - 1Password / Keychain lookups
# - RHS that is a shell variable / command substitution (no plaintext value)
# - jq string builders that inject runtime credentials
# - pure comments / docs mentioning the tokens
# - scanners that grep for secret names (not values)
# Invariant: a true leaked literal value still fails.
allow_re='op item get|security (find|add)-generic-password|=[[:space:]]*"?\$|=\$\(|@sh\)|grep -rIl |^[^:]*:[0-9]+:[[:space:]]*#|private key material was observed|OPENCODE_ALLOW_INTERACTIVE'
allowed="$(
  printf '%s\n' "$findings" | rg -i "$allow_re" || true
)"
unexpected="$(
  printf '%s\n' "$findings" | rg -iv "$allow_re" || true
)"

if [ -n "$allowed" ]; then
  printf 'allowed secret-adjacent lookup:\n%s\n\n' "$allowed"
fi

if [ -n "$unexpected" ]; then
  printf 'unexpected secret-like findings:\n%s\n' "$unexpected" >&2
  exit 1
fi

printf 'ok: no unexpected secret-like findings\n'
