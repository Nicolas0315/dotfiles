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

## Test A Backup Without Overwriting Live Files

まずarchiveの一覧だけを確認し、秘密を含まない既知の設定ファイル1件を選びます。
復元先は作業用の別ディレクトリにし、archive全体をlive homeへ展開しません。
symlink・hardlink・絶対path・親ディレクトリ参照を含むmemberは避けます。

復元元memberのbytesと復元先のSHA-256一致、設定形式のparse成功、liveファイルのhashが変わっていないことを確認します。
設定1件の復元成功は、制作素材・アプリ認証・端末全体を復旧できる証明にはなりません。
Time Machine等の別媒体バックアップは保存先、最終成功日時、素材1件の復元結果を別に確認します。

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
