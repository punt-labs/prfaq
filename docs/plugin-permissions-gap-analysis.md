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
- Syntax: `Bash(cmd:*)` for commands, `Edit(path)` / `Write(path)` for files

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
| **File writes** | `Write(*prfaq*.tex)`, `Write(meetings/**)` | `Write(.tts/**)` for config |
| **File edits** | `Edit(*prfaq*.tex)`, `Edit(README.md)` | — |
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

---

## Proposed Standard: Plugin-Distributed Permissions

### Principles

1. **Least privilege.** Only auto-allow operations the plugin performs
   autonomously. Operations that are risky, rare, or destructive stay at the
   prompt tier.

2. **Pattern specificity.** Permission patterns must be narrow enough that they
   don't grant access to unrelated files. Use the plugin name or domain-specific
   identifiers in patterns (e.g., `*prfaq*.tex` not `*.tex`).

3. **Idempotent injection.** Running the installer twice must not create
   duplicate rules or reorder existing user permissions.

4. **Order preservation.** New rules append to the existing allow list. The
   user's existing permission order is preserved.

5. **Clean uninstall.** Every rule the installer adds must be removable by
   the uninstaller. Track injected rules so cleanup is precise.

### What to Auto-Allow

| Category | Auto-allow when... | Example |
|----------|-------------------|---------|
| Bash (build tools) | The command is deterministic and non-destructive | `Bash(bash */compile_prfaq.sh *)` |
| Bash (scaffolding) | Creates empty directories only | `Bash(mkdir -p meetings)` |
| Bash (utilities) | Deterministic, no side effects | `Bash(uuidgen)` |
| Write (plugin output) | File pattern contains plugin name or is plugin-owned | `Write(*prfaq*.tex)` |
| Write (plugin config) | Plugin's own config files | `Write(.claude/prfaq.local.md)` |
| Edit (plugin output) | Same as Write — pattern contains plugin name | `Edit(*prfaq*.tex)` |
| WebSearch | Plugin performs research as core functionality | `WebSearch` |
| WebFetch | Plugin fetches from any domain as core functionality | `WebFetch` |
| MCP tools | Plugin's own MCP server tools | `mcp__plugin_<name>_<server>__*` |

### What to NOT Auto-Allow

| Category | Rationale |
|----------|-----------|
| `Bash(curl *)` | Network POST to external endpoints. Even benign uses (telemetry) should require explicit approval. |
| `Bash(rm *)` | File deletion. Users should see and approve every delete. |
| `Write(*)` / `Edit(*)` (broad) | Patterns that match files outside the plugin's domain. |
| Bash commands with side effects | Package installs, process kills, system configuration. |

### Implementation Pattern

#### Installer (install.sh)

Define rules as a JSON array. Use `jq` for atomic, order-preserving merge.
Fall back to manual instructions when `jq` is unavailable.

```sh
PLUGIN_RULES='[
  "Bash(bash */compile_prfaq.sh *)",
  "Write(*prfaq*.tex)",
  "Edit(*prfaq*.tex)"
]'

SETTINGS_FILE="$HOME/.claude/settings.json"

if command -v jq >/dev/null 2>&1; then
  # Validate existing file
  if [ ! -f "$SETTINGS_FILE" ]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    printf '{}' > "$SETTINGS_FILE"
  elif ! jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak" 2>/dev/null || true
    printf '{}' > "$SETTINGS_FILE"
  fi

  # Count new rules, then merge (order-preserving)
  ADDED=$(jq -r --argjson new "$PLUGIN_RULES" '
    (.permissions.allow // []) as $orig
    | [$new[] | select(. as $r | $orig | index($r) | not)] | length
  ' "$SETTINGS_FILE")

  jq --argjson new "$PLUGIN_RULES" '
    (.permissions.allow // []) as $orig
    | .permissions.allow = $orig + [$new[] | select(. as $r | $orig | index($r) | not)]
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
else
  # Manual fallback
  info "Add these rules to $SETTINGS_FILE under permissions.allow:"
  printf '%s\n' "$PLUGIN_RULES"
fi
```

#### Uninstaller

Remove only the rules the plugin added. Preserve everything else.

```sh
jq --argjson remove "$PLUGIN_RULES" '
  .permissions.allow = [.permissions.allow[] | select(. as $r | $remove | index($r) | not)]
' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
```

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
| Installer permission injection | Implemented (PR #22) |
| `allowed-tools` frontmatter | Implemented (PR #22) |
| Uninstaller cleanup | Not implemented |

### tts

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | Covered (SessionStart hook) |
| Installer permission injection | **Missing** — no non-MCP permissions injected |
| `allowed-tools` frontmatter | **Missing** — no commands declare allowed-tools |
| Uninstaller cleanup | Partial (MCP tools only) |

### biff

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | Covered (SessionStart hook) |
| Installer permission injection | Not assessed |
| `allowed-tools` frontmatter | Not assessed |
| Uninstaller cleanup | Not assessed |

### quarry

| Aspect | Status |
|--------|--------|
| MCP tool wildcards | Covered (SessionStart hook) |
| Installer permission injection | Not assessed |
| `allowed-tools` frontmatter | Not assessed |
| Uninstaller cleanup | Not assessed |

---

## Recommended Changes to punt-kit Standards

### permissions.md

Add a new section **"6. Plugin-Distributed Permissions"** (renumber existing
section 6 to 7) covering:

- What rules a plugin installer should inject into `~/.claude/settings.json`
- The auto-allow / never-allow categorization
- Pattern specificity requirements (must contain plugin name or domain term)
- The jq merge pattern (order-preserving, idempotent)

### plugins.md

Expand the SessionStart hook section to cover non-MCP permissions, or add a
new section **"Plugin Installer Permissions"** that:

- Requires every installer to include a permission injection step
- Requires every uninstaller to clean up injected permissions
- Lists the jq implementation pattern
- Requires `allowed-tools` frontmatter on all commands and skills

### distribution.md

Update the uninstall requirements table to explicitly list:

| Artifact | Created by | Cleaned up by |
|----------|-----------|---------------|
| Non-MCP permission entries | Installer Step N | Project `uninstall` |

### workflow.md

Update section 7 "Code Review Flow" step 3 to replace vague "wait for
feedback" with concrete commands (same issue prfaq CLAUDE.md had):

```bash
gh pr checks <number> --watch   # Background: blocks until all checks resolve
gh pr view <number> --comments  # Read Copilot feedback
```
