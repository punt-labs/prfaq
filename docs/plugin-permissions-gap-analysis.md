# Plugin Permissions: Gap Analysis

Comparison of what punt-labs plugin products **need** vs what the existing
punt-kit standards **define**.

---

## Existing Standards Coverage

### permissions.md — Per-Project Settings

Covers permissions in `.claude/settings.json` **checked into each project
repo**. Well-defined:

- Three-tier model (allow / prompt / deny)
- File split: `settings.json` (portable) vs `settings.local.json` (local paths)
- Required MCP wildcards, build tools, skills, WebFetch domains, deny rules
- Syntax: `Bash(cmd:*)` for commands, `Edit(path)` for files

**Correction (2026-08-13)**: `Write(path)` is not a working rule form. Claude
Code matches path-scoped rules under `Edit(path)` only, and that one form
covers the Write, Edit, and NotebookEdit tools. A `Write(path)` rule matches
nothing and produces a startup warning:

> Permission allow rule (...): `Write(*prfaq*.tex)` is not matched by file
> permission checks — only `Edit(path)` rules are. Use `Edit(*prfaq*.tex)`
> instead (Edit rules cover all file-editing tools).

Any standard that lists `Write(path)` as valid syntax needs the same fix.

**Scope**: What Claude can do when working **inside** a project directory.

### plugins.md — SessionStart Hook

Covers one specific permission pattern:

> Auto-allow MCP tool permissions — Add the plugin's tool pattern (e.g.,
> `mcp__plugin_biff_tty__*`) to `permissions.allow` in
> `~/.claude/settings.json` via jq.

Also mentions `allowed-tools` frontmatter in one sentence:

> Commands that invoke external tools should declare `allowed-tools` in their
> frontmatter to restrict what Claude can execute.

**Scope**: MCP tool wildcards only. No guidance for non-MCP permissions.

### distribution.md — Uninstall Cleanup

States that uninstall must clean up permission entries:

> | Permission entries in `~/.claude/settings.json` | SessionStart hook |
> Project `uninstall` |

**Scope**: Cleanup obligation, but never defines what was installed.

---

## The Gap

None of the three standards cover **plugin-distributed permissions**: the
Write, Edit, Bash, WebSearch, and WebFetch rules that plugins need to operate
without constant prompts when installed in **any** project.

### What Plugins Actually Need

