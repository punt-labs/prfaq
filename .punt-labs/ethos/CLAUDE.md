# Ethos

How an agent drives ethos — not how to develop ethos itself. Ethos binds a
name, voice, email, GitHub handle, writing style, personality, and talents
into one identity that other tools read.

New in this repo, or `ethos doctor` reports missing state? Setup guide is
deposited alongside this file at `.punt-labs/ethos/ETHOS-SETUP.md` on
`ethos enable`. Pre-enable, fetch from
<https://github.com/punt-labs/ethos/blob/main/docs/ETHOS-SETUP.md>.
Either way it's a one-time task and is deliberately not `@`-imported here.

## Who am I

- `ethos whoami` — resolve your identity from the session, git config, or OS
  user.
- `ethos iam <persona>` — declare a persona for the current session.

Session hooks inject your persona into context at start and after
compaction. Ethos generates `.claude/agents/<handle>.md` from team data at
SessionStart; restart Claude Code to regenerate them after a team change.

## Delegation (missions)

- `ethos mission dispatch --worker <h> --evaluator <h> --write-set <paths> --criteria <text>`
  — write a mission contract. Dispatch writes the contract; a separate
  agent spawn does the work.
- `ethos mission show|log|results <id>` — inspect a mission.
- `ethos mission close <id>` — close a passing mission (requires a
  submitted result for the current round).
- `ethos mission abandon <id> --reason <text>` — retire a mission that
  was created but never had a worker spawned against it. Refuses if any
  *blocking* delegation or any result exists — use `close` for those.
  A delegation refused before its worker ran (`verdict: aborted`) never
  blocks, automatically. A delegation proven to be a dispatch-sidecar
  misattribution (DES-076) can be named via repeatable
  `--disclaim <delegation-id>` to unblock just that one. Neither is a
  bypass of `close`'s result gate, which has no override; see
  `docs/mission-abandon.md`.
- `ethos mission pipeline list|show|instantiate <name>` — drive multi-stage
  work from a template.

Commit one logical step at a time; the write-set is enforced at runtime, so
an edit outside it fails the mission.

## Audit

- `ethos audit show --delegation <id>` — reconstruct a delegation's trail.
- `ethos audit seal` runs at pre-commit when ethos is enabled here. DES-079
  requires local archives by default, not automatically committed chunks.
- `ethos audit quarantine` — the recovery path for a corrupt chunk.

## Storage and sharing (DES-079; acceptance pending)

