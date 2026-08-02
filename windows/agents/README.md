# Windows AI-agent configuration

Portable, non-secret source for the Windows Codex and Claude Code agent
defaults used on the Katala OS workstation.

## Layout

- `codex/config.toml.example` — stable global defaults only. It intentionally
  excludes machine-specific MCP commands, project trust entries, hook trust
  hashes, temporary browser pipes, auth, and state databases.
- `codex/agents/*.toml` — the 26 custom Codex role definitions. These are
  portable role prompts and model/sandbox choices; they do not contain tokens
  or credentials.
- `claude/settings.json.example` — stable Claude Code model and UI defaults.
  User auth, MCP servers, hooks, plugin installation state, permission grants,
  and local project state stay on the machine.

The live files remain in `%USERPROFILE%\.codex` and `%USERPROFILE%\.claude`.
This directory is the reviewable source snapshot, not an automatic apply
mechanism. Review diffs and make a timestamped local backup before deploying
these files to another Windows node.

## Current policy

- Codex default: `gpt-5.6-terra` with medium reasoning and verbosity.
- Codex bounded roles keep their explicit model/effort pins; in particular,
  `luna-worker.toml` remains `gpt-5.6-luna` with `max` effort.
- Claude default: `opusplan` with high effort; planning uses Opus and normal
  execution uses Sonnet.
- Concurrency remains three spawned Codex threads per primary session.
- The portable Codex example records the trusted-development-machine
  approval/sandbox baseline; machine-specific permission state, MCP, hooks,
  plugins, histories, and credentials remain local.

## Validation

From PowerShell, parse every committed TOML and the Claude example before
deployment. The live machine should additionally run `codex --strict-config
doctor --summary`, `claude doctor`, and the repository's agent-team validator.

Do not commit `auth.json`, `.credentials.json`, `.mcp.json`, history/session
data, SQLite files, backups, `settings.local.json`, or generated runtime state.
