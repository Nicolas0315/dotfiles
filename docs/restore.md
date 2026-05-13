# Restore Notes

This repo uses file copies, not symlinks.

## Restore From An Apply Backup

`scripts/apply.sh --apply` writes backups under:

```sh
~/.dotfiles-apply-backups/<timestamp>/
```

Restore one file:

```sh
cp -a ~/.dotfiles-apply-backups/<timestamp>/.zshrc ~/.zshrc
```

Restore all managed files from a backup:

```sh
backup="$HOME/.dotfiles-apply-backups/<timestamp>"
cp -a "$backup/.zshrc" "$HOME/.zshrc"
cp -a "$backup/.paths" "$HOME/.paths"
cp -a "$backup/.exports" "$HOME/.exports"
cp -a "$backup/.functions" "$HOME/.functions"
cp -a "$backup/.aliases" "$HOME/.aliases"
cp -a "$backup/.tooling" "$HOME/.tooling"
cp -a "$backup/.tmux.conf" "$HOME/.tmux.conf"
cp -a "$backup/.config/ghostty/config" "$HOME/.config/ghostty/config"
cp -a "$backup/Library/Application Support/com.mitchellh.ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
cp -a "$backup/.config/zellij/layouts/ghostty-vscode.kdl" "$HOME/.config/zellij/layouts/ghostty-vscode.kdl"
```

## Restore From Repo

Dry-run first:

```sh
~/dotfiles/scripts/apply.sh
```

Apply:

```sh
~/dotfiles/scripts/apply.sh --apply
```

Then verify:

```sh
~/dotfiles/scripts/validate.sh
```
