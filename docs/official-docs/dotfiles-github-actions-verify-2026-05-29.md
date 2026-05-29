# Official Docs Evidence - dotfiles GitHub Actions Verify - 2026-05-29

## Decision

Add a portable GitHub Actions verification workflow for the private dotfiles repo and verify it through GitHub Flow.

## Official Sources

- GitHub Actions workflow syntax: `https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax`
- GitHub Actions `permissions` syntax: `https://docs.github.com/ja/actions/writing-workflows/workflow-syntax-for-github-actions`
- `actions/checkout` latest release: `https://github.com/actions/checkout/releases/tag/v6.0.2`

Retrieved: 2026-05-29 JST.

## Local Config

- Workflow: `.github/workflows/verify.yml`
- Repo: `https://github.com/Nicolas0315/dotfiles`
- Visibility: private
- Checkout action: `actions/checkout@v6`
- Token scope: `permissions: contents: read`
- Checkout credential persistence: `persist-credentials: false`
- CI command: `./scripts/verify.sh`

## Verification

```sh
rtk gh api repos/actions/checkout/releases/latest --jq '{tag_name, published_at, html_url}'
rtk scripts/secret-scan.sh
rtk scripts/verify.sh
rtk scripts/validate.sh
rtk ruby -e "require 'yaml'; YAML.load_file('.github/workflows/verify.yml'); puts 'yaml ok'"
rtk git diff --check
rtk gh pr checks 1 --repo Nicolas0315/dotfiles --json name,state,bucket,workflow,link,startedAt,completedAt
```

Result: all passed locally.

GitHub result:

- PR: `https://github.com/Nicolas0315/dotfiles/pull/1`
- Merge commit: `4b40a09d754b143bdee97fd9bc22e76e1da48603`
- CI: `Verify / verify` succeeded on run `26613152905`
- Local post-merge state: clean on `main...origin/main`

## Risk

- `scripts/validate.sh` checks local Mac shell, Ghostty, and Zellij state and is intentionally not the portable CI gate.
- `scripts/apply.sh --apply` remains a separate explicit live-home mutation gate.
- Live dotfiles were not applied; `scripts/diff-live.sh` still reports live-vs-repo drift.

## Rollback

Use GitHub Flow rollback: revert PR `#1` or open a restoring PR against `main`.

No live dotfile apply was performed for this workflow change.

## Next Refresh

Refresh before changing workflow action versions or token permissions.
