# Katala OS Dotfiles

macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/), plus a full Homebrew/mas/VS Code/uv/npm tool inventory and a resumable bootstrap for setting up a new Mac.

Mac / Windowsの共通化方針と検証範囲は[開発環境の契約](docs/cross-platform.md)を参照してください。
mise・Homebrew・既存CLIの担当と重複の扱いは[環境の担当](docs/runtime-roles.md)を参照してください。

## New Mac Setup

Canonical checklist: [`docs/new-mac.md`](docs/new-mac.md). Run the read-only
preflight first:

```sh
~/work/dotfiles/bootstrap.sh --check
```

1. Install Xcode Command Line Tools (Homebrew's installer also triggers this):

   ```sh
   xcode-select --install
   ```

2. Clone this repo and run the bootstrap:

   ```sh
   git clone https://github.com/Nicolas0315/dotfiles.git ~/work/dotfiles
   ~/work/dotfiles/bootstrap.sh
   ```

   For a clean Mac, use `--packages`, complete the manual account gates and
   companion repositories, then use `--apply`. Running without an option runs
   both phases when prerequisites already exist. See the canonical checklist.

   `bootstrap.sh` runs four phases:

   | Phase | What it does |
   | --- | --- |
   | 1. Homebrew | Installs Homebrew if missing, then `brew bundle` against `brew/Brewfile` (taps, formulae, casks, mas apps, VS Code extensions, uv/npm/cargo tools) |
   | 2. Dotfiles | `chezmoi init --source ~/work/dotfiles` + `chezmoi apply` |
   | 3. Runtimes | `mise install` using `dot_config/mise/config.toml` |
   | 4. Doctor | `scripts/doctor.sh` health check |

3. Manual gates that bootstrap intentionally does not automate:

   - Sign in to 1Password; CLI secrets resolve via `op` at runtime (only item identifiers are committed).
   - `gh auth login` for GitHub.
   - Sign in to the Mac App Store before rerunning `brew bundle` if any `mas` app failed.
   - `tailscale up` if the machine joins a tailnet.
   - Clone companion repos referenced by the dotfiles (e.g. `~/.tmux.conf` is a symlink into `~/work/katala-tooling`).

## What Is Managed

chezmoi source state (applied into `$HOME`):

- `dot_zshrc`, `dot_zprofile` — zsh startup (aliases/prompt/PATH details live in the shared `profile.sh` inside `katala-tooling`)
- `dot_config/git/` — git config (template), hooks, ignore, allowed signers
- `dot_config/ghostty/config` — Ghostty terminal
- `dot_config/starship.toml` — prompt
- `dot_config/mise/config.toml` — pinned runtimes
- `symlink_dot_tmux.conf.tmpl` — `~/.tmux.conf` symlink into `katala-tooling`
- `dot_config/private_dev-env/` — shared shell profile shim
- `dot_config/nvim/` — Neovim config (`init.lua`) with `lazy-lock.json` pinning every plugin commit

Repo-only assets (never applied to `$HOME`, listed in `.chezmoiignore`):

- `brew/Brewfile` — full machine tool inventory (`brew bundle dump` snapshot)
- `tools/matrix.tsv` — cross-platform (Mac/Windows) tool parity matrix
- `windows/` — Windows parity kit (PowerShell profile, setup, dev-doctor)
- `scripts/`, `docs/`, `research/`

## リポジトリ管理（ghq）

- 既存の`~/work`配下は固定パス・worktree・symlinkを守るため移動しません。
- 今後の新規cloneは`ghq get owner/repo`を使い、既定の`~/ghq/<host>/<owner>/<repo>`へ置きます。
- `ghq list -p`はghq管理分だけを対象にします。`~/work`を追加rootにすると現行Macで列挙が約10秒かかったため採用しません。
- `ghq migrate`, `ghq rm`, `ghq get -u`は移動・削除・更新を伴うため自動実行しません。
- MacはBrewfile、Windowsは`tools/matrix.tsv`の公式winget packageで導入します。

公式仕様: [x-motemen/ghq](https://github.com/x-motemen/ghq#readme)

## Daily Workflow

```sh
chezmoi status               # source vs live drift
chezmoi diff                 # inspect before applying
chezmoi apply                # write source into $HOME (explicit gate)
chezmoi re-add ~/.zshrc      # snapshot a live edit back into the repo
make update                  # brew bundle + chezmoi apply
```

Verification:

```sh
./scripts/verify.sh          # portable CI gate: syntax, layout, path hygiene, secret scan
./scripts/validate.sh        # local Mac gate: live commands, startup time, Ghostty config
./scripts/brew-check.sh      # is the Brewfile satisfied? (read-only, --no-upgrade)
./scripts/secret-scan.sh     # standalone secret scan
./scripts/sync-editor-extensions.sh --check  # default local VS Code/Cursor store
```

Editor extensions are intentionally limited to the Japanese language pack and
Markdown Preview Enhanced. Apply the shared allowlist explicitly with
`scripts/sync-editor-extensions.sh --apply` on macOS or
`windows/sync-editor-extensions.ps1 -Apply` on Windows. Claude Code and Codex
IDE extensions remain opt-in because their CLI/desktop clients work without
editor extensions.

This only manages each editor's default local extension store. Independent
profiles and Remote SSH/WSL/container extension stores stay separate, and
Settings Sync is not changed. Before pruning, the script saves an `id@version`
manifest under `~/.local/state/editor-extension-backups`; reinstall those entries
to restore a previous set.

## Secret Handling

No raw tokens, SSH private keys, API keys, auth databases, or shell histories are committed — `scripts/secret-scan.sh` gates this and runs in CI via `scripts/verify.sh`.

Secrets resolve at runtime instead:

- 1Password CLI (`op`) lookups by item identifier (the identifier is committed, the value never is)
- Machine-local files that are never tracked: `~/.config/dev-env/secrets.local.sh`, `~/.functions.local`

## Shell Policy

- `mise` provides Node/Python/Go runtimes; Homebrew stays ahead of macOS defaults in `PATH`.
- Aliases, completion, and tool init live in the shared `profile.sh` (in `katala-tooling`), sourced from `dot_zshrc`; do not append aliases directly to `dot_zshrc`.
- `starship` renders the prompt; `atuin` owns Ctrl-R history; `zoxide` owns `cd` jumps.
- Ghostty renders the terminal; tmux (config in `katala-tooling`) owns persistence and remote panes.
- `EDITOR`/`VISUAL` default to `vim`.

## Layout Notes

- This repo is the chezmoi source directory (`chezmoi init --source ~/work/dotfiles`).
- Absolute home paths are forbidden in tracked files; templates use `{{ .chezmoi.homeDir }}`. `scripts/verify.sh` fails on violations.
- `docs/current-state.md` is the dated repo-state contract; `docs/restore.md` covers recovery paths.
