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

Each command below is idempotent. Re-running upgrades in place; it does not
overwrite state you have already committed.

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

Writes the `.punt-labs/ethos` tracking marker, adds
`@.punt-labs/ethos/CLAUDE.md` to the repo's top-level `CLAUDE.md` (so agent
sessions in this repo auto-load daily-use ethos guidance), and registers
the SessionStart / PreCompact / pre-commit hooks in `.claude/settings.json`.

```bash
ethos enable
```

After enable, restart Claude Code once so SessionStart fires with the new
hook configuration. `ethos disable` reverses this; `ethos disable --purge`
also removes the `.punt-labs/ethos/` subtree.

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

Everything the wizard writes is git-tracked — commit these so the identity
graph is shared with the rest of the team.

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
  registers all hooks in `.claude/settings.json`).
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
