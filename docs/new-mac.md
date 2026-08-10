# New Mac Setup

This is the canonical entrypoint for rebuilding a Katala OS Mac. Historical
migration audits under `~/work/docs/` are evidence, not competing setup guides.

## 1. Before the Mac arrives

- Confirm the latest dotfiles and companion-repo work is committed and available remotely.
- Keep credentials in 1Password. Do not copy auth databases, private keys,
  browser profiles, shell histories, caches, or agent sessions from another Mac.
- Have the Apple ID, GitHub account, 1Password account, and Tailscale account available.

## 2. First boot

Complete macOS Setup Assistant, install all offered stable updates, enable
FileVault, and install Xcode Command Line Tools:

```sh
xcode-select --install
```

## 3. Install packages

```sh
mkdir -p ~/work
git clone https://github.com/Nicolas0315/dotfiles.git ~/work/dotfiles
~/work/dotfiles/bootstrap.sh --check
~/work/dotfiles/bootstrap.sh --packages
```

The package phase can take a long time and can require macOS prompts. If Mac App
Store items fail, complete the manual account gates and rerun this phase.

## 4. Manual account gates

Perform these interactively; they are intentionally not automated:

```sh
gh auth login
tailscale up
```

- Open 1Password, sign in, then enable Settings > Developer > Integrate with 1Password CLI.
- Sign in to the Mac App Store and rerun `brew bundle --file=~/work/dotfiles/brew/Brewfile` if `mas` entries failed.
- Verify `op vault list`, `gh auth status`, and `tailscale status` without recording secret output.
- Create a machine-specific `~/.ssh/id_ed25519` key, add its public key to
  GitHub, and verify `ssh -T git@github.com`. The managed Git configuration uses
  `~/.ssh/id_ed25519.pub` for commit signing. Never copy another Mac's private key.

## 5. Companion repositories and apply

After GitHub authentication, clone the private/shared repositories needed by the
managed symlinks and agent instructions:

```sh
git clone git@github.com:Nicolas0315/katala-tooling.git ~/work/katala-tooling
git clone git@github.com:Nicolas0315/agent-context.git ~/work/agent-context
~/work/dotfiles/bootstrap.sh --apply
~/work/agent-context/scripts/bootstrap.sh
~/work/agent-context/scripts/verify-manifest.sh
```

Clone `agent-skills-private` only when private skill access is required. Follow
its own README and verifier; do not copy live skill directories from another Mac.
The apply phase refuses to create profile or tmux links until the required
`katala-tooling` files exist.

## 6. Acceptance checks

```sh
~/work/dotfiles/scripts/verify.sh
~/work/dotfiles/scripts/brew-check.sh
~/work/dotfiles/scripts/validate.sh
~/work/dotfiles/scripts/doctor.sh
chezmoi status
ls -l ~/AGENTS.md ~/CLAUDE.md ~/GEMINI.md
```

Ready means the repository verifier passes, `chezmoi status` is empty, the three
agent instruction files point to `~/work/agent-context/AGENTS.MD`, required CLIs
resolve in a new shell, and manual account gates work. Fleet enrollment, Remote
Login, launchd jobs, production credentials, and service startup remain separate
approval-sensitive tasks.

## 7. Recovery

Use [restore.md](restore.md). Dotfiles apply keeps the five newest pre-apply
archives under `~/.local/state/dotfiles-backups/bootstrap/` and prints the exact
restore command. The agent-context bootstrap separately keeps its five newest
replacement backups under `~/.local/state/agent-context-backups/bootstrap/`.
