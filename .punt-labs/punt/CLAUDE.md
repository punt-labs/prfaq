# Tracking work in a Punt Labs repo

How an agent tracks work in a Punt Labs repo. punt-kit deposits this file;
edit the source in punt-kit (`src/punt_kit/templates/punt-guide.md`), never
this copy. The normative text is the punt-kit repo's `standards/workflow.md`
§ 4 (the backlog loop) — the org standard, not your repo's own
`docs/WORKFLOW.md`; this file is the operating rule that section leaves to the
tracker.

Two trackers exist. **Beads** is the local issue database behind the `bd`
command; one issue in it is a *bead*. **Linear** is the hosted tracker, used
from its web app or from the Linear MCP tools when your harness has them: one
team, **Punt Labs**, key `PL`, id `c1dfbb2c-985e-40cf-b004-5127646efc9d`. A
*pull* copies Linear into beads; a *push* copies beads into Linear.

## Which tracker is the record here

Run `bd config get linear.pull_label`. Output starting with `repo:` means this repo is migrated and
Linear is the tracker of record. Anything else means beads is. `bd config get issue-prefix` cannot
tell you: it prints `issue-prefix (not set)` on migrated repos whose `.beads/config.yaml` has the key.
Nor can `bd linear status`: it prints `Status: Not configured` on a working setup. The migrated set
is `bd config get linear.push_prefix`, read live; it is maintained nowhere else. If the output is not
`repo:` but this repo prefix is in `linear.push_prefix`, this checkout is behind main: pull it and
re-run; until then do not write to beads.

## Migrated repos: Linear is the record

Beads is a read-mostly local mirror. Do not use it as the record when Linear
is available. Every migrated bead stores its Linear URL in `external_ref`.

- **Plan from Linear.** `bd ready` and `bd show` are fine as local reads
  because the mirror carries the dependency graph; `bd list` and `bd ready`
  need `--label-any <the repo label>` to stay inside this repo, because the
  shared database holds every repo's beads. Refresh the mirror first:
  `bd linear sync --pull-if-stale --relations --team c1dfbb2c-985e-40cf-b004-5127646efc9d`
  pulls only when `.beads/last_pull` is missing or older than 20 minutes, never
  twice within 5 minutes (needs `LINEAR_API_KEY`). `--relations` imports added
  `blocks` edges; a pull removes none, so a blocker cleared in Linear still
  blocks locally until you run `bd dep remove <bead> <blocker>`. Until both the
  add and the removal are reconciled, `bd ready` can disagree with Linear.
  Auto-pull (`bd prime` pulling on its own at session start) is not on in every
  repo; never assume it ran.
- **Write in Linear, not beads.** Create an issue with the mandatory repo
  label (the value `bd config get linear.pull_label` printed) plus a type
  label (`Bug`, `Feature`, `Improvement`, `Epic`); a pull imports only issues
  carrying that repo label. Edit title, description and priority there. Claim, finish
  and cancel with the states In Progress, Done and Canceled. Labels, `blocks`
  relations and projects are Linear-only.
- **Three proven facts about sync.** A push sends no labels. A pull replaces a bead's label set
  with the issue's, so a beads-only label is wiped. A pull resets a bead's status to the issue's
  state, so a `bd close` made only in beads is undone by a later pull (the cursor bullet says when).
- **Blocked** means a `blocks` relation in Linear plus `bd dep add <bead>
  <blocker>`: a pull imports relations only with `--relations`, removes none.
- **Deferred** means state Backlog plus the `deferred` label; pick work with
  `bd ready --label-any <the repo label> --exclude-label deferred` (the repo
  filter keeps it inside this repo, as every migrated read does).
- **Automated loops** write status in Linear, then refresh the bead with a
  scoped `bd linear sync --pull --issues <PL id> --team <id>` — never a local
  `bd update`/`bd close`, which is the forbidden local edit below and strands
  other Linear changes to the same issue.
- **The one sanctioned beads-first write** is `bd linear sync --push --issues
  <bead ids> --team <id>` (title, description, priority, state only); then add
  labels in Linear, then `bd linear sync --pull --issues <PL ids> --team <id>`.
- **One cursor per repo label, shared by push and pull.** It is a saved timestamp; an incremental pull
  fetches only Linear changes after it, and every non-dry-run sync in this repo, a push included,
  moves it. A push hides Linear edits since the last pull from this repo's next incremental pull, not
  another repo's. Never edit a migrated bead locally, `bd close` included: the next pull, scoped or
  not, skips a bead edited after the cursor and moves the cursor past it; a later pull that fetches
  the issue (on its next Linear change, or by `--issues`) overwrites the bead, status included.
- **Never:** a bare `bd linear sync`; an unscoped `--push`;
  `bd config set linear.*` (shared by every repo); removing `issue-prefix` or
  `linear.pull_label` from `.beads/config.yaml` (an unscoped pull imports the
  whole PL team).
- **ID bridge.** Bead to Linear: `bd show <id>` prints the `external_ref` URL. Linear to bead:
  `bd list --json --all --limit 0 --label-any <the repo label>` and match on `external_ref`.

## Beads-only repos: beads is the record

`bd create`, `bd ready`, `bd show`, `bd update <id> --status in_progress`, `bd close`. Labels and
dependencies live in beads. To migrate, use the `linear-migrate` skill in the workspace: the
punt-labs/punt-labs meta-repo, whose `.claude/skills/` holds it — one directory above a child repo,
or this repo itself when the guide is deposited in the workspace.

## Both

- T4 work (a typo, a one-line fix, a mechanical refactor with no design
  choice) needs no issue; the commit is the record.
- Work is not complete until `git push` succeeds.
- Beads mechanics: the workspace `.docs/BEADS-SETUP.md`.
- Migration and reversal: the workspace `linear-migrate`, `beads-to-linear` and `linear-unmigrate` skills.
