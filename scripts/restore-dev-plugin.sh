#!/usr/bin/env bash
set -euo pipefail

# Restore dev plugin state on main after a release tag.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Repo-relative, because it is handed to git. The shippable surface lives under
# plugin/ so a git-subdir marketplace install fetches only that subtree.
PLUGIN_JSON="plugin/.claude-plugin/plugin.json"

# Require a clean working tree so we don't overwrite local changes.
if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or stash changes before restoring." >&2
  exit 1
fi

# Guard against double-run: if name already has -dev, nothing to restore.
current_name="$(PLUGIN_PATH="${REPO_ROOT}/${PLUGIN_JSON}" python3 -c "import json, os; print(json.load(open(os.environ['PLUGIN_PATH']))['name'])")"
if [[ "$current_name" == *-dev ]]; then
  echo "Plugin name is already '${current_name}' (already in dev state)" >&2
  exit 1
fi

# Optional argument: commit/tag to restore from (defaults to HEAD~1).
RESTORE_REF="${1:-HEAD~1}"
if ! git -C "$REPO_ROOT" rev-parse "$RESTORE_REF" >/dev/null 2>&1; then
  echo "Error: invalid ref to restore from: $RESTORE_REF" >&2
  exit 1
fi

# A ref from before the plugin/ move carries the surface at the repo root, so
# both pathspecs below match nothing and git aborts with a bare "did not match
# any file(s) known to git". Say which ref and why instead.
if ! git -C "$REPO_ROOT" ls-tree --name-only "$RESTORE_REF" -- "$PLUGIN_JSON" | grep -q .; then
  echo "Error: $RESTORE_REF has no $PLUGIN_JSON — it predates the move of the" >&2
  echo "       plugin surface into plugin/. Restore from a later ref, or check out" >&2
  echo "       .claude-plugin/plugin.json and commands/ from it by hand." >&2
  exit 1
fi

# Restore plugin.json and commands from the specified commit
git -C "$REPO_ROOT" checkout "$RESTORE_REF" -- "$PLUGIN_JSON" plugin/commands/
git -C "$REPO_ROOT" add "$PLUGIN_JSON" plugin/commands/
git -C "$REPO_ROOT" commit --no-verify -m "chore: restore dev plugin state"
