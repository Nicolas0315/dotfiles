DOTFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := doctor

.PHONY: bootstrap bootstrap-check bootstrap-packages bootstrap-apply verify doctor doctor-verbose update runtime-upgrade clean help

bootstrap: ## 新マシン: brew→mise→chezmoi→doctor を一括実行
	@bash $(DOTFILES_DIR)bootstrap.sh

bootstrap-check: ## 新マシン: 書き込みなしの事前確認
	@bash $(DOTFILES_DIR)bootstrap.sh --check

bootstrap-packages: ## 新マシン: Homebrew/Brewfile を導入
	@bash $(DOTFILES_DIR)bootstrap.sh --packages

bootstrap-apply: ## 新マシン: dotfiles/runtime を適用して検証
	@bash $(DOTFILES_DIR)bootstrap.sh --apply

verify: ## リポ整合性チェック (CI と同一: 構文・レイアウト・secrets)
	@bash $(DOTFILES_DIR)scripts/verify.sh

doctor: ## 実機環境の健康診断とスコア表示
	@bash $(DOTFILES_DIR)scripts/doctor.sh

doctor-verbose: ## doctor の詳細表示 (chezmoi diff・Ghostty設定値を追加表示)
	@VERBOSE=1 bash $(DOTFILES_DIR)scripts/doctor.sh

update: ## Homebrew と chezmoi のみ更新 (ランタイムは触らない)
	brew update && brew bundle --file=$(DOTFILES_DIR)brew/Brewfile
	chezmoi apply

runtime-upgrade: ## mise 管理のランタイムを更新 (Node/Python/Go 等)
	mise upgrade

clean: ## Homebrew・mise・uv・npm のキャッシュを掃除
	brew cleanup
	mise cache prune 2>/dev/null || true
	uv cache clean 2>/dev/null || true
	npm cache verify 2>/dev/null || true

help: ## このヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
