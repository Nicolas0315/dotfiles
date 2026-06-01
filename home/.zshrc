# Shared zsh entrypoint. Keep behavior in focused fragments.
for file in "$HOME/.paths" "$HOME/.exports" "$HOME/.functions" "$HOME/.aliases" "$HOME/.tooling"; do
  [ -f "$file" ] && source "$file"
done
unset file


# Added by Antigravity CLI installer
export PATH="/Users/s30519/.local/bin:$PATH"

# Google Cloud CLI
source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"

# OpenClaw source checkout shortcuts.
alias openclaw-repo="cd ~/work/nicolas-starred-repos/repos/openclaw_openclaw"
alias oc="cd ~/work/nicolas-starred-repos/repos/openclaw_openclaw && pnpm openclaw"
alias ocgw="cd ~/work/nicolas-starred-repos/repos/openclaw_openclaw && pnpm gateway:watch"

# Node LTS 最終保証: 全 source 完了後に v22 を先頭へ。brew/gcloud 等の後続 prepend を
# 上書きするため .zshrc 末尾に置く。.zprofile_local_minimal の guard は login-only shell 向け。
# LTS 更新時はここと .zprofile_local_minimal の 2 か所だけ変える。
() {
  local _lts="${NVM_DIR:-$HOME/.nvm}/versions/node/v22.22.2/bin"
  [[ -d "$_lts" ]] && export PATH="$_lts:$PATH"
}
typeset -U path PATH

# Cloudflare cf CLI completions.
typeset -U fpath
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit
# dump が 24h 以内なら検証を省いて即ロード(-C)、超過時のみフル再生成(-u で insecure dir 警告抑制)。
if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
  compinit -u
else
  compinit -C
fi
