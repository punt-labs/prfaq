# Tracking work in a Punt Labs repo

How an agent tracks work in a Punt Labs repo. punt-kit deposits this file;
edit the source in punt-kit (`src/punt_kit/templates/punt-guide.md`), never
this copy. The normative text is the punt-kit repo's `standards/workflow.md`
§ 4 (the backlog loop) — the org standard, not your repo's own
`docs/WORKFLOW.md`; this file is the operating rule that section leaves to the
tracker.

**Linear** is the tracker of record for every Punt Labs repo: the durable,
cross-session source of truth for what work exists and what state it is in.
One hosted team holds all of it — **Punt Labs**, key `PL`, id
`c1dfbb2c-985e-40cf-b004-5127646efc9d`. Reach it from the Linear web app, or
from the Linear MCP tools when your harness has them (`list_issues`,
`save_issue`, `list_comments`, and the rest). An issue is addressed by its
identifier, e.g. `PL-1051`.

One team holds every repo's work, so an issue carries a **repo label** —
`repo:<name>`, e.g. `repo:punt-kit` — that says which repo owns it. Every
read and every write names that label, so this repo's issues stay separate
from the rest of the team.

## Which issues are this repo's

List with the repo label to stay inside this repo:
`list_issues` filtered by team `PL` and label `repo:<name>` (the web app's
label filter does the same). The repo label is the one scoping key; nothing
else distinguishes one repo's issues from another's on the shared team.

## Working an issue

- **Plan from Linear.** List open, unblocked issues for this repo
  (`list_issues` by team `PL`, label `repo:<name>`, status not Done/Canceled)
  and read one with `get_issue`. `list_comments` returns an issue's
  discussion — `get_issue` does not include it.
- **Create** an issue on team `PL` with `save_issue` (omit `id` to create),
  carrying the mandatory `repo:<name>` label plus a type label — `Bug`,
  `Feature`, `Improvement`, or `Epic`. Give it a clear imperative title, a
  description another engineer or agent can act on, and a priority. Statuses
  and labels belong to the team; call `list_issue_statuses` or
  `list_issue_labels` for `PL` when unsure which values it supports.
- **Claim, finish, and cancel** by setting the issue's status — In Progress,
  Done, Canceled — with `save_issue` (pass `id` to update, and only the
  fields you change). A session task list mirrors the claimed batch for the
  operator; the Linear issue is the record.
- **Blocked** is a `blocks` relation in Linear between the blocker and the
  blocked issue. Pick work whose blockers are all Done.
- **Deferred** is state Backlog plus the `deferred` label; skip deferred
  issues when picking the next unit.
- **Edit** title, description, priority, labels, relations, and projects in
  Linear. To change part of a long description, pass `patch` to `save_issue`
  rather than resending the whole body. `addLabels` / `removeLabels` adjust
  one label without dropping the rest; the `labels` field replaces the whole
  set.

## Both

- T4 work (a typo, a one-line fix, a mechanical refactor with no design
  choice) needs no issue; the commit is the record.
- Work is not complete until `git push` succeeds.
