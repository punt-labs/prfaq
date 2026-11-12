# Beads (this repo)

Linear is the tracker of record for prfaq: the Punt Labs team (key `PL`),
issues labelled `repo:prfaq`. **bd** (beads) is a read-mostly local mirror
of those issues in the punt-labs central Hosted DoltDB instance. There is
**no per-repo issue store** — all beads live in one shared database,
distinguished by this repo's `issue-prefix` (set in `.beads/config.yaml`,
mirrored in `.beads/metadata.json`). The operating rules are in
`.punt-labs/punt/CLAUDE.md`.

## Source of truth

- Issues live in Linear; every mirrored bead stores its Linear URL in
  `external_ref`. The mirror is central Hosted DoltDB
  (`punt-labs-beads-1.dbs.hosted.doltdb.com`).
- `.beads/metadata.json` holds the connection mode + this repo's
  `issue_prefix`.
- `.beads/config.yaml` scopes `bd linear sync --pull` to this repo:
  `linear.pull_label` selects the issues, and `issue-prefix` names the
  beads a pull creates. For the prefix, `bd` reads the `BD_ISSUE_PREFIX`
  environment variable when set, else this `issue-prefix`, else the
  `metadata.json` value; keep the two files equal. Every pull resolves the
  prefix the same way, a by-id pull included; `bd linear sync --pull
  --issues` takes Linear identifiers (`PL-123`) because that is what it
  asks Linear for, and the beads it creates still carry this prefix.
- `.beads/issues.jsonl` and `.beads/interactions.jsonl` are local
  export views. Auto-export is disabled (`export.auto: false`);
  run `bd export` manually if needed. They are **gitignored** and
  not authoritative.
- `.beads/embeddeddolt/`, `backup/`, etc. are unused in server mode and
  gitignored.

## Connection

Connection details (host, port, user, password, TLS) come from the
org-root `.envrc` plus `~/.config/beads/server.json`. Cross-platform
secret retrieval via `security` (macOS Keychain) or `pass` (Linux GPG
password store). See punt-labs/`.envrc` for the canonical setup.

## Daily commands

```bash
bd linear sync --pull-if-stale --relations --team c1dfbb2c-985e-40cf-b004-5127646efc9d
                      # refresh the mirror from Linear (needs LINEAR_API_KEY)
bd list --label-any repo:prfaq
                      # issues for THIS repo (the shared DB holds every repo)
bd ready --label-any repo:prfaq --exclude-label deferred
                      # pick ready work
```

Create, claim, finish and cancel issues in Linear, not in beads: the next
pull skips a locally edited bead and a later one overwrites it, status
included. A new issue needs the `repo:prfaq` label plus a type label
(`Bug`, `Feature`, `Improvement`, `Epic`); a pull imports only issues
carrying the repo label. A pull with `--relations` adds `blocks` edges and
no pull removes one: a blocker added in Linear also needs `bd dep add
<bead> <blocker>` here when the mirror was refreshed without `--relations`,
and a blocker cleared in Linear needs `bd dep remove <bead> <blocker>`.
The guide's "Never" list applies here in full: no bare `bd linear sync`, no
unscoped `--push`, no `bd config set linear.*` (shared by every repo), and
never remove
`issue-prefix` or `linear.pull_label` from `config.yaml`. A pull is a beads
write: `bd` reads the `config.yaml` of the checkout it runs in, so before
running one, `bd config get linear.pull_label` there must print
`repo:prfaq`, or the pull imports the whole Punt Labs team.

## bd version

This repo needs `bd` built from the punt-labs fork, branch
`factory-fixes`, at or after punt-labs/beads#8 (commit `769f8a1`).
Build it from the meta-repo with `.bin/install-bd.sh install`, which
clones the fork into `.tmp/beads-fork/` and installs `~/.local/bin/bd`.

Upstream `bd` and fork builds before punt-labs/beads#7 ignore
`linear.pull_label`, so their `bd linear sync --pull` turns other repos'
Linear issues into `prfaq-*` beads; builds from #7 up to #8 honour the
label but let a bulk pull refresh other repos' linked beads. Before
pulling, take the commit `bd version` prints (the branch name beside it is
the current directory's, not the fork's) and confirm it is at or after
`769f8a1` with `git merge-base --is-ancestor 769f8a1 <that commit>` in
the fork clone; if it is not, rebuild.

Upstream bd: <https://github.com/gastownhall/beads>
