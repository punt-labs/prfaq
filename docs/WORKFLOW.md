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
  → local review        local_review(diff) (see below) until it returns clean
  → ship                commit → push → PR → Qodo + Bugbot at open → merge gate → merge
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

**Local Review.** The step this session skipped entirely. Local rounds are
cheap and bugs die here; the PR gate stays short. Review is agent-owned end
to end: the operator may read the diff in the IDE, but that inspection is
non-gating and nothing here waits on it. `local_review` is a function the
leader runs on a diff before the PR opens and before every fix push:

```text
function local_review(diff):
    for round in 1..5:
        if this is the unit's first full diff or diff is 20 lines or more:
            reviewers = `qodo review` + silent_failure_hunter + code_reviewer
        else:
            reviewers = `qodo review`    # a small fix diff
        reviewers += the content reviewers for what the diff touches
                     (table below)
        if diff touches credentials, secrets, or caller text that reaches
                a file, a log line, or a header:
            reviewers += djb             # whatever the diff's size
        if this is not the unit's first full diff:
            scope: regressions this diff introduces, and High findings
                inside it — nothing outside the diff, no Medium or Low on
                unchanged behaviour
        run reviewers in parallel        # qodo review from the worktree,
                                         #   against the pushed base
        re-run once any reviewer that did not complete (error, outage)
        if a reviewer still has not completed:
            report it to the operator
            return blocked               # a review that never ran is not
                                         #   clean
        findings = every reviewer's findings
        if round == 5 and a finding needs a fix:
            report the open findings to the operator
            return blocked
        answer each finding: fix it, or dismiss it with the exact finding,
            the specific reason, and the code reference
        close each local Qodo finding through the Qodo CLI
            (mark-implemented or dismiss, with its local_review_id) —
            an unclosed one comes back as still_open in every later run
        if no finding was fixed:
            return clean                 # nothing found, or all dismissed
        make check; commit
        diff = this round's fix diff     # every change is reviewed,
                                         #   Low fixes included
    # at most four fix rounds, plus a fifth review that only verifies the
    # fourth round's fixes. No deferral beads. Every caller acts only on
    # clean: on blocked, nothing opens and nothing is pushed until the
    # operator rules and local_review then returns clean.
```

The three standard reviewers are not substitutes — in the vox pilot each found
defects the other two missed — so every first full diff and every fix diff of
20 lines or more gets all three. From the second round on the review is scoped
to what the diff changed; without that boundary a failure-focused reviewer
walks outward into code the diff never touched and the rounds do not converge.
`qodo review` is the engine that later reviews the PR, so what it finds
locally does not come back as a PR round. Add content reviewers by what
changed:

| Touched | Also run |
|---|---|
| Skill prompts, agent personas, reference guides | `prfaq:peer-reviewer` (content/methodology review, not code review) |
| LaTeX templates or the dogfood document's structure | `prfaq:peer-reviewer`, then confirm `make check` still compiles cleanly |
| Meeting summaries, or any prose subject to the banlist | the prose-lint hook already gates this live; additionally re-run `python3 plugin/scripts/prose_lint.py --config plugin/banlist.conf --profile business <file>` by hand for anything edited outside the `Write`/`Edit` tools (a direct Bash file write bypasses the hook — see `plugin/hooks/prose_lint_hook.py` for why bulk cleanups sometimes need this path) |

`silent-failure-hunter` and `code-reviewer` are Claude Code sub-agents
deployed by `ethos seed`; `qodo review` is the Qodo CLI.
`prfaq:peer-reviewer` ships with *this* repo's own plugin and is always
available. If a reviewer is not installed in your session, `local_review`
returns blocked — a read-through of the diff against `CLAUDE.md`'s Standards
and this doc's Loop 2 is not a substitute.

Fix every finding or document why it doesn't apply (no "pre-existing," no
"outside scope" — see `CLAUDE.md` § No "Pre-existing" Excuse). Only when
`local_review` returns clean, push.

