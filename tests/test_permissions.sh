#!/bin/sh
# Tests for the permission scripts: scripts/prfaq_permissions.sh (project
# rules) and install.sh Step 5 (legacy global cleanup).
#
# Both scripts edit a user's Claude Code settings file, so the cases that
# matter are the destructive ones: rules the user wrote must survive, a
# no-op must not rewrite the file, and a successful run must exit 0.
#
# Usage: sh tests/test_permissions.sh
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
WORK="$REPO/.tmp/permission-tests"
PERMS="$REPO/scripts/prfaq_permissions.sh"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1 — expected [$2], got [$3]"
  fi
}

command -v jq >/dev/null 2>&1 || { printf 'jq is required to run these tests\n' >&2; exit 1; }

rm -rf "$WORK"
mkdir -p "$WORK"

# A stub `claude` so install.sh can run its plugin steps offline.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'STUB'
#!/bin/sh
case "$*" in
  "plugin marketplace list") echo "punt-labs" ;;
  "plugin list") echo "prfaq@punt-labs" ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$WORK/bin/claude"

run_installer() { # run_installer <fake-home>
  env HOME="$1" PATH="$WORK/bin:$PATH" sh "$REPO/install.sh" >"$WORK/installer.out" 2>&1
}

printf '\nProject permissions (scripts/prfaq_permissions.sh)\n'

# --- Fresh project ---
P="$WORK/fresh"
mkdir -p "$P"
sh "$PERMS" --add "$P" >/dev/null
check "fresh add writes every rule" "19" "$(jq '.permissions.allow | length' "$P/.claude/settings.json")"
check "fresh add enables agent teams" "1" "$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$P/.claude/settings.json")"
check "fresh add writes no Write() rule" "0" "$(jq '[.permissions.allow[] | select(startswith("Write("))] | length' "$P/.claude/settings.json")"

# --- Idempotence: a no-op must not touch the file ---
BEFORE=$(cksum < "$P/.claude/settings.json")
sh "$PERMS" --add "$P" >/dev/null
check "second add leaves the file byte-identical" "$BEFORE" "$(cksum < "$P/.claude/settings.json")"
sh "$PERMS" --add "$P" >/dev/null
check "no-op add exits 0" "0" "$?"

# --- Check mode ---
sh "$PERMS" --check "$P" >/dev/null
check "check on a complete project exits 0" "0" "$?"

# --- Remove ---
sh "$PERMS" --remove "$P" >/dev/null
check "remove takes every rule back out" "0" "$(jq '.permissions.allow | length' "$P/.claude/settings.json")"
check "remove leaves the env var alone" "1" "$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$P/.claude/settings.json")"

# --- Merging into a settings file the user already owns ---
P="$WORK/existing"
mkdir -p "$P/.claude"
jq -n '{permissions:{allow:["Bash(git:*)","WebSearch"],deny:["Bash(rm:*)"]},env:{FOO:"bar"}}' > "$P/.claude/settings.json"
sh "$PERMS" --add "$P" >/dev/null
check "user rules keep their position" "Bash(git:*)" "$(jq -r '.permissions.allow[0]' "$P/.claude/settings.json")"
check "an overlapping rule is not duplicated" "1" "$(jq '[.permissions.allow[] | select(. == "WebSearch")] | length' "$P/.claude/settings.json")"
check "deny list survives" "Bash(rm:*)" "$(jq -r '.permissions.deny[0]' "$P/.claude/settings.json")"
check "unrelated env survives" "bar" "$(jq -r '.env.FOO' "$P/.claude/settings.json")"

# --- Settings file that is valid JSON but not an object ---
P="$WORK/notanobject"
mkdir -p "$P/.claude"
printf '[1,2,3]' > "$P/.claude/settings.json"
STATUS=0
sh "$PERMS" --add "$P" >/dev/null 2>&1 || STATUS=$?
check "non-object settings file is refused" "1" "$STATUS"
check "non-object settings file is left alone" "[1,2,3]" "$(cat "$P/.claude/settings.json")"

# --- The global settings file is off limits ---
STATUS=0
sh "$PERMS" --add "$HOME" >/dev/null 2>&1 || STATUS=$?
check "writing \$HOME is refused" "1" "$STATUS"

printf '\nLegacy global cleanup (install.sh)\n'

# --- Cleanup removes prfaq's rules and nothing else ---
H="$WORK/home-with-legacy"
mkdir -p "$H/.claude"
jq -n '{permissions:{allow:["Bash(git:*)","Write(*prfaq*.tex)","Write(meetings/**)","Edit(*prfaq*.tex)","WebSearch","Read"],deny:["Bash(sudo:*)"]},env:{FOO:"bar"}}' > "$H/.claude/settings.json"
STATUS=0
run_installer "$H" || STATUS=$?
check "installer exits 0 after cleanup" "0" "$STATUS"
check "legacy rules are gone" "0" "$(jq '[.permissions.allow[] | select(startswith("Write("))] | length' "$H/.claude/settings.json")"
check "user rules survive" "Bash(git:*) Read" "$(jq -r '.permissions.allow | join(" ")' "$H/.claude/settings.json")"
check "deny list survives cleanup" "Bash(sudo:*)" "$(jq -r '.permissions.deny[0]' "$H/.claude/settings.json")"
check "a backup is left behind" "1" "$(find "$H/.claude" -name 'settings.json.prfaq-backup.*' | wc -l | tr -d ' ')"
check "no temp file is left behind" "0" "$(find "$H/.claude" -name 'settings.json.tmp' | wc -l | tr -d ' ')"

# --- Second run has nothing to do ---
STATUS=0
run_installer "$H" || STATUS=$?
check "second installer run exits 0" "0" "$STATUS"
if grep -q "no legacy global rules found" "$WORK/installer.out"; then
  pass "second installer run reports nothing to clean"
else
  fail "second installer run reports nothing to clean"
fi

# --- A global settings file that is not an object must not abort the install ---
H="$WORK/home-not-an-object"
mkdir -p "$H/.claude"
printf '["not","an","object"]' > "$H/.claude/settings.json"
STATUS=0
run_installer "$H" || STATUS=$?
check "non-object global settings does not abort the install" "0" "$STATUS"
check "non-object global settings is left alone" '["not","an","object"]' "$(cat "$H/.claude/settings.json")"

# --- No global settings file at all ---
H="$WORK/home-empty"
mkdir -p "$H"
STATUS=0
run_installer "$H" || STATUS=$?
check "missing global settings file is fine" "0" "$STATUS"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
