#!/usr/bin/env bash
# 実機環境の健康診断。verify.sh（リポ整合性・CI）とは別の責務。
# WHY: chezmoi/Brew/mise の設定エラーや PATH の乱れを数値スコアで可視化し、
#      日常的に `make doctor` を実行する価値のある診断レポートにする。
set -uo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERBOSE="${VERBOSE:-0}"

pass=0; warn_count=0; fail_count=0; total=0
ISSUES=""; RECOMMENDATIONS=""

_ok()   { total=$((total+1)); pass=$((pass+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
_warn() {
  total=$((total+1)); warn_count=$((warn_count+1))
  printf '  \033[33m⚠\033[0m %s\n' "$1"
  ISSUES="${ISSUES}  ⚠ ${2:-$1}\n"
}
_fail() {
  total=$((total+1)); fail_count=$((fail_count+1))
  printf '  \033[31m✗\033[0m %s\n' "$1"
  ISSUES="${ISSUES}  ✗ $1\n"
}
_check() {
  local label="$1"; shift
  total=$((total+1))
  if eval "$@" >/dev/null 2>&1; then
    pass=$((pass+1)); printf '  \033[32m✓\033[0m %s\n' "$label"
  else
    fail_count=$((fail_count+1)); printf '  \033[31m✗\033[0m %s\n' "$label"
    ISSUES="${ISSUES}  ✗ $label\n"
  fi
}
_rec() { RECOMMENDATIONS="${RECOMMENDATIONS}  • $1\n"; }
_section() { printf '\n\033[1m── %s ──\033[0m\n' "$1"; }

_section "OS / Shell"
_check "macOS"  'sw_vers'
_check "zsh"    'command -v zsh'

_section "Package Manager"
if command -v brew >/dev/null 2>&1; then
  _ok "Homebrew $(brew --version | head -1 | sed 's/Homebrew //')"
  brew_out="$(brew doctor 2>&1)"
  if echo "$brew_out" | grep -q "Your system is ready to brew"; then
    _ok "brew doctor"
  else
    warn_cnt="$(echo "$brew_out" | grep -c "Warning:" 2>/dev/null || echo "?")"
    _warn "brew doctor" "${warn_cnt} warning(s) — run: brew doctor"
    _rec "brew doctor"
  fi
  # --no-upgrade: バージョン古いものは「充足」とみなし、純粋な未インストールのみを検出
  bundle_out="$(brew bundle check --file="$DOTFILES_DIR/brew/Brewfile" --no-upgrade --verbose 2>&1)"
  bundle_exit=$?
  missing_count="$(echo "$bundle_out" | grep -c "needs to be installed" || true)"
  if [ "$bundle_exit" -eq 0 ]; then
    _ok "Brewfile 充足"
  elif [ "${missing_count:-0}" -eq 0 ]; then
    _fail "Brewfile check failed (exit $bundle_exit; installation state unknown)"
  else
    _warn "Brewfile 充足" "${missing_count} パッケージ未インストール"
    _rec "brew bundle --file=$DOTFILES_DIR/brew/Brewfile"
  fi
else
  _fail "Homebrew"
  _rec "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

_section "ランタイム (mise)"
if command -v mise >/dev/null 2>&1; then
  _ok "mise $(mise --version 2>/dev/null | head -1)"
  mise_doc="$(mise doctor 2>&1)"
  mise_exit=$?
  if [ "$mise_exit" -ne 0 ]; then
    _fail "mise doctor failed (exit $mise_exit)"
  elif echo "$mise_doc" | grep -qiE "^error|^warning.*no"; then
    _warn "mise doctor" "issues detected — run: mise doctor"
    _rec "mise doctor"
  else
    _ok "mise doctor"
  fi
else
  _fail "mise"
  _rec "brew install mise"
fi

_section "dotfiles (chezmoi)"
if command -v chezmoi >/dev/null 2>&1; then
  _ok "chezmoi $(chezmoi --version 2>/dev/null | head -1 | awk '{print $3}')"
  chezmoi_src="$(chezmoi source-path 2>/dev/null)"
  expected_src="$DOTFILES_DIR"
  if [ "$chezmoi_src" = "$expected_src" ]; then
    _ok "chezmoi source-path ($chezmoi_src)"
  else
    _fail "chezmoi source-path (期待: $expected_src, 実際: ${chezmoi_src:-未設定})"
    _rec "chezmoi init --source $expected_src"
  fi
  diff_out="$(chezmoi status --exclude=scripts,encrypted 2>/dev/null)"
  diff_exit=$?
  if [ "$diff_exit" -ne 0 ]; then
    _fail "chezmoi status failed (exit $diff_exit; drift unknown)"
  elif [ -z "$diff_out" ]; then
    _ok "chezmoi status (no-op; scripts/encrypted excluded)"
  else
    _warn "chezmoi diff" "未適用の変更あり"
    _rec "chezmoi apply"
    [ "$VERBOSE" = "1" ] && printf '%s\n' "$diff_out"
  fi
  chezmoi_doc="$(chezmoi doctor 2>&1)"
  chezmoi_exit=$?
  if [ "$chezmoi_exit" -ne 0 ]; then
    _fail "chezmoi doctor failed (exit $chezmoi_exit)"
  elif echo "$chezmoi_doc" | grep -qi "^error"; then
    _warn "chezmoi doctor" "$(echo "$chezmoi_doc" | grep -i "^error" | head -1)"
    _rec "chezmoi doctor"
  else
    _ok "chezmoi doctor"
  fi
  secrets_hit="$(grep -rIl "OP_SERVICE_ACCOUNT_TOKEN=" "$DOTFILES_DIR" --include="dot_*" --include="*.tmpl" 2>/dev/null || true)"
  if [ -n "$secrets_hit" ]; then
    _fail "Secrets 非混入 (漏洩候補: $secrets_hit)"
    _rec "git grep でトークン値を確認して除去"
  else
    _ok "Secrets 非混入"
  fi
else
  _fail "chezmoi"
  _rec "brew install chezmoi"
fi

_section "Git"
_check "Git"                  'command -v git'
_check "Git user.name"        '[ -n "$(git config --global user.name 2>/dev/null)" ]'
_check "Git user.email"       '[ -n "$(git config --global user.email 2>/dev/null)" ]'
_check "Git SSH署名"          '[ "$(git config --global gpg.format 2>/dev/null)" = ssh ]'
_check "Git signingkey"       '[ -n "$(git config --global user.signingkey 2>/dev/null)" ]'
_check "Git commit.gpgsign"   '[ "$(git config --global commit.gpgsign 2>/dev/null)" = true ]'

_section "SSH / 1Password"
_check "1Password CLI"  'command -v op'
ssh_out="$(timeout 10 ssh -T git@github.com 2>&1 || true)"
if echo "$ssh_out" | grep -q "successfully authenticated"; then
  _ok "SSH GitHub疎通"
else
  _fail "SSH GitHub疎通"
  _rec "ssh -T git@github.com で詳細確認"
fi

_section "Shell / PATH"
# PATH 重複: 先頭出現を正として重複エントリを列挙（Claude セッション注入パスは除外）
path_dups="$(echo "$PATH" | tr ':' '\n' | grep -v "local-agent-mode-sessions" | awk '!seen[$0]++ && prev[$0] {print $0} {prev[$0]=1}')"
# より単純な方法: sort | uniq -d で重複ありかを確認
path_dups="$(echo "$PATH" | tr ':' '\n' | grep -v "local-agent-mode-sessions" | sort | uniq -d)"
if [ -z "$path_dups" ]; then
  _ok "PATH 重複なし"
else
  while IFS= read -r dup; do
    [ -z "$dup" ] && continue
    _warn "PATH duplicate" "$dup"
  done <<< "$path_dups"
  _rec "dot_zshrc 末尾に typeset -U path PATH を追加"
fi

_section "ターミナル"
if [ -d /Applications/Ghostty.app ]; then
  _ok "Ghostty インストール済"
  ghostty_out="$(/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config 2>&1)"
  if echo "$ghostty_out" | grep -qi "^error\|invalid"; then
    _warn "Ghostty 設定検証" "設定エラー検出"
    _rec "ghostty +show-config 2>&1 | grep -i error"
  else
    _ok "Ghostty 設定検証"
  fi
  [ "$VERBOSE" = "1" ] && echo "$ghostty_out" | grep -E "^font|^theme|^confirm|^auto-update|^clipboard"
else
  _warn "Ghostty" "インストール未確認（AppStore/直接配布）"
fi

_section "AI CLI"
_check "Claude CLI"    'command -v claude'
_check "Codex CLI"     'command -v codex'

_section "開発ツール"
_check "Docker"   'command -v docker'
_check "VSCode"   'command -v code'
_check "Node"     'command -v node'
_check "Python"   'command -v python3'
_check "Go"       'command -v go'
_check "Rust"     'command -v cargo'

# ────────────────── 診断レポート ──────────────────
total_checks=$((pass + warn_count + fail_count))
[ "$total_checks" -gt 0 ] && score=$(( pass * 100 / total_checks )) || score=0

printf '\n\033[1m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
printf '\033[1mEnvironment Score: %d%%\033[0m  ' "$score"
printf '(%d/%d passed' "$pass" "$total_checks"
[ "$warn_count" -gt 0 ] && printf ', %d warnings' "$warn_count"
[ "$fail_count" -gt 0 ] && printf ', %d failures' "$fail_count"
printf ')\n'

if [ -n "$ISSUES" ]; then
  printf '\n\033[1mIssues\033[0m\n──────────────────────────────────────\n'
  printf '%b' "$ISSUES"
fi
if [ -n "$RECOMMENDATIONS" ]; then
  printf '\n\033[1mRecommendations\033[0m\n──────────────────────────────────────\n'
  printf '%b' "$RECOMMENDATIONS"
fi
printf '\033[1m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n\n'

[ "$fail_count" -eq 0 ]
