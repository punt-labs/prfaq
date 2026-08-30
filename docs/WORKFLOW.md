# Development Workflow

Three nested loops. Read this before touching any file in the repo — it is
`@`-imported from `CLAUDE.md` so it loads at session start.

This doc exists because a 2026-08-30 session edited `prfaq.tex` and eight
files under `meetings/` directly on `main` — no bead, no branch, no local
review, nothing committed for hours of work. The cause was a single
ambiguous sentence in `CLAUDE.md`'s old Branch Discipline section ("Small
fixes... can go directly to main") read as license to skip the PR loop
entirely for anything that felt mechanical. It never did license that, and
after this rewrite it cannot be misread that way: **nothing lands on `main`
except through a merged PR.** See `prfaq-6wz`.

## Loop 1: Backlog

*What to work on, and in what order.*

1. `bd ready --label-any repo:prfaq` — see everything unblocked. Beads is a
   single shared central DB across all punt-labs repos; `bd ready` does not
   auto-scope to this repo in bd 1.0.4 the way `bd list` does (see
   `.beads/config.yaml` and `.beads/README.md`), so the bare form can surface
   other repos' work. `bd list` alone is auto-scoped and fine for a quick
   look; use the `--label-any` form for anything you're about to act on.
2. Pick a bead, or create one (`bd create "<title>"`, optionally with
   `--description "..."` for extra context) if the work isn't tracked yet.
   Skip this only for genuinely trivial,
   single-file, single-session fixes (see Workflow Tiers, T4 below) — even
   those still go through Loop 2.
3. `bd update <id> --status=in_progress` to claim it.
4. Pick a tier (`CLAUDE.md` § Workflow Tiers) — T1 Forge, T2 Feature Dev, T3
   Direct, or T4 (see below). The tier decides which tool drives Loop 2, not
   whether Loop 2 runs.

**T4: Trivial, no bead.** A single-character typo fix, a broken link, a
version-string bump nobody could disagree with. No design ambiguity, no
judgment call, one file, one line. Still goes through Loop 2 (branch, PR) —
T4 only means skip the bead, not skip the branch.

**The exemption is about triviality of the single change, never about
count.** "Eight files, each edit mechanical" is not T4 — it is exactly the
kind of work Loop 2 exists to catch, because a mechanical edit repeated
eight times is eight chances to get one of them wrong, and nobody reviewed
any of them before this session found out the hard way (`prfaq-6wz`). If
you are touching more than one file, or a content-quality pass across
several documents, claim a bead and branch — full stop.

## Loop 2: PR

*One rollback-coherent merge.* This is the loop that failed on 2026-08-30.
Every step below is mandatory; none is exempt for "small" work — only the
bead in Loop 1 is optional (T4), never the branch, never local review.

```text
claim (Loop 1)
  → branch            git checkout -b <prefix>/<short-description> main
  → implement          write the change
  → verify              make check  (must pass before every commit)
  → document            CHANGELOG.md, README.md, DESIGN.md as applicable
  → local review        run the applicable review agents (see below) to zero findings
  → ship                commit → push → PR → Copilot review → cycle to clean → merge
  → close               bd close <id>, delete branch, pull main
```

**Branch.** `git checkout -b <prefix>/<short-description> main` — always,
even for a single-file fix. Prefixes: `feat/`, `fix/`, `refactor/`, `docs/`
(see `CLAUDE.md` § Branch Discipline for the full table). "Short-lived" and
"no long-lived feature branch needed" describe how long the branch lives
and what it's named, never whether one exists. Branch protection is
already configured to require a PR for everything; this loop is what makes
that configuration actually bite in practice instead of getting routed
around by `claude-puntlabs` bypass rights. Bypass rights exist for CI
emergencies, not for convenience — see the org-wide `punt-labs/CLAUDE.md`
§ Claude Agento (loaded via Claude Code's ancestor-directory walk from the
`punt-labs/` workspace meta-repo, not a file inside this repo).

**Implement & Verify.** `make check` (compiles every `.tex` in `TEX_DIRS`,
runs the permission tests, runs the prose-lint test suite) must pass before
every commit, not just before the PR. A commit that fails `make check` is a
broken commit.

**Document.** `CHANGELOG.md` for user-facing change (skip for internal-only
edits per the existing rule), `README.md` if install/usage changed,
`DESIGN.md` ADR for an architectural or process decision with rejected
alternatives.

**Local Review.** The step this session skipped entirely. Run before
pushing, not after — GitHub review cycles are slow; local review is
seconds. Pick agents by what changed:

| Touched | Run |
|---|---|
| Python (`plugin/scripts/*.py`, `plugin/hooks/*.py`) | `feature-dev:code-reviewer` + `pr-review-toolkit:silent-failure-hunter` |
| Skill prompts, agent personas, reference guides | `prfaq:peer-reviewer` (content/methodology review, not code review) |
| LaTeX templates or the dogfood document's structure | `prfaq:peer-reviewer`, then confirm `make check` still compiles cleanly |
| Meeting summaries, or any prose subject to the banlist | the prose-lint hook already gates this live; additionally re-run `python3 plugin/scripts/prose_lint.py --config plugin/banlist.conf --profile business <file>` by hand for anything edited outside the `Write`/`Edit` tools (a direct Bash file write bypasses the hook — see `plugin/hooks/prose_lint_hook.py` for why bulk cleanups sometimes need this path) |

The `feature-dev:*` and `pr-review-toolkit:*` names are Claude Code
sub-agents shipped by the `feature-dev` and `pr-review-toolkit` plugins —
not something defined inside this repo, so they're only invokable in a
session where those plugins are installed. `prfaq:peer-reviewer` ships with
*this* repo's own plugin and is always available. If the `feature-dev`/
`pr-review-toolkit` plugins aren't installed in your session, substitute a
manual read-through of the diff against `CLAUDE.md`'s Standards and this
doc's Loop 2, rather than skipping the step.

Fix every finding or document why it doesn't apply (no "pre-existing," no
"outside scope" — see `CLAUDE.md` § No "Pre-existing" Excuse). Re-run until
clean. Only then push.

**Ship.** Push, open the PR (`mcp__github__create_pull_request`), request
Copilot review once, then cycle per `CLAUDE.md` § Pull Request and Code
Review Workflow until a review round is uneventful. Merge via
`mcp__github__merge_pull_request`.

**Close.** `bd close <id>` (if a bead existed), delete the branch, pull
main, and — this is also mandatory, not optional — actually push before the
session ends (see `CLAUDE.md` § Session Close Protocol).

## Loop 3: Delegation

*One worker/evaluator dispatch*, nested inside Loop 2's implement step when
the work matches a row in `CLAUDE.md` § Ethos & Delegation. Worker and
evaluator are always distinct handles; Claude is the leader, never the
evaluator. Use the `standard` pipeline for new commands or methodology
changes, `quick` for compile fixes or single-section edits. A delegation
still has to clear Loop 2's Verify and Local Review steps before it ships —
delegating the drafting does not delegate the accountability.

## What this doc is not

It does not replace `CLAUDE.md`'s Quality Gates, CHANGELOG rules, Release
Process, or Pre-PR Checklist — those stay where they are and this doc
points to them rather than restating them. This doc is the *shape* of the
loop; `CLAUDE.md`'s other sections are the *content* inside each step.
