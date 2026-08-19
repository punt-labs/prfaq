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

COMMANDS_DIR="plugin/commands"

# git checkout aborts if *any* pathspec matches nothing, so probe every one it
# will be given — not just the first. A ref from before the plugin/ move
# carries the surface at the repo root and matches neither, and an odd
# intermediate ref could carry one without the other; either way git says only
# "did not match any file(s) known to git". Name the ref and the paths instead.
missing=()
for path in "$PLUGIN_JSON" "$COMMANDS_DIR"; do
  if ! git -C "$REPO_ROOT" ls-tree --name-only "$RESTORE_REF" -- "$path" | grep -q .; then
    missing+=("$path")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Error: $RESTORE_REF does not contain: ${missing[*]}" >&2
  echo "       A ref from before the plugin/ move has the surface at the repo" >&2
  echo "       root instead. Restore from a later ref, or check out" >&2
  echo "       .claude-plugin/plugin.json and commands/ from it by hand." >&2
  exit 1
fi

# Restore plugin.json and commands from the specified commit
git -C "$REPO_ROOT" checkout "$RESTORE_REF" -- "$PLUGIN_JSON" "$COMMANDS_DIR"
git -C "$REPO_ROOT" add "$PLUGIN_JSON" "$COMMANDS_DIR"
git -C "$REPO_ROOT" commit --no-verify -m "chore: restore dev plugin state"
