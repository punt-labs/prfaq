---
description: Grant prfaq the permissions it needs in this project — or check and revoke them
argument-hint: "[check|remove]"
allowed-tools: Bash(bash */prfaq_permissions.sh *), Bash(bash scripts/prfaq_permissions.sh *), Read
---

# Configure prfaq Permissions for This Project

Write prfaq's permission rules into this project's `.claude/settings.json` so
the plugin's commands stop asking for approval on every compile, edit, and
search. The rules apply to this project only — prfaq never writes to the
global `~/.claude/settings.json`.

## Steps

1. **Pick the mode.** Read `$ARGUMENTS`:
   - `check` (or `status`) — report which rules are present, change nothing
   - `remove` (or `revoke`, `off`) — take the rules back out
   - anything else, including empty — add the rules

2. **Confirm before writing.** For the add and remove modes, tell the user
   which file will change (`.claude/settings.json` in the current project) and
   that the file is normally committed, so the change is visible to everyone
   working in the repo. Ask before proceeding. Skip this for `check`.

3. **Run the script.**
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/prfaq_permissions.sh --add
   ```
   Substitute `--check` or `--remove` for the other modes. The script operates
   on the current working directory and is idempotent — running it twice adds
   nothing the second time and leaves the file byte-identical.

4. **Report the result.** Relay the script's output. When rules were added,
   tell the user two things:
   - Claude Code watches settings files, so the rules apply without a restart.
     Tell the user to restart only if they do not seem to have taken.
   - `.claude/settings.json` is checked into the repo, so committing it shares
     the permissions with the team. To keep them to themselves, they can move
     the block to `.claude/settings.local.json`, which is gitignored.

5. **If jq is missing.** The script requires `jq`. When it reports jq missing,
   tell the user to install it (`brew install jq` on macOS, `apt install jq`
   on Linux) and offer to add the rules by hand instead — read the rule list
   out of `${CLAUDE_PLUGIN_ROOT}/scripts/prfaq_permissions.sh` and write them
   into `.claude/settings.json` under `permissions.allow`.

## What Gets Granted

- **Bash** — the plugin's own compile and export scripts, `uuidgen`, and
  `mkdir -p meetings|research`. Nothing else.
- **Edit** — `*prfaq*.tex`, `*prfaq*.bib`, `press-release-*.tex`,
  `.claude/prfaq.local.md`, `meetings/**`, `research/**`, `README.md`,
  `.gitignore`. Path rules use the `Edit(...)` form, which covers the Write,
  Edit, and NotebookEdit tools. A `Write(...)` rule matches nothing.
- **WebSearch and WebFetch** — the researcher agent needs open web access;
  the sources it must reach cannot be enumerated in advance.
- **CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1** — required by
  `/prfaq:meeting-hive` for parallel persona execution.

Deliberately excluded: `Bash(curl *)` and every `Bash(rm *)` form. Sending
data to an external endpoint and deleting files stay at the prompt tier.