**Ship.** Push, open the PR (`mcp__github__create_pull_request`), and
schedule a background poll with `/loop 3m` — never `gh pr checks --watch`,
never a foreground sleep loop. Qodo reviews once, when the PR opens
(`.pr_agent.toml`), and Bugbot reviews once, on its own, at open (Cursor
dashboard: once per PR); neither runs on push, and round 1 needs no
`bugbot run` comment. Copilot reviews only when the operator asks: at most one
request per PR, at open, never on push. Merge via
`mcp__github__merge_pull_request`, explicitly — no auto-merge, no admin
override.

**Remote review: Qodo and Bugbot, at most two rounds.** Remote review is
automated-only, runs on already-clean code, and its budget is
fixed. The full specification is
[`punt-kit/standards/pr-review.md`](https://github.com/punt-labs/punt-kit/blob/main/standards/pr-review.md);
this section carries the terms and the poll loop this repo runs.

Qodo is the primary remote reviewer. High findings post inline as threads, and
the `required_review_thread_resolution` ruleset rule makes each one block the
merge. Medium findings appear in the summary. Lows are dropped by
`comments_routing`. Round 1 is the review at open. Round 2 — one
`/agentic_review` comment plus one `bugbot run` comment — happens only when
round 1's fixes included a High, and it is the last. A new High in round 2
goes to the operator; it is never fixed or dismissed on the leader's own
authority.

This holds only when four settings are in place: `.pr_agent.toml` is on
`main` (Qodo reads it from the default branch); "Review every push" is
Disabled in the Qodo portal; Bugbot is set to review each PR once, at open;
and the ruleset has no `copilot_code_review` rule. If a push still starts a
Bugbot run, its findings are findings like any other.

All terms are read from GitHub; Qodo's login is `qodo-code-review[bot]`.

```text
round(pr)    = 1 + the number of "/agentic_review" comments the leader has
               posted on the PR
trigger(N)   = the PR open, for N = 1; the leader's (N-1)th
               "/agentic_review" comment, for N > 1
head(N)      = the PR head commit when trigger(N) happened
qodo_in(N)   = `qodo read pr-review-session findings --pr-url <url>` reports
               review_session.status "completed" with a started_at at or
               after trigger(N) and a commit_sha that is head(N) or a later
               commit on the branch; or the outage fallback ran for round
               N. A session that started before trigger(N), or a late reply
               to an earlier round, never completes round N, and a clean
               review counts like any other.
bugbot_in(N) = a "Cursor Bugbot" check run on head(N) or a later branch
               commit, started at or after trigger(N) — the PR open for
               N = 1 (Bugbot's automatic run), round 2's "bugbot run"
               comment for N = 2 — and completed with any conclusion except
               cancelled; or 30 minutes since trigger(N). A run a push
               cancelled reviewed nothing, so it does not count; a later
               push does not undo a completed run. A clean run posts no
               review, so read the check run.
copilot_in   = no Copilot review was requested on the PR, or one was and
               (a review by copilot-pull-request-reviewer exists or 30
               minutes have passed since the request)
pending(pr)  = not skipped(pr) and (not qodo_in(round(pr))
               or not bugbot_in(round(pr)) or not copilot_in)
finding      = any unresolved review thread, from any author, or any Medium
               in Qodo's summary — whenever it arrives, late ones included
answered(f)  = one path per source, never both:
               - a finding with a Qodo id (from the CLI read): its
                 attribution_status is closed (implemented, dismissed,
                 outdated); close it with `qodo pr-review-session
                 mark-implemented` or `dismiss` plus the reason and
                 file:line. A ledger line does not close it.
               - any other finding — Bugbot, a security automation,
                 Copilot, a human, the local outage fallback: fixed by a
                 commit on the PR head, or a ledger comment gives the
                 reason and file:line.
               A finding repeated from an earlier round keeps its answer.
new High     = a High not raised in an earlier round; a manual review may
               re-scan the whole PR and repeat old findings
escalation   = the leader's "escalated:" comment on one new round-2 High;
               closed by a later ledger entry recording the operator's
               ruling and how it was applied
skipped(pr)  = the PR author is a bot ([github_app] ignore_bot_pr in
               .pr_agent.toml); no title or label lets an author skip
reviewed_head = the newest commit covered by a Qodo review, the outage
               fallback, or the local delta review below
bugbot_open  = a Cursor Bugbot check run on the head whose status is not
               completed (queued or in progress) and that was created under
               30 minutes ago
```

A ledger comment is a PR comment that records one finding, its reason, and
the code reference. "Pre-existing," "intentional," "expected," and "by
design" are not reasons.

The leader polls the PR in the background. Cadence is 3 minutes while
anything is pending and 15 minutes after, when only CI or a late thread can
change state.

```text
function poll_tick(pr):
    state = current reviews, threads, checks
    N = round(pr)
    if CI failed: fix in this PR
    if not skipped(pr) and not qodo_in(N)
            and 30 minutes have passed since trigger(N)
            and the fallback has not yet run for round N:
        run code_reviewer locally on the diff Qodo was asked to review;
            it completes round N for qodo_in; its findings have no Qodo
            id, so they take the ledger path       # outage fallback
    for each finding not answered(f) and not under an open escalation:
        if N == 2 and f is a new High:
            post an escalation comment; the operator rules
        else:
            fix it now, or answer it by its source's path (answered(f))
            # never re-litigated; Qodo Lows are dropped by comments_routing;
            # no deferral beads
    for each escalation the operator has ruled on:
        apply the ruling; record it in a ledger comment
    if fixes were made: delegate them to a bare agent; make check; commit
        if local_review(the fix diff) is blocked:
            stop; the operator rules
        push once                          # every fix reaches the PR head
    close each escalated finding the operator ruled on, by its answered(f)
        path, only once its fix commit is on the PR head and passed
        local_review — a finding with a Qodo id through the Qodo CLI
        (mark-implemented; or dismiss if the ruling was dismiss), because
        a ledger line does not close it
    resolve each thread that is answered, one by one — the leader
        resolves, not the agent
    if not skipped(pr) and not pending(pr) and N == 1
            and a High was fixed since trigger(1):
        comment "/agentic_review"; comment "bugbot run"   # opens round 2,
                                                          #   the last
    if not pending(pr) and no review is requested and the PR head is newer
            than reviewed_head:
        run code_reviewer locally on the reviewed_head..head delta; its
            findings are findings like any other   # bounded rounds, but
                                                   #   no unreviewed merge
    if not pending(pr) and not bugbot_open and no finding is unanswered:
        cadence = 15m
    else: cadence = 3m
    if the poll's interval is not cadence:
        cancel the poll job; schedule the poll at cadence in its place
    re-read state                          # the gate must see this tick's
                                           #   push and comment
    if merge_gate(state): merge (squash); close_out()

function merge_gate(state) -> bool:
    return CI green on the latest commit
       and not pending(pr)                 # no requested review outstanding
       and not bugbot_open                 # a push-started run's findings
                                           #   land before the merge
       and (skipped(pr) or reviewed_head is the PR head)
       and every finding is answered
       and zero unresolved review threads
       and round(pr) <= 2
       and no escalation is open
    # prfaq defines no demo, so demo_ok(pr) holds. A push restarts CI, not
    # review. When this returns true: merge explicitly. No auto-merge. No
    # admin override. Do not ask, do not wait.

function close_out():
    cancel the poll loop
    checkout main; pull; delete the branch # local and remote; a checked-out
                                           #   branch cannot be deleted
    bd close the bead(s), if the unit had any
    send the merge recap                   # every merge, unprompted, with the
                                           #   review data block from
                                           #   ../.bin/review-metrics.py pr
                                           #   punt-labs/prfaq <N> --format
                                           #   recap, pasted verbatim
    if the PR was a release/ branch:
        run the remaining Release Process steps in CLAUDE.md (name swap and
            tag, GitHub Release, marketplace, downstream pins) first
    start the next unit immediately        # no stopping to report
```

A finding that arrives late is handled the moment it arrives, like any other.
A fix push is reviewed locally first (`local_review` on the fix diff) and is
never followed by a request for another remote review; the only way back into
remote review is round 2, and only after a High fix.

**Close.** `close_out` above: `bd close <id>` (if a bead existed), pull main,
delete the branch, and — this is also mandatory, not optional — actually push
before the session ends (see `CLAUDE.md` § Session Close Protocol).

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
