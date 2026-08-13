#!/bin/sh
# Grant prfaq the permissions it needs — in one project, never globally.
#
# Usage:
#   prfaq_permissions.sh [--add|--remove|--check] [project-dir]
#
#   --add     (default) add prfaq's rules to <project-dir>/.claude/settings.json
#   --remove  take them back out
#   --check   report what is present and what is missing; change nothing
#
# The file written is the project's own settings file, checked into the
# project repo. prfaq never writes to ~/.claude/settings.json: rules there
# apply in every project the user opens, including projects that have nothing
# to do with prfaq.
set -eu

# --- Colors (disabled when not a terminal) ---
if [ -t 1 ]; then
  BOLD='\033[1m' GREEN='\033[32m' YELLOW='\033[33m' NC='\033[0m'
else
  BOLD='' GREEN='' YELLOW='' NC=''
fi

info() { printf '%b▶%b %s\n' "$BOLD" "$NC" "$1"; }
ok()   { printf '  %b✓%b %s\n' "$GREEN" "$NC" "$1"; }
warn() { printf '  %b!%b %s\n' "$YELLOW" "$NC" "$1"; }
fail() { printf '  %b✗%b %s\n' "$YELLOW" "$NC" "$1" >&2; exit 1; }

# Permission rules prfaq's commands and skills need to run without a prompt
# on every step.
#
# Path patterns use the Edit(path) form only. Claude Code matches path-scoped
# rules under Edit, which covers the Write, Edit, and NotebookEdit tools; a
# Write(path) rule matches nothing and earns a warning at every session start.
#
# Deliberately excluded: Bash(curl *) and every Bash(rm *) form. Sending data
# to an external endpoint and deleting files stay at the prompt tier.
PRFAQ_PROJECT_RULES='[
  "Bash(bash */compile_prfaq.sh *)",
  "Bash(bash scripts/compile_prfaq.sh *)",
  "Bash(bash */export_prfaq_docx.sh *)",
  "Bash(bash scripts/export_prfaq_docx.sh *)",
  "Bash(bash */generate_reference_docx.sh *)",
  "Bash(bash scripts/generate_reference_docx.sh *)",
  "Bash(uuidgen)",
  "Bash(mkdir -p meetings)",
  "Bash(mkdir -p research)",
  "Edit(*prfaq*.tex)",
  "Edit(*prfaq*.bib)",
  "Edit(press-release-*.tex)",
  "Edit(.claude/prfaq.local.md)",
  "Edit(meetings/**)",
  "Edit(research/**)",
  "Edit(README.md)",
  "Edit(.gitignore)",
  "WebSearch",
  "WebFetch"
]'

# --- Arguments ---

MODE=add
PROJECT_ARG=''

for arg in "$@"; do
  case "$arg" in
    --add)    MODE=add ;;
    --remove) MODE=remove ;;
    --check)  MODE=check ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) fail "Unknown option: $arg" ;;
    *)
      [ -n "$PROJECT_ARG" ] && fail "Only one project directory may be given"
      PROJECT_ARG="$arg"
      ;;
  esac
done

[ -n "$PROJECT_ARG" ] || PROJECT_ARG=.
[ -d "$PROJECT_ARG" ] || fail "Not a directory: $PROJECT_ARG"
PROJECT_DIR=$(cd "$PROJECT_ARG" && pwd)

command -v jq >/dev/null 2>&1 || fail "jq is required. Install it: brew install jq (macOS) or apt install jq (Linux)"

SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"

# prfaq's own invariant: this script writes project settings, never the global
# file. A user running it from $HOME would otherwise recreate the exact problem
# this script exists to undo.
if [ "$PROJECT_DIR" = "$HOME" ]; then
  fail "Refusing to write $SETTINGS_FILE — that is the global settings file. Run this inside a project directory."
fi

# --- Load current state ---

if [ -f "$SETTINGS_FILE" ]; then
  jq -e 'type == "object"' "$SETTINGS_FILE" >/dev/null 2>&1 || fail "$SETTINGS_FILE is not a JSON object. Fix or move it, then re-run."
elif [ "$MODE" = "remove" ]; then
  fail "No $SETTINGS_FILE — nothing to remove."
fi

read_settings() {
  if [ -f "$SETTINGS_FILE" ]; then
    cat "$SETTINGS_FILE"
  else
    printf '{}'
  fi
}

