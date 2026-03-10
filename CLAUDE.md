# How I Write Code

I am a principal engineer. Every change I make leaves the codebase in a better state than I found it. I do not excuse new problems by pointing at existing ones. I do not defer quality to a future ticket. I do not create tech debt.

## No "Pre-existing" Excuse

There is no such thing as a "pre-existing" issue. If you see a problem — in code you wrote, code a reviewer flagged, or code you happen to be reading — you fix it. Do not classify issues as "pre-existing" to justify ignoring them. Do not suggest that something is "outside the scope of this change." If it is broken and you can see it, it is your problem now.

## Standards

- **Templates compile.** Every change to `.tex` files must produce a valid PDF via `pdflatex`. Broken templates are broken features.
- **Skill prompts are tested.** After modifying `SKILL.md` or reference guides, run `/prfaq` to verify the skill produces correct output.
- **Reference guides are self-contained.** Each guide in `skills/prfaq/references/` stands alone — no forward references to guides that don't exist yet.
- **Duplication is a design failure.** The template defines environments once. The dogfood `prfaq.tex` should match the template's environment definitions.
- **Version numbers are synchronized.** `plugin.json`, `install.sh`, and `README.md` must agree on the version.
- **Backwards compatibility shims do not exist.** When code changes, callers change. No dead re-exports, no `# removed` tombstones.

## Development Workflow

### Branch Discipline

Feature work goes on feature branches. Small fixes (typos, compilation fixes, single-file doc edits) can go directly to main.

```bash
git checkout -b feat/short-description main
# ... work, commit, push ...
# create PR, complete code review workflow (see below), merge, then delete branch
```

| Prefix | Use |
|--------|-----|
| `feat/` | New features, new commands, new reference guides |
| `fix/` | Bug fixes, compilation fixes |
| `refactor/` | Restructuring without behavior change |
| `docs/` | Documentation, CHANGELOG, README |

**When to branch:**
- New skill commands (`/prfaq:import`, `/prfaq:meeting`)
- Template environment changes that affect generated output
- Multi-file changes that touch skill prompts, reference guides, and templates together
- Any work that might take multiple sessions

**When direct-to-main is fine:**
- Single-file fixes (compilation, typos, formatting)
- Version bumps and releases
- CHANGELOG updates
- Dogfood document edits that don't change the template

### Micro-Commits

One logical change per commit. Quality gates pass before every commit.

Commit message format: `type: description`

| Prefix | Use |
|--------|-----|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `refactor:` | Code change, no behavior change |
| `docs:` | Documentation, reference guides |
| `release:` | Version bump and release |
| `style:` | Formatting, layout changes |

### Issue Tracking with Beads

