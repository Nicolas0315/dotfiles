# Restore Notes

This repo is chezmoi-managed. `chezmoi apply` overwrites live files from the repo source; recovery paths are below.

## Inspect Before Applying

```sh
chezmoi status
chezmoi diff
chezmoi apply --dry-run --verbose
```

`bootstrap.sh --apply` creates a pre-apply archive under
`~/.local/state/dotfiles-backups/bootstrap/<timestamp>/` and retains the five
newest runs. It prints the exact restore command:

```sh
tar -xzf ~/.local/state/dotfiles-backups/bootstrap/<timestamp>/live-home-before-apply.tar.gz -C ~
```

## Restore A Live File From The Repo

```sh
chezmoi apply ~/.zshrc
```

## Restore The Repo Source From Live Files

If a repo-side edit was wrong and the live file is correct:

```sh
chezmoi re-add ~/.zshrc
```

## Restore From Git History

Every managed file is versioned. To recover any earlier state:

```sh
git -C ~/work/dotfiles log --oneline -- dot_zshrc
git -C ~/work/dotfiles checkout <commit> -- dot_zshrc
chezmoi apply ~/.zshrc
```

Then verify:

```sh
~/work/dotfiles/scripts/validate.sh
```