PRESENT=$(read_settings | jq -r --argjson rules "$PRFAQ_PROJECT_RULES" '
  [(.permissions.allow? // [])[] | select(. as $r | $rules | index($r))] | length
')
TOTAL=$(printf '%s' "$PRFAQ_PROJECT_RULES" | jq -r 'length')
ADDED=$((TOTAL - PRESENT))
TEAMS=$(read_settings | jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // "unset"')

# --- Check ---

if [ "$MODE" = "check" ]; then
  info "prfaq permissions in $SETTINGS_FILE"
  if [ "$PRESENT" -eq "$TOTAL" ]; then
    ok "all $TOTAL rule(s) present"
  else
    warn "$PRESENT of $TOTAL rule(s) present — missing:"
    read_settings | jq -r --argjson rules "$PRFAQ_PROJECT_RULES" '
      (.permissions.allow? // []) as $have
      | $rules[] | select(. as $r | $have | index($r) | not) | "      " + .
    '
  fi
  if [ "$TEAMS" = "1" ]; then
    ok "agent teams enabled (/prfaq:meeting-hive available)"
  else
    warn "agent teams not enabled — /prfaq:meeting-hive needs CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
  fi
  exit 0
fi

# --- Write ---

# Nothing to do is a valid outcome, and it must leave the file — and the
# project's git status — untouched.
if [ "$MODE" = "add" ] && [ "$ADDED" -eq 0 ] && [ "$TEAMS" = "1" ]; then
  info "prfaq permissions for $PROJECT_DIR"
  ok "all $TOTAL rule(s) already present — no change"
  exit 0
fi
if [ "$MODE" = "remove" ] && [ "$PRESENT" -eq 0 ]; then
  info "prfaq permissions for $PROJECT_DIR"
  ok "no prfaq rules present — no change"
  exit 0
fi

# One backup, overwritten on each change: a timestamped series would pile up
# inside the project the user is about to commit.
if [ -f "$SETTINGS_FILE" ]; then
  BACKUP="${SETTINGS_FILE}.prfaq-backup"
  cp "$SETTINGS_FILE" "$BACKUP" || fail "Could not back up $SETTINGS_FILE"
else
  BACKUP=''
  mkdir -p "$(dirname "$SETTINGS_FILE")"
fi

TMP="${SETTINGS_FILE}.prfaq-tmp"
cleanup_tmp() { rm -f "$TMP"; }
trap cleanup_tmp EXIT INT TERM

if [ "$MODE" = "add" ]; then
  # Order-preserving: existing rules keep their position, new ones append.
  read_settings | jq --argjson rules "$PRFAQ_PROJECT_RULES" '
    (.permissions.allow? // []) as $have
    | .permissions.allow = $have + [$rules[] | select(. as $r | $have | index($r) | not)]
    | .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
  ' > "$TMP" || fail "Could not update $SETTINGS_FILE"
  mv "$TMP" "$SETTINGS_FILE" || fail "Could not replace $SETTINGS_FILE"

  info "prfaq permissions for $PROJECT_DIR"
  if [ "$ADDED" -gt 0 ]; then
    ok "$ADDED rule(s) added to .claude/settings.json"
  else
    ok "all $TOTAL rule(s) were already present"
  fi
  ok "agent teams enabled (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)"
  [ -n "$BACKUP" ] && ok "backup saved to $BACKUP"
  printf '\n'
  info "These rules apply in this project only. Commit the file to share them."
  info "Restart Claude Code for them to take effect."
  printf '\n'
else
  read_settings | jq --argjson rules "$PRFAQ_PROJECT_RULES" '
    .permissions.allow = [(.permissions.allow? // [])[] | select(. as $r | $rules | index($r) | not)]
  ' > "$TMP" || fail "Could not update $SETTINGS_FILE"
  mv "$TMP" "$SETTINGS_FILE" || fail "Could not replace $SETTINGS_FILE"

  info "prfaq permissions for $PROJECT_DIR"
  ok "$PRESENT rule(s) removed from .claude/settings.json"
  [ -n "$BACKUP" ] && ok "backup saved to $BACKUP"
  printf '\n'
  warn "Generic rules went too — WebSearch, WebFetch, Bash(uuidgen), and Edit of"
  warn "README.md and .gitignore. If you use those outside prfaq, restore them"
  warn "from the backup."
  warn "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS was left as it is — other tools may rely on it."
  printf '\n'
fi