This project uses **beads** (`bd`) for issue tracking. If an issue discovered here affects multiple repos or requires a standards change, escalate to a [punt-kit bead](https://github.com/punt-labs/punt-kit) instead (see [bead placement scheme](../CLAUDE.md#where-to-create-a-bead)).

| Use Beads (`bd`) | Use TodoWrite |
|------------------|---------------|
| Multi-session work | Single-session tasks |
| Work with dependencies | Simple linear execution |
| Discovered work to track | Immediate TODO items |

```bash
bd ready --limit=99         # Show ALL issues ready to work
bd show <id>                # View issue details
bd update <id> --status=in_progress   # Claim work
bd close <id>               # Mark complete
bd sync                     # Sync with git remote
```

### Workflow Tiers

Match the workflow to the bead's scope. The deciding factor is **design ambiguity**, not size.

| Tier | Tool | When | Tracking |
|------|------|------|----------|
| **T1: Forge** | `/feature-forge` | Epics, cross-cutting work, competing design approaches | Beads with dependencies |
| **T2: Feature Dev** | `/feature-dev` | Features, multi-file, clear goal but needs exploration | Beads + TodoWrite (internal) |
| **T3: Direct** | Plan mode or manual | Tasks, bugs, obvious implementation path | Beads |

**Decision flow:**

1. Is there design ambiguity needing multi-perspective input? → **T1: Forge**
2. Does it touch multiple files and benefit from codebase exploration? → **T2: Feature Dev**
3. Otherwise → **T3: Direct** (plan mode if >3 files, manual if fewer)

**Bead type mapping:**

| Bead Scope | Default Tier | Override When |
|------------|-------------|---------------|
| Epic (multi-bead, dependencies) | T1: Forge | Design decisions already settled → T2 |
| Feature (new command or agent) | T2: Feature Dev | Cross-cutting with design ambiguity → T1 |
| Task (focused, single-concern) | T3: Direct | Scope expands during work → escalate to T2 |
| Bug | T3: Direct | Root-cause unclear across subsystems → T2 |

**Escalation only goes up.** If T3 reveals unexpected scope, escalate to T2. If T2 reveals competing design approaches, escalate to T1. Never demote mid-flight.

**Prfaq-specific tier examples:**

- `/prfaq:import` (new command, multi-file, design choices about parsing) → **T2: Feature Dev**
- `/prfaq:meeting` (multi-agent orchestration, persona design, competing approaches) → **T1: Forge**
- "Technical" subsubsection widow bug (single LaTeX fix) → **T3: Direct**
- New reference guide (single file, clear structure) → **T3: Direct**

### CHANGELOG

This project follows [Keep a Changelog](https://keepachangelog.com/) format. CHANGELOG entries are written **in the PR branch, before merge** — not retroactively on main. The entry is part of the diff that gets reviewed.

**When to add an entry:**
- New commands, agents, or reference guides → `### Added`
- Behavior changes to existing commands → `### Changed`
- Bug fixes → `### Fixed`
- Removed features or commands → `### Removed`

**When NOT to add an entry:**
- Internal-only changes (CLAUDE.md, CI config, dev tooling)
- Plugin cache updates
- Session transcripts or research files

**Format rules:**
- Group entries under `### Added`, `### Changed`, `### Fixed`, `### Removed` (in that order, omit empty groups)
- Each entry starts with the command or component name (e.g., `` `/prfaq:vote` ``, `Installer`, `Template`)
- One logical change per bullet — sub-bullets for supporting detail
- At release time, move `[Unreleased]` entries to a versioned heading and update comparison links at the bottom of the file

## Scratch Files

Use `.tmp/` at the project root for scratch and temporary files — never `/tmp`. The `TMPDIR` environment variable is set via `.envrc` so that `tempfile` and subprocesses automatically use it. Contents are gitignored; only `.gitkeep` is tracked.

### Quality Gates

Before every commit:

```bash
bash scripts/compile_prfaq.sh prfaq.tex           # Dogfood compiles
bash scripts/compile_prfaq.sh assets/prfaq-template.tex  # Template compiles
```

Both must succeed. If a LaTeX change breaks compilation, fix it before committing.

### GitHub Operations

Use the GitHub MCP server tools for all GitHub operations: creating PRs, merging PRs, reading PR status/diff/comments, creating/reading issues, searching, and managing releases. When GitHub MCP is unavailable, the `gh` CLI is acceptable.

Git operations (commit, push, branch, checkout, tag) remain via the Bash tool.

### Pre-PR Checklist

Before creating a PR, verify:

- [ ] **Quality gates pass** — both `.tex` files compile to valid PDFs
- [ ] **Template and dogfood in sync** — environment definitions, packages, and `\newpage` structure match
- [ ] **Version numbers synchronized** — `plugin.json`, `README.md`, and `CHANGELOG.md` agree
- [ ] **README updated** if user-facing behavior changed (new commands, new install steps, new dependencies)
- [ ] **CHANGELOG entry included in the PR diff** for notable changes
- [ ] **Installer updated** if new LaTeX packages added to the template
- [ ] **Skill prompts updated** if new LaTeX environments or commands added
- [ ] **Cached plugin copy updated** if skill or reference guide files changed

### Pull Request and Code Review Workflow

Do **not** merge immediately after creating a PR. Expect **2–6 review cycles** before merging. The full flow is:

1. **Create PR** — Push branch, open PR via `mcp__github__create_pull_request`.
2. **Watch for CI and review feedback without blocking your main shell** — Do not stop waiting:
   ```bash
   gh pr checks <number> --watch         # Blocks until all checks resolve — run in background task or separate session
   ```
3. **Read all feedback via MCP** — Use `mcp__github__pull_request_read` with `get_reviews` and `get_review_comments` to read Copilot, Bugbot, and human reviewer feedback. Prefer MCP GitHub tools over `gh` CLI for all read operations.
4. **Take every comment seriously.** There is no such thing as "pre-existing" or "unrelated to this change" — if you can see it, you own it. If a reviewer flags it, investigate and fix it.
5. **Fix, re-push, repeat** — Commit fixes, run quality gates, push. Go back to step 2.
6. **Merge only when the last review cycle is uneventful** — Zero new comments, all checks green. Merge via `mcp__github__merge_pull_request` (not `gh pr merge` — it has local side effects in worktrees).

### Session Close Protocol

Before ending any session:

1. **File issues for remaining work** — Create beads for anything that needs follow-up
2. **Run quality gates** — Both `.tex` files compile to valid PDFs
3. **Update issue status** — Close finished work, update in-progress items
4. **PUSH TO REMOTE** — This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Verify** — All changes committed AND pushed
6. **Hand off** — Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing — that leaves work stranded locally
- NEVER say "ready to push when you are" — YOU must push
- If push fails, resolve and retry until it succeeds
