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
#
# CLAUDE_STUB_MARKETPLACES picks what `marketplace list` prints, so the
# registration branches can be exercised. The default mimics the real
# formatting: name on its own line, source repo on the next.
cat > "$WORK/bin/claude" <<'STUB'
#!/bin/sh
[ -n "${CLAUDE_STUB_LOG:-}" ] && echo "$*" >> "$CLAUDE_STUB_LOG"
case "$*" in
  "plugin marketplace list")
    case "${CLAUDE_STUB_MARKETPLACES:-registered}" in
      registered)
        printf 'Configured marketplaces:\n\n  \xe2\x9d\xaf punt-labs\n    Source: GitHub (punt-labs/claude-plugins)\n'
        ;;
      decoy)
        # Someone else's marketplace whose source repo merely contains our
        # name. Ours is not registered.
        printf 'Configured marketplaces:\n\n  \xe2\x9d\xaf someone-else\n    Source: GitHub (mirrors/punt-labs-fork)\n'
        ;;
      unlisted)
        # Registered, but under formatting the name-field check cannot read —
        # stands in for a future CLI that changes its output.
        printf 'Configured marketplaces:\n\n  1. punt-labs (GitHub: punt-labs/claude-plugins) [enabled]\n'
        ;;
      none)
        printf 'Configured marketplaces:\n\n'
        ;;
    esac
    ;;
  "plugin marketplace add"*)
    # Adding an already-registered marketplace fails.
    [ "${CLAUDE_STUB_MARKETPLACES:-registered}" = "unlisted" ] && exit 1
    exit 0
    ;;
  "plugin list") echo "prfaq@punt-labs" ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$WORK/bin/claude"

run_installer() { # run_installer <fake-home> [marketplace-stub-mode]
  rm -f "$WORK/claude-calls.log"
  env HOME="$1" PATH="$WORK/bin:$PATH" CLAUDE_STUB_MARKETPLACES="${2:-registered}" \
    CLAUDE_STUB_LOG="$WORK/claude-calls.log" \
    sh "$REPO/install.sh" >"$WORK/installer.out" 2>&1
}

refreshed() { grep -q "^plugin marketplace update punt-labs$" "$WORK/claude-calls.log"; }

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

# --- Keys of the right name but the wrong type ---
# These parse as JSON and then die inside jq mid-query. The script must name
# the offending key rather than emit a raw jq stack trace, and must not treat
# a user's typo as an empty list.
for BAD_KEY in 'permissions' 'permissions.allow' 'env'; do
  case "$BAD_KEY" in
    permissions)       BAD_JSON='{"permissions":"nope"}' ;;
    permissions.allow) BAD_JSON='{"permissions":{"allow":"nope"}}' ;;
    env)               BAD_JSON='{"env":"nope"}' ;;
  esac
  P="$WORK/malformed-$(printf '%s' "$BAD_KEY" | tr '.' '-')"
  mkdir -p "$P/.claude"
  printf '%s' "$BAD_JSON" > "$P/.claude/settings.json"
  for MODE in --check --add --remove; do
    STATUS=0
    OUT=$(sh "$PERMS" "$MODE" "$P" 2>&1) || STATUS=$?
    check "$MODE on a malformed \"$BAD_KEY\" key exits 1" "1" "$STATUS"
    case "$OUT" in
      *"jq: error"*) fail "$MODE on \"$BAD_KEY\" leaked a jq stack trace" ;;
      *"$BAD_KEY"*)  pass "$MODE on \"$BAD_KEY\" names the offending key" ;;
      *)             fail "$MODE on \"$BAD_KEY\" does not name the offending key — got [$OUT]" ;;
    esac
  done
  check "malformed \"$BAD_KEY\" file is left alone" "$BAD_JSON" "$(cat "$P/.claude/settings.json")"
done

# --- The global settings file is off limits ---
# Run against a fake HOME: if the guard ever regresses, this test must not
# rewrite the developer's own ~/.claude/settings.json.
FAKE_HOME="$WORK/guard-home"
mkdir -p "$FAKE_HOME"
STATUS=0
env HOME="$FAKE_HOME" sh "$PERMS" --add "$FAKE_HOME" >/dev/null 2>&1 || STATUS=$?
check "writing \$HOME is refused" "1" "$STATUS"

ln -s "$FAKE_HOME" "$WORK/guard-home-link"
STATUS=0
env HOME="$FAKE_HOME" sh "$PERMS" --add "$WORK/guard-home-link" >/dev/null 2>&1 || STATUS=$?
check "writing \$HOME through a symlink is refused" "1" "$STATUS"
check "the guard wrote nothing" "0" "$(find "$FAKE_HOME" -name settings.json | wc -l | tr -d ' ')"

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

# --- A malformed global settings file must not abort the install ---
# install.sh is piped from curl. A hard exit here strands the user after the
# plugin installed but before the toolchain checks and the closing message.
H="$WORK/home-malformed-allow"
mkdir -p "$H/.claude"
printf '{"permissions":{"allow":"nope"}}' > "$H/.claude/settings.json"
STATUS=0
run_installer "$H" || STATUS=$?
check "malformed global permissions.allow does not abort the install" "0" "$STATUS"
check "malformed global settings is left alone" '{"permissions":{"allow":"nope"}}' "$(cat "$H/.claude/settings.json")"
if grep -q "jq: error" "$WORK/installer.out"; then
  fail "installer leaked a jq stack trace on a malformed settings file"
else
  pass "installer leaks no jq stack trace on a malformed settings file"
fi
if grep -q "is ready!" "$WORK/installer.out"; then
  pass "installer still reaches its closing message"
else
  fail "installer still reaches its closing message"
fi

# --- No global settings file at all ---
H="$WORK/home-empty"
mkdir -p "$H"
STATUS=0
run_installer "$H" || STATUS=$?
check "missing global settings file is fine" "0" "$STATUS"

printf '\nMarketplace registration (install.sh)\n'

H="$WORK/home-marketplace"
mkdir -p "$H"

run_installer "$H" registered
if grep -q "marketplace already registered" "$WORK/installer.out"; then
  pass "a registered marketplace is recognized by name"
else
  fail "a registered marketplace is recognized by name"
fi
if refreshed; then
  pass "a registered marketplace is refreshed"
else
  fail "a registered marketplace is refreshed"
fi

# Registered, but the name-field read misses it, so the installer tries to add
# and the add fails. It must recover — and still refresh, or the install
# silently resolves against whatever ref was cached last time.
run_installer "$H" unlisted
if grep -q "marketplace already registered" "$WORK/installer.out"; then
  pass "an unreadable listing recovers via the add fallback"
else
  fail "an unreadable listing recovers via the add fallback"
fi
if refreshed; then
  pass "the add fallback still refreshes the marketplace"
else
  fail "the add fallback still refreshes the marketplace"
fi

# Another marketplace whose source repo contains our name must not be mistaken
# for ours — that would skip registration and fail at install time.
run_installer "$H" decoy
if grep -q "marketplace registered" "$WORK/installer.out" && ! grep -q "already registered" "$WORK/installer.out"; then
  pass "a decoy marketplace does not suppress registration"
else
  fail "a decoy marketplace does not suppress registration"
fi

STATUS=0
run_installer "$H" none || STATUS=$?
check "an empty marketplace list registers cleanly" "0" "$STATUS"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
