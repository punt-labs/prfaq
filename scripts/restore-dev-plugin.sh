#!/usr/bin/env bash
set -euo pipefail

# Restore dev plugin state on main after a release tag.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Restore plugin.json and commands from the commit before release prep
git -C "$REPO_ROOT" checkout HEAD~1 -- .claude-plugin/plugin.json commands/
git -C "$REPO_ROOT" add .claude-plugin/plugin.json commands/
git -C "$REPO_ROOT" commit --no-verify -m "chore: restore dev plugin state"
