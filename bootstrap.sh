#!/usr/bin/env bash
# git clone <dotfiles-repo> ~/work/dotfiles && ~/work/dotfiles/bootstrap.sh
# 新マシンで一発実行すると brew→mise→chezmoi→verify の順に環境を構築する。
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="all"

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--check|--packages|--apply]

  --check  Read-only preflight. Show prerequisites and the changes that would
           be applied without installing packages or writing dotfiles.
  --packages  Install Homebrew and the Brewfile only.
  --apply     Apply dotfiles, install mise runtimes, then verify.
EOF
}

case "${1:-}" in
  "") ;;
  --check) MODE="check" ;;
  --packages) MODE="packages" ;;
  --apply) MODE="apply" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

_step() { printf '\n\033[1m── %s ──\033[0m\n' "$1"; }
_ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
_info() { printf '  \033[36m→\033[0m %s\n' "$1"; }

if [ "$MODE" = "check" ]; then
  _step "New Mac read-only preflight"
  failures=0
  for tool in git curl; do
    if command -v "$tool" >/dev/null 2>&1; then
      _ok "$tool: $(command -v "$tool")"
    else
      printf '  ✗ %s is required\n' "$tool" >&2
      failures=$((failures + 1))
    fi
  done
  if command -v brew >/dev/null 2>&1; then
    brew bundle check --file="$DOTFILES_DIR/brew/Brewfile" --no-upgrade || true
  else
    _info "Homebrew is not installed; packages or all mode will install it"
  fi
  if command -v chezmoi >/dev/null 2>&1; then
    chezmoi init --source "$DOTFILES_DIR" --dry-run --verbose
    chezmoi apply --source "$DOTFILES_DIR" --dry-run --verbose
  else
    _info "chezmoi is not installed; packages or all mode installs it through Brewfile"
  fi
  printf '\nManual gates: 1Password, GitHub, App Store, and Tailscale sign-in.\n'
  printf 'Runbook: %s/docs/new-mac.md\n' "$DOTFILES_DIR"
  [ "$failures" -eq 0 ]
  exit
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [ "$MODE" = "all" ] || [ "$MODE" = "packages" ]; then
  _step "Phase 1: Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    _info "Homebrew を導入中..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
  _ok "Homebrew $(brew --version | head -1)"
  _info "Brewfile を反映中..."
  if ! brew bundle --file="$DOTFILES_DIR/brew/Brewfile"; then
    printf '\nBrewfile did not finish. Complete App Store or tap authentication, then rerun:\n  %s --packages\n' "$0" >&2
    exit 1
  fi
  _ok "Brewfile 完了"
  [ "$MODE" = "packages" ] && exit 0
fi

for required in \
  "$HOME/work/katala-tooling/config/profile.sh" \
  "$HOME/work/katala-tooling/config/tmux.conf"; do
  if [ ! -f "$required" ]; then
    printf 'required companion file missing: %s\n' "$required" >&2
    printf 'Follow %s/docs/new-mac.md, then rerun with --apply.\n' "$DOTFILES_DIR" >&2
    exit 1
  fi
done

for tool in brew chezmoi mise; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf '%s is missing; run %s --packages first\n' "$tool" "$0" >&2
    exit 1
  }
done

_step "Phase 2: dotfiles (chezmoi)"
if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  _info "chezmoi init..."
  chezmoi init --source "$DOTFILES_DIR"
fi

backup_root="$HOME/.local/state/dotfiles-backups/bootstrap"
backup_dir="$backup_root/$(date +%Y%m%d-%H%M%S)"
backup_archive="$backup_dir/live-home-before-apply.tar.gz"
backup_paths=()
for path in \
  .zshrc .zprofile .tmux.conf \
  .config/git .config/ghostty/config .config/mise/config.toml \
  .config/starship.toml .config/dev-env/profile.sh; do
  [ -e "$HOME/$path" ] || [ -L "$HOME/$path" ] || continue
  backup_paths+=("$path")
done
if [ "${#backup_paths[@]}" -gt 0 ]; then
  mkdir -p "$backup_dir"
  tar -czf "$backup_archive" -C "$HOME" "${backup_paths[@]}"
  printf 'Backup: %s\n' "$backup_archive"
  printf 'Restore: tar -xzf %q -C %q\n' "$backup_archive" "$HOME"
  find "$backup_root" -mindepth 1 -maxdepth 1 -type d -print0 \
    | sort -zr \
    | awk -v RS='\0' 'NR > 5 { printf "%s%c", $0, 0 }' \
    | xargs -0r rm -r
fi
chezmoi apply --source "$DOTFILES_DIR"
_ok "chezmoi apply 完了"

_step "Phase 3: ランタイム (mise)"
eval "$(mise activate bash)"
mise install
_ok "mise install 完了"

_step "Phase 4: 検証"
"$DOTFILES_DIR/scripts/verify.sh"
"$DOTFILES_DIR/scripts/doctor.sh"
