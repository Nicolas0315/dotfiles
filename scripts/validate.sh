#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '## script syntax\n'
bash -n "$repo_dir"/scripts/*.sh
printf 'ok: bash scripts\n\n'

printf '## zsh syntax\n'
zsh -n \
  "$repo_dir/home/.zshrc" \
  "$repo_dir/home/.paths" \
  "$repo_dir/home/.exports" \
  "$repo_dir/home/.functions" \
  "$repo_dir/home/.aliases" \
  "$repo_dir/home/.tooling"
printf 'ok: zsh fragments\n\n'

printf '## live command resolution\n'
zsh -lic 'which -a node npm codex claude gemini; codex --version; claude --version; gemini --version' 2>&1 \
  | sed '/^Restored session:/d;/^Saving session/d;/^\.\.\./d'
printf '\n'

printf '## shell ergonomics\n'
zsh -lic '
  alias ls ll tree cat c cx g
  command -v zoxide
  zoxide query -l 2>/dev/null | sed -n "1,5p"
  bindkey | grep -q bracketed-paste
  printf "ok: bracketed paste binding\n"
' 2>&1 | sed '/^Restored session:/d;/^Saving session/d;/^\.\.\./d'
printf '\n'

printf '## zellij validation\n'
zellij_check="$(mktemp)"
zellij_layout="$(mktemp)"
if zsh -lic 'command -v zellij; zellij --version; command -v ft; printf "EDITOR=%s\nVISUAL=%s\n" "${EDITOR:-}" "${VISUAL:-}"; zellij setup --check' >"$zellij_check" 2>&1 \
  && zellij setup --dump-layout ghostty-vscode >"$zellij_layout" 2>&1; then
  if rg -q '\[DEFAULT EDITOR\]: Not set' "$zellij_check"; then
    tr -d '\000' < "$zellij_check" >&2
    rm -f "$zellij_check" "$zellij_layout"
    exit 1
  fi
  sed '/^Restored session:/d;/^Saving session/d;/^\.\.\./d' "$zellij_check" | sed -n '1,8p'
  printf 'ok: zellij layout ghostty-vscode\n'
else
  tr -d '\000' < "$zellij_check" >&2
  tr -d '\000' < "$zellij_layout" >&2
  rm -f "$zellij_check" "$zellij_layout"
  exit 1
fi
rm -f "$zellij_check" "$zellij_layout"
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
