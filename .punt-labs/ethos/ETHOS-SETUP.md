# Ethos Setup (for the agent)

Read this if you have landed in a repo where ethos is not yet enabled, or
where `ethos doctor` reports missing state. The binary is assumed present —
`ethos version` should already work. This file is deliberately not
`@`-imported anywhere so it does not ride in per-session context; open it
on demand, close it when done.

## Quick decision tree

1. `ethos doctor` — is ethos healthy in this repo?
   - **Clean**: nothing to do. Move on.
   - **"Not enabled here"**: run `ethos enable` (below).
   - **"No global content"**: run `ethos seed` first (below).
   - **"No identity resolved"**: run `ethos setup` (below).

Seed, enable and setup below can be re-run to refresh integration/content.
The separately confirmed legacy repair is destructive, not a migration.

## `ethos seed` — populate global starter content (once per machine)

Deploys starter roles, talents, personalities, writing styles, and skills
into `~/.punt-labs/ethos/`. Also deploys review-checklist agents
(`code-reviewer`, `silent-failure-hunter`,
`invariant-completeness-reviewer`) to `.claude/agents/`.

```bash
ethos seed
```

Run once per machine. Repeat only after upgrading the ethos binary — new
versions may ship additional starter content.

## `ethos enable` — turn ethos on in the current repo

Deposits the vendored agent guide and its manifest, writes the enabled
marker, adds `@.punt-labs/ethos/CLAUDE.md` to the repo's top-level
`CLAUDE.md` (so agent sessions in this repo auto-load daily-use ethos
guidance), and chains the audit-seal and trailer git hooks.

```bash
ethos enable
```

After enable, restart Claude Code once so SessionStart fires with the new
hook configuration. `ethos disable` reverses this: it removes the import
line, deletes the marker, and unchains the git hooks. It is non-destructive:
the guide, config and audit data stay on disk. It refuses while a sibling
worktree is still enabled, because the git hooks are shared; `ethos disable
--force` unchains anyway.

## `ethos setup` — populate this repo's identities + team

Interactive wizard that writes to `.punt-labs/ethos/identities/`,
`.punt-labs/ethos/teams/`, `.punt-labs/ethos/roles/`, and
`.punt-labs/ethos.yaml`. Bundle choice affects which starter team the
wizard installs.

```bash
ethos setup                        # interactive, default bundle: foundation
ethos setup --solo                 # identity only, no team
ethos setup --bundle gstack        # use gstack starter bundle
ethos setup --file config.yaml     # non-interactive, from a config file
```

**Bundles:**

| Bundle | What it is | When to pick |
|---|---|---|
| `foundation` (default) | The general sidecar content seeded by `ethos seed` (all roles, all talents, all personalities available globally). No bundle-scoped subset — just uses everything already global. | Most repos. Default. |
| `gstack` | Small pre-composed starter team: `ceo`, `coo`, `architect`, `product-lead`, `implementer`, `reviewer`, `qa-engineer`, `security-reviewer`. Ships two pipelines: `gstack-plan` (design) and `gstack-ship` (implement). Tagline: "Boil the Lake, Search Before Building, User Sovereignty." | Repos starting greenfield with a small team and want a curated starter roster instead of building one from scratch. |

The wizard's identity graph and configuration are intended for Git — stage
and commit them explicitly so they are shared with the rest of the team.

## Storage policy (DES-079; acceptance pending)

