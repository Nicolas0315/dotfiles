# Current State - 2026-05-29

Repo: `/Users/s30519/dotfiles`
Mode: private dotfiles repo under GitHub Flow.

## Current Local State

- Baseline branch: `main`
- Working branch: `codex/dotfiles-github-flow-20260529`
- Remote: `origin` -> `git@github.com:Nicolas0315/dotfiles.git`
- Visibility: private
- Dirty tracked files before the GitHub Flow capsule:
  - `app-support/com.mitchellh.ghostty/config`
  - `config/ghostty/config`
  - `home/.paths`
- Read-only checks completed:
  - `scripts/secret-scan.sh`: passed; only the expected 1Password lookup pattern was reported as allowed.
  - `scripts/verify.sh`: passed locally.
  - `scripts/validate.sh`: passed on the local Mac.
  - `git diff --check`: passed.

## Flow Policy

- Use feature branches and PRs for repo changes after a private remote is created.
- CI runs `scripts/verify.sh`, which avoids live Mac app dependencies.
- Local Mac behavior changes should also run `scripts/validate.sh`.
- `scripts/apply.sh --apply` is a separate user-approved live-home mutation gate.
