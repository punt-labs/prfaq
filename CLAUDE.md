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

**When a feature branch is not needed** (PR directly from a short-lived branch):
- Single-file fixes (compilation, typos, formatting)
- CHANGELOG updates
- Dogfood document edits that don't change the template

Branch protection is active — all changes require a PR, but these don't need
a long-lived feature branch. Releases have their own process (see
[Release Process](#release-process) below).

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

### Release Process

This is a pure plugin — no PyPI artifact. Releases require the dev/prod name
swap described in `plugins.md § Release flow for pure plugins` in the
[punt-kit](https://github.com/punt-labs/punt-kit) standards.
Branch protection is active, so every step that touches main goes through a PR.

**Steps (in order):**

1. **Feature work is merged.** All PRs for the release are on main.

2. **Create a release branch** from main:
   ```bash
   git checkout -b release/vX.Y.Z main
   ```

3. **Bump the version** in `.claude-plugin/plugin.json` (keep the `-dev` name).

4. **Move CHANGELOG entries** from `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD`.
   Add reference links at the bottom (`[X.Y.Z]: ...compare...`).
   Update the `[Unreleased]` link to compare from the new tag.

5. **PR and merge** the release branch (version bump + CHANGELOG).

6. **Pull main**, then do the name swap and tag:
   ```bash
   git pull --rebase
   # Swap plugin name: prfaq-dev → prfaq
   # (use scripts/release-plugin.sh if working tree is clean,
   #  or edit plugin.json manually if untracked files exist)
   git add .claude-plugin/plugin.json
   git commit --no-verify -m "chore: prepare plugin for release [skip ci]"
   git tag vX.Y.Z
   ```

7. **Restore the dev name** immediately:
   ```bash
   # Swap plugin name back: prfaq → prfaq-dev
   git add .claude-plugin/plugin.json
   git commit --no-verify -m "chore: restore dev plugin state"
   ```

8. **Push the tag** (branch protection does not block tags):
   ```bash
   git push origin vX.Y.Z
   ```
   Do **not** push the release/restore commits to `origin/main`. They exist
   only locally to produce the tagged commit with the prod name. The tag
   points at that commit; `main` stays on the dev-name state from the
   release PR. Only the tag is pushed. Reset local main afterward:
   ```bash
   git reset --hard origin/main
   ```

9. **Create a GitHub Release** from the tag:
   ```bash
   gh release create vX.Y.Z --repo punt-labs/prfaq --title "vX.Y.Z" --notes "..."
   ```
   A tag without a Release object does not appear on the Releases page.

10. **Update the marketplace** — PR to `punt-labs/claude-plugins` updating
    `source.ref` and `version` for prfaq in `marketplace.json`.

11. **Update downstream SHA pins** — check and update all of these:
    - `prfaq/README.md` — install.sh SHA pin
    - `public-website/src/data/projects.json` — version + install SHA
    - `punt-labs/.github profile/README.md` — only if it has a prfaq-specific pin

12. **Verify** the tag has the prod name:
    ```bash
    git show vX.Y.Z:.claude-plugin/plugin.json  # must say "name": "prfaq"
    ```

**Common mistakes:**
- Forgetting the name swap (tag ships with `prfaq-dev`) — this broke 4 of 10 releases
- Pushing a tag without creating a GitHub Release object
- Not updating the marketplace `source.ref`
- Not updating README and website SHA pins

## Ethos & Delegation

Identity: `agent: claude` per `.punt-labs/ethos.yaml`. Sub-agent calls (`Agent(subagent_type=…)`) match ethos identity handles.

prfaq is a Claude Code plugin (skills + LaTeX templates) implementing Amazon's Working Backwards PR/FAQ process. Two distinct domains: (1) the *product methodology* — meeting personas, peer review, decision quality — owned by product/PM specialists; (2) the *publishing chain* — LaTeX environments, pdflatex compile gate, plugin packaging — owned by docs/infra specialists. Within each row, the worker and evaluator must be distinct handles. Claude is the leader, never the evaluator.

| Task type | Worker | Evaluator |
|-----------|--------|-----------|
| New PR/FAQ section / methodology guide | `adt` (Hopper) | `mcg` (Cagan) |
| Meeting persona authoring (Alex, Wei, Priya, Dana) | `mcg` | `tdt` (Torres) |
| Peer-reviewer / streamliner skill prompt | `adt` | `mcg` |
| Reference guide (`skills/prfaq/references/*.md`) | `mcg` | `adt` |
| LaTeX template / environment / `\newpage` structure | `edt` (Tufte) | `mdm` (Pike) |
| Compile-gate scripts / installer / pdflatex hygiene | `adb` (Lovelace) | `mdm` |
| Plugin packaging, name swap, marketplace pin | `mdm` | `adb` |
| Skill orchestration / agent wiring | `adt` | `mdm` |
| Customer-evidence research integration | `tdt` | `mcg` |

Use the `standard` pipeline for new commands or methodology changes. Use `quick` for compile fixes or single-section edits. Always re-run both compile gates (template + dogfood) after any LaTeX change — broken templates are broken features.

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