DES-080 redaction shipped in v4.20.0. DES-079 storage-boundary behavior is a
required repair contract, not yet a verified release guarantee. See the
[storage and publication contract](https://github.com/punt-labs/ethos/blob/main/docs/storage-layout.md)
for paths and outstanding acceptance.

Resolve the canonical store root **S** through Git's common directory,
separately from the invoking checkout **C**. S owns shared source/blame records
under `S/.punt-labs/ethos/`. All repository-local live logs, retained archives,
overlays, locks, receipts, scratch and temporary staging belong under
`S/.punt-labs/local/ethos/`. C owns
generated agents, guide/marker/import deposits and publication/index effects.
In a normal checkout S = C; a linked feature checkout usually differs.

```yaml
# S/.punt-labs/ethos.yaml (alongside the existing identity/team settings)
record: blame   # default if omitted; full opts in prospectively
```

- Both modes retain local prompts, full reflections, mission events and
  session audits at S. Default blame sealing does not query or change the
  index. Full mode adds eligible published copies into C, including sealed
  session audits, without relocating the only local copy.
- Consent is captured per immutable entry. A mode switch neither promotes
  private older history nor deletes published history. Missing/legacy consent
  is private. Previously eligible pending copies remain retryable after a
  switch back to blame; the switch alone publishes nothing.
- Validate configuration once per request, including each long-lived MCP
  call. Invalid `record` values fail visibly; no fallback location is allowed.
- Re-enable maintains the shared local-zone exclusion, never mode-specific
  ignores inside `.punt-labs/ethos/`. Use ordinary staging for intended
  publication/export output, never force-add.
- All repository temporaries, including rollback and symlink-target staging,
  stay in S's local zone. Cross-filesystem rename/link refuses with the old
  target intact, without adjacent-temp or copy-over fallback.
- Removing a linked C distinct from S must retain prompts, reflections,
  chunks and unsealed tails without SessionEnd. Deleting S or its local data
  is not covered. Local retained history is not disposable scratch.
- Worker artifacts, including `MISSION_ARTIFACTS_DIR`, must target local
  scratch. Legacy misplaced agent-owned files require operator-directed
  cleanup; Ethos does not silently move, export or redact them.

### Bounded legacy repair

`ethos repair --dry-run` inventories known obsolete trace/runtime files without
deleting. Destructive `ethos repair` lists those files, warns that old prompts,
reflections, events/audit history and runtime residue will be permanently lost,
then asks `Are you sure? [y/N]` in a terminal. Empty input, no and EOF delete
nothing. `--yes` is explicit automation consent and an assertion that all old/new
writers, hooks and MCP servers are stopped; busy locks refuse cleanup. Windows
supports inventory, but destructive repair currently refuses: use a Unix host
with all writers stopped.

No backup, lossless migration, backfill, lifecycle change, Git staging/commit or
configuration rewrite is performed. Cleanup excludes shared identities,
contracts, results, corrections, provenance and ADRs, private credentials and
overlays, configuration, global data, arbitrary/agent-owned files and canonical
local history. Current publications and flat current exports
(`missions/<id>.contract.yaml` / `<id>.result.yaml`, with associated trace) are
retained, including incomplete/ambiguous exports. Other intentional publications
and exports are not blanket deletion targets. Historical shipped
`ethos mission migrate` / `ethos audit migrate` commands are not expanded into a
new storage-upgrade workflow.

Private legacy repository overlays require explicit operator handling: stop
writers, reconcile each old
`S/.punt-labs/ethos/identities/<handle>.ext/<ns>.local.yaml` into
`S/.punt-labs/local/ethos/identities/<handle>.ext/<ns>.local.yaml`, preserving all
credentials and resolving any existing destination before removing the old copy.
Do not overwrite divergent values, print credentials or write a merged identity
into the tracked base. Legacy siblings are read-only compatibility inputs;
local writes refuse while one remains and unequal copies refuse reads. Repair
does not move/delete overlays, and global overlay layout is unchanged.

Review the inventory before consenting. Deletions are incremental: after
interruption, inspect a fresh inventory and confirm again; no rollback is
promised. Old missions may need manual retirement; repair never invents shared
authority. Review tracked deletions and stage/commit normally. Then run
`ethos enable` to refresh repository integration and reconnect long-lived MCP
servers. Re-running enable alone is not evidence of final storage acceptance.

## Verify

```bash
ethos doctor       # should report no missing state
ethos whoami       # resolves your identity (session roster → git config → OS user)
ethos session      # current session roster (empty until `ethos iam <handle>` is called)
ls .claude/agents/ # regenerated agent files, one per team member with kind: agent
```

`ethos doctor` failures point at what to fix and how. Address one at a time,
re-run.

## After setup — declare identity per session

Every session where you want the persona block injected:

```bash
ethos iam <handle>          # e.g. ethos iam claude
```

Then restart Claude Code (or trigger the SessionStart hook manually). The
persona block appears as `additionalContext` on the first turn.

## The ethos-in-ethos exception

This file lives IN the ethos repo. In the ethos repo itself, the top-level
`CLAUDE.md` deliberately does NOT `@`-import `.punt-labs/ethos/CLAUDE.md`
— developer guidance for ethos is in `docs/development.md`, opened on
demand. Same for `.punt-labs/{vox,z-spec}/CLAUDE.md` — those are end-user
docs for their tools, not needed for developing ethos.

In every OTHER repo (biff, quarry, langlearn, etc.), `ethos enable`
DOES add the `@`-import so daily-use guidance auto-injects.

## Troubleshooting for the agent

- **`ethos doctor` reports "hook missing"** → run `ethos enable` (it
  chains the audit-seal and trailer git hooks again).
- **`ethos doctor` reports "stale binary version"** → the binary on PATH
  is older than the plugin. Ask the human to run `make install` from a
  shell (agent sessions cannot overwrite their own running binary on
  macOS).
- **Persona block not appearing** → SessionStart hook only fires at
  session start. Restart Claude Code. Also verify `ethos iam <handle>`
  was called for this session.
- **`.claude/agents/<handle>.md` regenerated with wrong content** → the
  source is `.punt-labs/ethos/identities/<handle>.yaml` +
  `.punt-labs/ethos/personalities/<slug>.md` +
  `.punt-labs/ethos/writing-styles/<slug>.md`. Edit the source, not the
  generated agent file.
- **Regen removes files** → it doesn't. Ethos generation adds/updates but
  never deletes. To remove a stale `.claude/agents/*.md`, first remove
  the identity from every team's roster, then `git rm` the file.
- **Uninstall** → `ethos disable` in each repo, then `ethos uninstall`
  (or `ethos uninstall --purge` to also remove `~/.punt-labs/ethos/`).
