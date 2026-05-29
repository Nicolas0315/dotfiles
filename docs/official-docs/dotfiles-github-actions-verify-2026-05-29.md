# Official Docs Evidence - dotfiles GitHub Actions Verify - 2026-05-29

## Decision

Add a portable GitHub Actions verification workflow for the private dotfiles repo.

## Official Sources

- GitHub Actions workflow syntax: `https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax`
- GitHub Actions `permissions` syntax: `https://docs.github.com/ja/actions/writing-workflows/workflow-syntax-for-github-actions`
- `actions/checkout` latest release: `https://github.com/actions/checkout/releases/tag/v6.0.2`

Retrieved: 2026-05-29 JST.

## Local Config

- Workflow: `.github/workflows/verify.yml`
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
```

Result: all passed locally.

## Risk

- GitHub-hosted CI has not run until the first PR is created.
- `scripts/validate.sh` checks local Mac shell, Ghostty, and Zellij state and is intentionally not the portable CI gate.
- `scripts/apply.sh --apply` remains a separate explicit live-home mutation gate.

## Rollback

Use GitHub Flow rollback after publication: revert the PR commit or open a restoring PR against `main`.

No live dotfile apply was performed for this workflow change.

## Next Refresh

Refresh before changing workflow action versions or token permissions.
