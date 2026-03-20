#!/usr/bin/env bash
set -euo pipefail

# Prepare plugin for release: swap name to prod, remove -dev commands.
# The tagged commit has only prod artifacts; the marketplace cache clones from it.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON=".claude-plugin/plugin.json"
COMMANDS_DIR="commands"

# Swap plugin name from *-dev to prod
current_name="$(python3 -c "import json; print(json.load(open('${REPO_ROOT}/${PLUGIN_JSON}'))['name'])")"
prod_name="${current_name%-dev}"

if [[ "$current_name" == "$prod_name" ]]; then
  echo "Plugin name is already '${prod_name}' (no -dev suffix)" >&2
  exit 1
fi

echo "Swapping plugin name: ${current_name} → ${prod_name}"
python3 -c "
import json, pathlib
p = pathlib.Path('${REPO_ROOT}/${PLUGIN_JSON}')
d = json.loads(p.read_text())
d['name'] = '${prod_name}'
p.write_text(json.dumps(d, indent=2) + '\n')
"

git -C "$REPO_ROOT" add "$PLUGIN_JSON"

# Remove -dev commands if any exist
dev_files=()
while IFS= read -r -d '' f; do
  dev_files+=("${COMMANDS_DIR}/$(basename "$f")")
done < <(find "${REPO_ROOT}/${COMMANDS_DIR}" -name '*-dev.md' -print0 2>/dev/null || true)

if [[ ${#dev_files[@]} -gt 0 ]]; then
  for f in "${dev_files[@]}"; do
    echo "Removing: $(basename "$f")"
  done
  git -C "$REPO_ROOT" rm "${dev_files[@]}"
fi

git -C "$REPO_ROOT" commit --no-verify -m "chore: prepare plugin for release [skip ci]"
