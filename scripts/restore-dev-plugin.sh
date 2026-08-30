#!/usr/bin/env bash
set -euo pipefail

# Restore dev plugin state on main after a release tag. Mirrors
# release-plugin.sh's swap exactly, in reverse: a targeted rewrite of the
# `name` field, nothing else. It does not check out plugin.json from a
# historical ref — main can go an arbitrary number of commits between
# releases without ever holding the dev name (e.g. if a prior release
# skipped this script), and a ref-based restore has no correct commit to
# point at in that case. Operating on the current working-tree content
# instead makes the restore correct regardless of how main got here.

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

dev_name="${current_name}-dev"
echo "Restoring plugin name: ${current_name} → ${dev_name}"
PLUGIN_PATH="${REPO_ROOT}/${PLUGIN_JSON}" DEV_NAME="$dev_name" python3 -c "
import json, pathlib, os
p = pathlib.Path(os.environ['PLUGIN_PATH'])
d = json.loads(p.read_text())
d['name'] = os.environ['DEV_NAME']
p.write_text(json.dumps(d, indent=2) + '\n')
"

git -C "$REPO_ROOT" add "$PLUGIN_JSON"
git -C "$REPO_ROOT" commit --no-verify -m "chore: restore dev plugin state"