DES-080 redaction shipped in v4.20.0. The DES-079 requirements below are
pending final entry-point acceptance, not guarantees of an installed binary.
The [storage contract](https://github.com/punt-labs/ethos/blob/main/docs/storage-layout.md)
supersedes older tracked-by-default and checkout-local audit guidance.

Four classes: source/configuration and blame records are intended for Git;
trace is retained locally with explicit sharing; runtime state is never
published. Regenerated agents are expected source changes when inputs or the
binary change. Edit their sources, not generated output. Redaction is only a
backstop: contracts and commands must not contain credentials.

- Resolve canonical store root **S** through Git's common directory,
  separately from invoking checkout **C**. Shared source/blame records live
  in `S/.punt-labs/ethos/`; all new repository live logs, retained archives,
  overlays, locks, receipts, scratch and temporaries belong under
  `S/.punt-labs/local/ethos/`. No record-tree ignore workaround.
- C owns generated agents, guide/marker/import deposits and publication into
  its actual index. Removing a linked C distinct from S must retain even
  unsealed tails without SessionEnd; deleting S or its local data is not covered.
- `record: blame` is the default; sealing neither queries nor changes the
  index. `record: full` retains the same local trace and adds eligible copies,
  including sealed session audits. Consent is per immutable entry. Mode
  switches do not promote old private history or remove published history;
  pending eligible copies remain retryable. Invalid config fails visibly,
  validated once per request, including each MCP call.
- Full Reflection submission remains mandatory. Bounded inline v1
  `round_decisions` in the shared contract govern advancement; full prose
  stays local. Durable local intent and required event precede decision
  installation. A prepared event alone grants no permission. Reads must
  distinguish submitted/detail unavailable here from never submitted, legacy
  unknown or unreadable authority. Ordinary required-event rollback remains.
  Local detail uses per-round envelopes at
  `S/.punt-labs/local/ethos/trace/missions/<id>/reflection-<round>.yaml`;
  pending receipts use `missions/<id>/reflection-intents/<round>.yaml` under
  the same local root. Each has `version`, `kind`, `mission`, `decision`,
  `reflection`, `event`, `event_session` and `publish`. Join the complete
  decision against shared authority; a receipt alone does not mean accepted.
  Published/exported `reflections.yaml` is an aggregate, not this local format.
- Repository overlays move to
  `S/.punt-labs/local/ethos/identities/<handle>.ext/<namespace>.local.yaml`;
  ordinary writes remain base-only. Overlays are not a vault and may reach
  model context. Global overlay layout is unchanged.
  Legacy repository siblings are read-only: stop writers and explicitly
  reconcile each into the local destination, preserving all credentials and
  resolving an existing destination before removing the old copy. Unequal
  copies refuse reads; local writes refuse while a legacy sibling remains.
  Never serialize the merged identity into the base or print credentials.
- Worker files, including `MISSION_ARTIFACTS_DIR`, target local scratch, not
  the tracked delegation directory. Ethos does not automatically move, export
  or redact agent-owned files; legacy cleanup is operator-directed.
- Pending `mission publish <id>...` snapshots complete selected blame records
  into C and its actual index. `provenance message <ref>` supplies the
  generated body for the head-pinned GitHub squash route; fetch and
  `provenance verify <mergeSHA>` afterward. Local hooks do not run remotely.
  See the [merge procedure](https://github.com/punt-labs/ethos/blob/main/docs/example/07-pr-and-merge.md).
- Plain `mission export` remains contract + final result, without staging.
  Pending `mission export <id> --full` explicitly shares that mission's
  retained prompts, reflections and event chunks, including a locally sealed
  unsealed tail, regardless of original mode. Missing expected history is
  incomplete. It excludes session audits, scratch, overlays, artifacts and
  transcripts. Use ordinary `git add`, never force-add.
- Readers union local, published and supported legacy evidence in either
  mode, collapse equal copies and report conflicting payloads before watermark
  filtering. Direct filesystem consumers need this contract too; legacy
  fallback inside Ethos does not update Quarry or Desk automatically.
- All repository staging stays local; `EXDEV` refuses
  with the old target intact, never an adjacent-temp/copy-over fallback.

### Bounded legacy repair

`ethos repair --dry-run` inventories known obsolete trace/runtime files.
Destructive `ethos repair` lists them, warns of permanent loss of old prompts,
reflections, events/audit history and runtime residue, and asks
`Are you sure? [y/N]` in a terminal. Empty input, no and EOF delete nothing.
`--yes` explicitly consents for automation and asserts that all old/new writers,
hooks and MCP servers are stopped. Busy locks refuse. Windows supports inventory
but currently refuses destructive repair; deletion requires a Unix host with all
writers stopped.

No backup, lossless migration, authority backfill, lifecycle change, Git
staging/commit or configuration rewrite is performed. Cleanup excludes shared
identities, contracts, results, corrections, provenance and ADRs, private
credentials/overlays, configuration, global data, arbitrary/agent-owned files and
canonical local history. Current publications and flat current exports
(`missions/<id>.contract.yaml` / `<id>.result.yaml`, with associated trace) are
retained, including incomplete/ambiguous exports. Other intentional publications
and exports are not blanket deletion targets. Repair neither moves nor deletes
private overlays; use the operator-directed handling above. Historical shipped
`mission migrate` / `audit migrate` are not expanded; there is no storage-upgrade
command.

After interruption, inspect a fresh inventory and confirm again; incremental
deletion has no rollback. Old missions may need manual retirement; repair never
invents shared authority. Review tracked deletions and stage/commit normally.
Then run `ethos enable` to refresh integration and reconnect long-lived MCP
servers. Re-enable maintains the shared local-zone exclusion, not record-tree
ignore exceptions; it does not prove final storage acceptance.

## Session

- `ethos session` — the current roster.
- `ethos session purge` — clear stale sessions.

## Review agents

`ethos seed` deploys three review-checklist agents to `.claude/agents/`:
`code-reviewer` (general code-quality and CLAUDE.md-compliance),
`silent-failure-hunter` (error handling, swallowed exceptions, fallback
logic), and `invariant-completeness-reviewer` (verifies a claimed invariant,
exhaustiveness property, or regression-guarding test actually holds, rather
than trusting the prose that asserts it). These are checklist agents, not
mission-dispatchable specialists: invoke them directly as local review
passes, never via `ethos mission dispatch --worker <handle>`.

Local review sequence, after `make check` passes:

1. Run `code-reviewer` on the diff.
2. Run `silent-failure-hunter` on the diff.
3. Run `invariant-completeness-reviewer` on the diff.
4. Fix all valid findings; re-run until all three return zero findings.

## Gotchas

- Reinstalling ethos does not restart a running MCP server. An `ethos
  serve` started before the install keeps answering from the old binary
  — reconnect the ethos server afterwards, or the new code stays inert.
  Installing mid-session is itself safe: every supported install path
  unlinks or renames over the old file rather than writing into it, so a
  running process keeps its own image and never hits `ETXTBSY`.
- Agent types are discovered at SessionStart; restart after adding one.
- `ethos doctor` checks seal and trailer hook presence only when ethos
  is enabled here, but its hook currency checks run unconditionally, on
  dormant repos too.
