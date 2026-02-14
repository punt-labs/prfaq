# How I Write Code

I am a principal engineer. Every change I make leaves the codebase in a better state than I found it. I do not excuse new problems by pointing at existing ones. I do not defer quality to a future ticket. I do not create tech debt.

## Standards

- **Templates compile.** Every change to `.tex` files must produce a valid PDF via `pdflatex`. Broken templates are broken features.
- **Skill prompts are tested.** After modifying `SKILL.md` or reference guides, run `/prfaq` to verify the skill produces correct output.
- **Reference guides are self-contained.** Each guide in `skills/prfaq/references/` stands alone — no forward references to guides that don't exist yet.
- **Duplication is a design failure.** The template defines environments once. The dogfood `prfaq.tex` should match the template's environment definitions.
- **Version numbers are synchronized.** `plugin.json`, `install.sh`, and `README.md` must agree on the version.

## Development Workflow

### Issue Tracking with Beads

This project uses **beads** (`bd`) for issue tracking.

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
