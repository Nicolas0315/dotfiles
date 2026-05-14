# AI Agent Tool Candidates

Last reviewed: 2026-05-14

Scope: public GitHub repositories cloned locally for read-only review. Nothing
from this list is installed into shell startup, Brewfile, Codex, Claude, Gemini,
MCP config, or global npm/pip/uv state yet.

## Local Workspaces

Research-only references:

| Repo | Local path | Commit | Role |
| --- | --- | --- | --- |
| `ComposioHQ/awesome-codex-skills` | `~/workspace/research/awesome-codex-skills` | `c63e9dd` | Codex skill examples and skill design reference |
| `FlorianBruniaux/claude-code-ultimate-guide` | `~/workspace/research/claude-code-ultimate-guide` | `91374e1` | Claude Code operations, security, MCP, workflow reference |
| `anthropics/claude-plugins-official` | `~/workspace/research/claude-plugins-official` | `1a2f18b` | Claude plugin directory and trust model reference |

PoC candidates:

| Repo | Local path | Commit | Primary stack | License signal | Role |
| --- | --- | --- | --- | --- | --- |
| `mksglu/context-mode` | `~/workspace/experiments/context-mode` | `17587f6` | Node/TypeScript MCP/plugin | Elastic License 2.0 | Context isolation, MCP tool-output routing, context savings |
| `safishamsi/graphify` | `~/workspace/experiments/graphify` | `77bb10c` | Python/uv | MIT | Queryable repo/docs knowledge graph |
| `brunoborges/ghx` | `~/workspace/experiments/ghx` | `0bc3899` | Go | MIT | Cached `gh` proxy for high-volume GitHub agent workflows |
| `ie3jp/illustrator-mcp-server` | `~/workspace/experiments/illustrator-mcp-server` | `26a8d70` | Node/TypeScript MCP | MIT | Adobe Illustrator automation via MCP |

## PoC First

### `mksglu/context-mode`

Why it fits:

- Targets Claude Code, Gemini CLI, OpenCode, and Codex CLI style workflows.
- Provides MCP tools and hook-based routing for large tool output.
- Relevant to long-running audit sessions where raw command output can flood
  context.

Adoption blockers:

- License is Elastic License 2.0, not MIT/Apache.
- Installs hooks/plugins into agent runtimes, so it changes behavior rather than
  being a passive CLI.
- Uses `postinstall` and plugin installation paths; inspect before any global
  `npm install -g context-mode`.

Safe next check:

```sh
cd ~/workspace/experiments/context-mode
rg -n "postinstall|hook|mcp|codex|claude|gemini|opencode" README.md package.json scripts src
npm view context-mode version license
```

PoC gate:

- Run only in a disposable project first.
- Prefer MCP-only mode before hook-enabled mode.
- Do not enable global hooks until `ctx doctor` and rollback steps are known.

### `safishamsi/graphify`

Why it fits:

- Intended to turn code/docs/folders into a queryable graph for coding agents.
- Has explicit Codex, Claude Code, OpenCode, Gemini, and other platform install
  paths.
- `~/dotfiles` is a good first target because it is small and already validated.

Adoption blockers:

- Optional extras can pull in many heavy dependencies: MCP, Neo4j, PDF, Office,
  video/audio, OpenAI/Gemini/Bedrock, SQL, and graph community detection.
- README suggests platform install commands that modify agent config.
- LLM-backed extraction can use external API keys unless constrained to local or
  non-LLM modes.

Safe next check:

```sh
cd ~/workspace/experiments/graphify
uvx --from graphifyy graphify --help
rg -n "backend|ollama|openai|gemini|neo4j|install --platform|multi_agent" README.md graphify
```

PoC gate:

- Use `~/dotfiles` as the first input.
- Prefer a local/no-network backend if available.
- Do not run `graphify install --platform codex` until the exact file writes are
  known.

### `brunoborges/ghx`

Why it fits:

- Designed for repeated GitHub CLI calls in agent workflows.
- Could help if future GitHub Stars or issue/PR analysis starts hitting rate or
  repeated-call limits.

Adoption blockers:

