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
chezmoi_status="$(chezmoi status)"
if [ -n "$chezmoi_status" ]; then
  printf '%s\n' "$chezmoi_status" >&2
  printf 'chezmoi source and live state differ\n' >&2
  exit 1
fi
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
printf '\n'

# 誤爆すると Cursor/Claude Desktop の内蔵端末や SSH セッションまで herdr TUI に
# 乗っ取られ、この validate.sh 自身(zsh -lic)も止まる。HOME を差し替えてガード節だけを
# 隔離実行し、起動する条件としない条件の両方を確かめる。
printf '## herdr auto-attach guard\n'
guard_home="$(mktemp -d)"
trap 'rm -rf "$guard_home"' EXIT
mkdir -p "$guard_home/bin"
printf '#!/bin/sh\necho HERDR_LAUNCHED\n' > "$guard_home/bin/herdr"
chmod +x "$guard_home/bin/herdr"
sed -n '/^# Ghostty の新規ウィンドウは herdr/,/^fi$/p' "$repo_dir/dot_zshrc" > "$guard_home/.zshrc"
grep -q 'command -v herdr' "$guard_home/.zshrc" || { printf 'guard block not found in dot_zshrc\n' >&2; exit 1; }

guard_run() {  # $1=tty(yes/no), 残りは env
  local tty="$1"; shift
  if [ "$tty" = yes ]; then
    env -i HOME="$guard_home" PATH="$guard_home/bin:/usr/bin:/bin" "$@" \
      script -q /dev/null zsh -i -c true 2>/dev/null | grep -c HERDR_LAUNCHED || true
  else
    env -i HOME="$guard_home" PATH="$guard_home/bin:/usr/bin:/bin" "$@" \
      zsh -i -c true 2>/dev/null | grep -c HERDR_LAUNCHED || true
  fi
}
guard_fail=0
guard_check() {
  if [ "$2" = "$3" ]; then printf 'ok: %s\n' "$1"
  else printf 'FAIL: %s (expected=%s actual=%s)\n' "$1" "$2" "$3" >&2; guard_fail=1; fi
}
guard_check "Ghostty + tty なら attach する"        1 "$(guard_run yes TERM_PROGRAM=ghostty)"
guard_check "tty 無しでは attach しない"             0 "$(guard_run no  TERM_PROGRAM=ghostty)"
guard_check "Cursor/VS Code 内蔵端末を巻き込まない"   0 "$(guard_run yes TERM_PROGRAM=vscode)"
guard_check "TERM_PROGRAM 未設定では attach しない"   0 "$(guard_run yes)"
guard_check "herdr ペイン内で再帰しない"             0 "$(guard_run yes TERM_PROGRAM=ghostty HERDR_ENV=1)"
guard_check "SSH セッションを乗っ取らない"            0 "$(guard_run yes TERM_PROGRAM=ghostty SSH_CONNECTION=x)"
guard_check "NO_HERDR=1 の逃げ道が効く"              0 "$(guard_run yes TERM_PROGRAM=ghostty NO_HERDR=1)"
[ "$guard_fail" -eq 0 ] || exit 1