When a plugin is installed in an arbitrary project (not the plugin's own repo),
it needs permissions for operations its commands and skills perform:

| Category | Example (prfaq) | Example (tts) |
|----------|-----------------|---------------|
| **Bash commands** | `bash */compile_prfaq.sh *`, `uuidgen`, `mkdir -p meetings` | hook scripts that invoke `tts` CLI |
| **File writes and edits** | `Edit(*prfaq*.tex)`, `Edit(meetings/**)`, `Edit(README.md)` | `Edit(.tts/**)` for config |
| **Web access** | `WebSearch`, `WebFetch` (researcher agent) | — |
| **MCP tools** | — (no MCP server) | `mcp__plugin_tts_vox__*` (covered by existing standard) |

MCP tools are the only category with an existing standard. Everything else
falls through to the prompt tier — users approve every operation manually.

### Where Permissions Live

| Layer | What it covers | Standard exists? |
|-------|---------------|-----------------|
| Project `.claude/settings.json` | Developer working in the project | Yes (`permissions.md`) |
| User `~/.claude/settings.json` | Plugin operating in any project | **Partial** (MCP only via `plugins.md`) |
| Command `allowed-tools` frontmatter | Tool restrictions per command | **Mentioned** but not required |

The middle layer — user-level permissions injected by the installer — has no
standard.

**Correction (2026-08-13)**: it has no standard because it should not exist
for non-MCP rules. prfaq shipped installer-injected global rules in v1.5.0 and
carried them to v1.6.1; the result was a plugin granting itself standing
permission to edit `README.md` and `.gitignore` and to reach the web in every
project the user ever opened, prfaq-related or not. A user hit it in an
unrelated repo — eight warnings per session, from a plugin that repo does not
use.

The layer that fits the need is the one that already has a standard: the
project's own `.claude/settings.json`, written on request by a plugin command
rather than by the installer. The user decides which projects prfaq operates
in, the rules are visible in the project's git history, and removing the
plugin cannot leave debris in a file it should never have touched.

MCP tool wildcards remain the exception. An MCP server is process-global and
its tool names are namespaced to the plugin (`mcp__plugin_<name>_<server>__*`),
so a global allow entry grants nothing outside the plugin's own tools. That is
why `plugins.md` is right to keep them in `~/.claude/settings.json`.

---

## Proposed Standard: Plugin-Distributed Permissions

### Principles

1. **Project scope, never global.** Non-MCP rules go in the project's
   `.claude/settings.json`. A plugin has no business granting itself standing
   permission in projects the user never pointed it at. MCP tool wildcards are
   the sole exception, for the reason given above.

2. **The user asks for it.** The installer installs; it does not grant. Rules
   land when the user runs the plugin's own permissions command inside a
   project. Installing a plugin is not consent to edit files in every repo on
   the machine.

3. **Least privilege.** Only allow operations the plugin performs
   autonomously. Operations that are risky, rare, or destructive stay at the
   prompt tier.

4. **Pattern specificity.** Permission patterns must be narrow enough that they
   don't grant access to unrelated files. Use the plugin name or domain-specific
   identifiers in patterns (e.g., `*prfaq*.tex` not `*.tex`).

5. **`Edit(path)` for every path rule.** `Write(path)` matches nothing and
   warns at every session start. One `Edit(...)` rule covers Write, Edit, and
   NotebookEdit.

6. **Idempotent.** Running the command twice must not create duplicate rules,
   reorder existing user permissions, or rewrite the file at all when there is
   nothing to add. A no-op that dirties the user's git status is not a no-op.

7. **Order preservation.** New rules append to the existing allow list. The
   user's existing permission order is preserved.

8. **Reversible.** Every rule the plugin adds must be removable by the plugin,
   and the file must be backed up before it changes. This includes rules
   earlier versions added to places the plugin no longer writes — an upgrade
   is responsible for cleaning up what its predecessors left behind.

### What to Auto-Allow

| Category | Auto-allow when... | Example |
|----------|-------------------|---------|
| Bash (build tools) | The command is deterministic and non-destructive | `Bash(bash */compile_prfaq.sh *)` |
| Bash (scaffolding) | Creates empty directories only | `Bash(mkdir -p meetings)` |
| Bash (utilities) | Deterministic, no side effects | `Bash(uuidgen)` |
| Edit (plugin output) | File pattern contains plugin name or is plugin-owned | `Edit(*prfaq*.tex)` |
| Edit (plugin config) | Plugin's own config files | `Edit(.claude/prfaq.local.md)` |
| WebSearch | Plugin performs research as core functionality | `WebSearch` |
| WebFetch | Plugin fetches from any domain as core functionality | `WebFetch` |
| MCP tools | Plugin's own MCP server tools | `mcp__plugin_<name>_<server>__*` |

There is no separate Write row. `Edit(pattern)` is the only path-scoped form
and it already covers the Write tool.

### What to NOT Auto-Allow

| Category | Rationale |
|----------|-----------|
| `Bash(curl *)` | Network POST to external endpoints. Even benign uses (telemetry) should require explicit approval. |
| `Bash(rm *)` | File deletion. Users should see and approve every delete. |
| `Edit(*)` (broad) | Patterns that match files outside the plugin's domain. |
| `Write(anything)` | Not a working form. Use `Edit(...)`. |
| Anything in `~/.claude/settings.json` except MCP wildcards | Applies in every project the user opens. |
| Bash commands with side effects | Package installs, process kills, system configuration. |

### Implementation Pattern

#### Permissions command (`/<plugin>:permissions`)

The plugin ships one script, invoked by one command, operating on one file:
`<project>/.claude/settings.json`. It supports `--add`, `--check`, and
`--remove`, refuses to write when the target resolves to `$HOME`, backs up
before changing anything, and exits without touching the file when there is
nothing to do.

prfaq's implementation is `plugin/scripts/prfaq_permissions.sh`, reachable from
the command as `${CLAUDE_PLUGIN_ROOT}/scripts/prfaq_permissions.sh`. The merge is
the same order-preserving jq expression used before, pointed at the project
file instead of the global one:

```sh
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"

[ "$PROJECT_DIR" = "$HOME" ] && fail "Refusing to write the global settings file."

jq --argjson rules "$PLUGIN_RULES" '
  (.permissions.allow // []) as $have
  | .permissions.allow = $have + [$rules[] | select(. as $r | $have | index($r) | not)]
' "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
```

#### Installer (install.sh)

Installs the plugin. Grants nothing. Its only permission-related job is
removing rules earlier versions of the same plugin injected globally:

```sh
# Frozen historical list — every rule the plugin ever wrote to the global file.
# Never add to it.
LEGACY_GLOBAL_RULES='[ ... ]'

FOUND=$(jq -r --argjson legacy "$LEGACY_GLOBAL_RULES" '
  [(.permissions.allow // [])[] | select(. as $r | $legacy | index($r))] | length
' "$SETTINGS_FILE")

if [ "$FOUND" -gt 0 ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.prfaq-backup.$(date +%Y%m%d%H%M%S)"
  jq --argjson legacy "$LEGACY_GLOBAL_RULES" '
    .permissions.allow = [(.permissions.allow // [])[] | select(. as $r | $legacy | index($r) | not)]
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  # then print every removed rule, so a user who authored an overlapping
  # generic rule (WebSearch, Edit(README.md)) can restore it from the backup
fi
```

Print what was removed. Cleanup cannot distinguish a rule the plugin injected
from an identical rule the user wrote by hand, so the backup and the printed
list are what make the operation safe.

#### Command Frontmatter (allowed-tools)

Every command and skill must declare `allowed-tools` in YAML frontmatter.
Currently bugged (Claude Code issues #14956, #18837) but serves as
documentation and will activate when fixed.

```yaml
---
description: Run a simulated review meeting
allowed-tools: Bash(mkdir -p meetings), Read, Write, Glob, Grep
---
```

---

## Current State by Plugin

### prfaq

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | N/A (no MCP server) |
| Global installer injection | **Removed in v1.7.0.** Shipped in v1.5.0 (PR #22), carried to v1.6.1 |
| Project permissions command | `/prfaq:permissions` (v1.7.0) |
| Path rules use `Edit(...)` | Yes (v1.7.0). v1.5.0–1.6.1 shipped 8 dead `Write(...)` rules |
| Legacy global cleanup | Implemented — installer removes all 24 legacy rules, with backup |
| `allowed-tools` frontmatter | Implemented (PR #22) |

### tts

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | Covered (SessionStart hook) |
| Global installer injection | None — correct as-is |
| Project permissions command | **Missing** — no way to grant `Edit(.tts/**)` without hand-editing |
| `allowed-tools` frontmatter | **Missing** — no commands declare allowed-tools |
| Legacy global cleanup | N/A (nothing injected) |

### biff

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | Covered (SessionStart hook) |
| Global installer injection | Not assessed — **audit for `Write(...)` and non-MCP rules** |
| Project permissions command | Not assessed |
| `allowed-tools` frontmatter | Not assessed |
| Legacy global cleanup | Not assessed |

### quarry

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | Covered (SessionStart hook) |
| Global installer injection | Not assessed — **audit for `Write(...)` and non-MCP rules** |
| Project permissions command | Not assessed |
| `allowed-tools` frontmatter | Not assessed |
| Legacy global cleanup | Not assessed |

Every plugin with an installer needs the same audit prfaq just went through:
`grep -n '"Write(' install.sh` and `grep -n 'HOME/.claude/settings.json'
install.sh`. Any hit outside an MCP wildcard is the same bug.

---

## Recommended Changes to punt-kit Standards

### permissions.md

Two changes:

1. **Fix the syntax line.** It lists `Edit(path)` / `Write(path)` as
   equivalent file forms. `Write(path)` matches nothing and warns at every
   session start. Only `Edit(path)` is valid, and it covers Write, Edit, and
   NotebookEdit.

2. Add a new section **"6. Plugin-Distributed Permissions"** (renumber existing
   section 6 to 7) covering:

   - That non-MCP plugin rules belong in the project's `.claude/settings.json`,
     never in `~/.claude/settings.json`, and why MCP wildcards are the exception
   - That the user grants them by running the plugin's permissions command in a
     project — installers install, they do not grant
   - The auto-allow / never-allow categorization
   - Pattern specificity requirements (must contain plugin name or domain term)
   - The jq merge pattern (order-preserving, idempotent, no-op writes nothing)

### plugins.md

Expand the SessionStart hook section to cover non-MCP permissions, or add a
new section **"Plugin Permissions"** that:

- Forbids installers from writing non-MCP rules to the global settings file
- Requires every plugin needing permissions to ship a `permissions` command
  with `--add`, `--check`, and `--remove` behavior, scoped to one project
- Requires an installer that previously injected global rules to remove them
  on upgrade, backing up the file and printing every rule removed
- Lists the jq implementation pattern
- Requires `allowed-tools` frontmatter on all commands and skills

### distribution.md

Update the uninstall requirements table to explicitly list:

| Artifact | Created by | Cleaned up by |
|----------|-----------|---------------|
| Project permission entries | `/<plugin>:permissions` | `/<plugin>:permissions remove` |
| Legacy global permission entries | Installers before the project-scoped rule | Installer, on upgrade |

### workflow.md

Update section 7 "Code Review Flow" step 3 to replace vague "wait for
feedback" with concrete commands (same issue prfaq CLAUDE.md had):

```bash
gh pr checks <number> --watch   # Background: blocks until all checks resolve
gh pr view <number> --comments  # Read Copilot feedback
```
