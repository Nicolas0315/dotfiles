#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '## script syntax\n'
bash -n "$repo_dir"/scripts/*.sh "$repo_dir/bootstrap.sh"
printf 'ok: bash scripts\n\n'

printf '## zsh syntax\n'
zsh -n \
  "$repo_dir/dot_zshrc" \
  "$repo_dir/dot_zprofile"
printf 'ok: zsh fragments\n\n'

printf '## chezmoi state\n'
chezmoi status
printf 'ok: chezmoi status (empty output above = source matches live)\n\n'

printf '## live command resolution\n'
zsh -lic 'which -a node npm codex claude gemini; codex --version; claude --version; gemini --version' 2>&1 \
  | sed '/^Restored session:/d;/^Saving session/d;/^\.\.\./d'
printf '\n'

printf '## shell ergonomics\n'
zsh -lic '
  alias ls ll tree cat
  command -v zoxide
  bindkey | grep -q bracketed-paste
  printf "ok: bracketed paste binding\n"
' 2>&1 | sed '/^Restored session:/d;/^Saving session/d;/^\.\.\./d'
printf '\n'

printf '## live startup time\n'
/usr/bin/time -p zsh -i -c exit 2>&1 \
  | sed '/^Restored session:/d;/^Saving session/d;/^\.\.\./d' \
  | sed -n '1,8p'
printf '\n'

ghostty_bin="$(command -v ghostty || true)"
if [ -z "$ghostty_bin" ] && [ -x "/Applications/Ghostty.app/Contents/MacOS/ghostty" ]; then
  ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

if [ -n "$ghostty_bin" ]; then
  printf '## Ghostty config validation\n'
  ghostty_output="$(mktemp)"
  if "$ghostty_bin" +validate-config >"$ghostty_output" 2>&1; then
    rm -f "$ghostty_output"
  else
    tr -d '\000' < "$ghostty_output" >&2
    rm -f "$ghostty_output"
    exit 1
  fi
  printf 'ok: Ghostty config\n'
else
  printf '## Ghostty config validation\n'
  printf 'skipped: ghostty command not found in PATH or /Applications\n'
fi