- It is a wrapper/proxy around GitHub CLI behavior, so auth/cache semantics need
  review.
- It can auto-download `gh` if missing; this environment already has Homebrew
  `gh`, so that path should be avoided.

Safe next check:

```sh
cd ~/workspace/experiments/ghx
rg -n "cache|daemon|token|GITHUB|GH_TOKEN|install|brew|agent" README.md DOCS.md go.mod internal
go test ./...
```

PoC gate:

- Run only against public GitHub API calls first.
- Confirm cache directory and token handling before using with authenticated
  private repos.

### `ie3jp/illustrator-mcp-server`

Why it fits:

- Useful if Illustrator automation becomes a real workflow.
- MIT licensed and MCP-compatible.

Adoption blockers:

- Controls a GUI design app and can create/export/modify documents.
- Uses `npx illustrator-mcp-server` or Claude MCP config, so installation is an
  externally visible capability change.
- Requires Adobe Illustrator availability and a clear safety boundary.

Safe next check:

```sh
cd ~/workspace/experiments/illustrator-mcp-server
rg -n "tools|export|write|delete|mcp|claude mcp add|npx|Illustrator" README.md package.json src
npm test
```

PoC gate:

- Only use with a throwaway Illustrator document.
- Confirm command set and write/export behavior before connecting to Claude
  Desktop or Claude Code.

## Reference Only

### `ComposioHQ/awesome-codex-skills`

Use as a skill-design catalog, not an install target. Interesting local skill
ideas for this workstation:

- `dotfiles-validate`
- `brewfile-gate`
- `ghostty-config-review`
- `zellij-layout-review`
- `cli-agent-stack-check`
- `secret-scan-before-commit`

Do not bulk-install skills from this repo. Select individual skills only after
reading their `SKILL.md`, scripts, network behavior, and credential handling.

### `FlorianBruniaux/claude-code-ultimate-guide`

Use as a Claude Code operations and security reference. Strongest areas to mine:

- MCP vetting checklist
- production safety / prompt injection notes
- context and compaction guidance
- commands/hooks examples that can be adapted into local, private scripts

Do not install its MCP server or copy hooks globally until reviewed. The guide
itself warns that MCP/plugin trust must be treated as a security boundary.

### `anthropics/claude-plugins-official`

Use as a directory and trust model reference. The README explicitly frames
plugins as items that must be trusted before install/update/use. Treat every
plugin as an apply gate, not a passive doc.

## Do Not Auto-Install

Do not add these classes to Brewfile, shell startup, MCP config, or global agent
runtime without a separate approval gate:

- hacking / offensive security toolkits
- OSINT tools that can enumerate people or accounts
- unofficial "free" access wrappers for paid AI tools
- finance / trading automation
- remote-control tools for Codex or Claude
- MCP servers that can write to third-party accounts or GUI apps

## Initial Review Notes

- All seven cloned repos had clean git worktrees after clone.
- Combined local checkout size is modest: the largest clone is
  `claude-code-ultimate-guide` at about 45 MiB.
- A broad secret-pattern scan found examples, placeholders, tests, and docs
  containing API-key and GitHub-token placeholder text plus redaction tests. No
  private key material was observed in this pass.
- `context-mode` is the highest-leverage candidate, but also the one most likely
  to alter agent behavior via hooks.
- `graphify` is the best match for codebase/dotfiles structure exploration, but
  its optional dependency surface is broad.
- `ghx` is only worth adopting if GitHub API/CLI volume becomes a bottleneck.
- `illustrator-mcp-server` belongs in a creative-app experiment gate, not the
  base workstation stack.

## Next Safe Commands

Read-only/low-risk:

```sh
cd ~/workspace/experiments/context-mode && npm view context-mode version license
cd ~/workspace/experiments/graphify && uvx --from graphifyy graphify --help
cd ~/workspace/experiments/ghx && go test ./...
cd ~/workspace/experiments/illustrator-mcp-server && npm test
```

Do not run install/config commands yet:

```sh
npm install -g context-mode
graphify install --platform codex
brew install ghx
claude mcp add illustrator-mcp -- npx illustrator-mcp-server
/plugin install context-mode@context-mode
```
