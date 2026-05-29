# Current State - 2026-05-29

Repo: `/Users/s30519/dotfiles`
Mode: private dotfiles repo under GitHub Flow.

## Current Local State

- Default branch: `main`
- Post-merge state before this docs-only follow-up: `main...origin/main` clean
- Remote: `origin` -> `git@github.com:Nicolas0315/dotfiles.git`
- Visibility: private
- Latest GitHub Flow PR: `https://github.com/Nicolas0315/dotfiles/pull/1`
- Latest merge commit: `4b40a09d754b143bdee97fd9bc22e76e1da48603`
- Dirty tracked files before the GitHub Flow capsule:
  - `app-support/com.mitchellh.ghostty/config`
  - `config/ghostty/config`
  - `home/.paths`
- Read-only checks completed:
  - `scripts/secret-scan.sh`: passed; only the expected 1Password lookup pattern was reported as allowed.
  - `scripts/verify.sh`: passed locally.
  - `scripts/validate.sh`: passed on the local Mac.
  - `git diff --check`: passed.
  - GitHub `Verify / verify`: passed on run `26613152905`.

## Flow Policy

- Use feature branches and PRs for repo changes after a private remote is created.
- CI runs `scripts/verify.sh`, which avoids live Mac app dependencies.
- Local Mac behavior changes should also run `scripts/validate.sh`.
- `scripts/apply.sh --apply` is a separate user-approved live-home mutation gate.
