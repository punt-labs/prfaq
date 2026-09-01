#!/usr/bin/env bash
set -euo pipefail

# Prepare plugin for release: swap name to prod, remove -dev commands.
# The tagged commit has only prod artifacts; the marketplace cache clones from it.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Repo-relative, because both are handed to git. The shippable surface lives
# under plugin/ so a git-subdir marketplace install fetches only that subtree.
PLUGIN_JSON="plugin/.claude-plugin/plugin.json"
COMMANDS_DIR="plugin/commands"

# Require a clean working tree so we don't accidentally stage local changes.
if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

# Swap plugin name from *-dev to prod
current_name="$(PLUGIN_PATH="${REPO_ROOT}/${PLUGIN_JSON}" python3 -c "import json, os; print(json.load(open(os.environ['PLUGIN_PATH']))['name'])")"
prod_name="${current_name%-dev}"

if [[ "$current_name" == "$prod_name" ]]; then
  echo "Plugin name is already '${prod_name}' (no -dev suffix)" >&2
  exit 1
fi

echo "Swapping plugin name: ${current_name} → ${prod_name}"
PLUGIN_PATH="${REPO_ROOT}/${PLUGIN_JSON}" PROD_NAME="$prod_name" python3 -c "
import json, pathlib, os
p = pathlib.Path(os.environ['PLUGIN_PATH'])
d = json.loads(p.read_text(encoding='utf-8'))
d['name'] = os.environ['PROD_NAME']
p.write_text(json.dumps(d, indent=2) + '\n', encoding='utf-8')
"

git -C "$REPO_ROOT" add "$PLUGIN_JSON"

# A missing COMMANDS_DIR must not be survivable. find's failure used to be
# swallowed by `2>/dev/null || true`, which reads as "no -dev commands to
# remove" — indistinguishable from a path that is simply wrong. Since the move
# to plugin/ this path is load-bearing: a typo would sail through and produce a
# release tag that still ships every *-dev command.
if [[ ! -d "${REPO_ROOT}/${COMMANDS_DIR}" ]]; then
  echo "Error: ${COMMANDS_DIR} not found under ${REPO_ROOT}." >&2
  echo "       COMMANDS_DIR must name the shipped commands directory; it is" >&2
  echo "       where this script looks for *-dev.md files to strip." >&2
  exit 1
fi

# Remove -dev commands if any exist (repo-relative paths for git).
# REPO_ROOT is quoted inside the ${..} because an unquoted expansion there is
# read as a pattern: a checkout under a path holding [ ? or * would strip
# nothing and hand git an absolute path.
dev_files=()
while IFS= read -r -d '' f; do
  dev_files+=("${f#"${REPO_ROOT}"/}")
done < <(find "${REPO_ROOT}/${COMMANDS_DIR}" -name '*-dev.md' -print0)

if [[ ${#dev_files[@]} -gt 0 ]]; then
  for f in "${dev_files[@]}"; do
    echo "Removing: $f"
  done
  git -C "$REPO_ROOT" rm "${dev_files[@]}"
fi

git -C "$REPO_ROOT" commit --no-verify -m "chore: prepare plugin for release"
