#!/usr/bin/env bash
# git clone <dotfiles-repo> ~/work/dotfiles && ~/work/dotfiles/bootstrap.sh
# 新マシンで一発実行すると brew→mise→chezmoi→verify の順に環境を構築する。
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_step() { printf '\n\033[1m── %s ──\033[0m\n' "$1"; }
_ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
_info() { printf '  \033[36m→\033[0m %s\n' "$1"; }

# Phase 1: Homebrew
_step "Phase 1: Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  _info "Homebrew を導入中..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
_ok "Homebrew $(brew --version | head -1)"

# mise が Brewfile に含まれるので bundle より先にインストール済みか確認
if ! command -v mise >/dev/null 2>&1; then
  _info "mise を先行インストール中..."
  brew install mise
fi
_ok "mise $(mise --version)"

_info "Brewfile を反映中..."
brew bundle --file="$DOTFILES_DIR/brew/Brewfile" --no-lock
_ok "Brewfile 完了"

# Phase 2: ランタイム
_step "Phase 2: ランタイム (mise)"
eval "$(mise activate bash)"
mise install
_ok "mise install 完了"

# Phase 3: dotfiles を適用
_step "Phase 3: dotfiles (chezmoi)"
if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  _info "chezmoi init..."
  chezmoi init --source "$DOTFILES_DIR"
fi
chezmoi apply
_ok "chezmoi apply 完了"

# Phase 4: 環境診断
_step "Phase 4: 環境診断 (doctor)"
"$DOTFILES_DIR/scripts/doctor.sh"
