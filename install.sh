#!/bin/sh
# Install prfaq — Working Backwards PR/FAQ process for Claude Code.
# Usage: curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/<SHA>/install.sh | sh
#
# The plugin generates .tex files. PDF compilation requires a TeX distribution
# (MacTeX, TeX Live). The installer checks for pdflatex and biber but does not
# install them automatically — see the output for instructions if they're missing.
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
fail() { printf '  %b✗%b %s\n' "$YELLOW" "$NC" "$1"; exit 1; }

MARKETPLACE_REPO="punt-labs/claude-plugins"
MARKETPLACE_NAME="punt-labs"
PLUGIN_NAME="prfaq"

# --- Step 1: Prerequisites ---

info "Checking prerequisites..."

if command -v claude >/dev/null 2>&1; then
  ok "claude CLI found"
else
  fail "'claude' CLI not found. Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
fi

if command -v git >/dev/null 2>&1; then
  ok "git found"
else
  fail "'git' not found. Install git first: https://git-scm.com/downloads"
fi

# --- Step 2: Register marketplace ---

info "Registering Punt Labs marketplace..."

if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
  ok "marketplace already registered"
  claude plugin marketplace update "$MARKETPLACE_NAME" 2>/dev/null || true
else
  claude plugin marketplace add "$MARKETPLACE_REPO" || fail "Failed to register marketplace"
  ok "marketplace registered"
fi

# --- Step 3: SSH fallback for plugin install ---

# claude plugin install clones via SSH (git@github.com:...).
# Users without SSH keys need an HTTPS fallback.
NEED_HTTPS_REWRITE=0
cleanup_https_rewrite() {
  if [ "$NEED_HTTPS_REWRITE" = "1" ]; then
    git config --global --unset url."https://github.com/".insteadOf 2>/dev/null || true
    NEED_HTTPS_REWRITE=0
  fi
}
trap cleanup_https_rewrite EXIT INT TERM

if ! ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  warn "SSH auth to GitHub unavailable, using HTTPS fallback"
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  NEED_HTTPS_REWRITE=1
fi

# --- Step 4: Install plugin ---

info "Installing $PLUGIN_NAME..."

claude plugin uninstall "${PLUGIN_NAME}@${MARKETPLACE_NAME}" 2>/dev/null || true
if ! claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"; then
  cleanup_https_rewrite
  fail "Failed to install $PLUGIN_NAME"
fi
if ! claude plugin list 2>/dev/null | grep -q "$PLUGIN_NAME@$MARKETPLACE_NAME"; then
  cleanup_https_rewrite
  fail "$PLUGIN_NAME install reported success but plugin not found"
fi
ok "$PLUGIN_NAME installed"

cleanup_https_rewrite

# --- Step 5: Configure permissions ---

info "Configuring plugin permissions..."

SETTINGS_FILE="$HOME/.claude/settings.json"

# Permission rules the plugin needs to operate without constant prompts.
# Deliberately excluded: Bash(curl *) and all Bash(rm *) — those require manual approval.
PRFAQ_RULES='[
  "Bash(bash */compile_prfaq.sh *)",
  "Bash(bash scripts/compile_prfaq.sh *)",
  "Bash(bash */export_prfaq_docx.sh *)",
  "Bash(bash scripts/export_prfaq_docx.sh *)",
  "Bash(bash */generate_reference_docx.sh *)",
  "Bash(bash scripts/generate_reference_docx.sh *)",
  "Bash(uuidgen)",
  "Bash(mkdir -p meetings)",
  "Bash(mkdir -p research)",
  "Write(*prfaq*.tex)",
  "Write(*prfaq*.bib)",
  "Write(press-release-*.tex)",
  "Write(.claude/prfaq.local.md)",
  "Write(meetings/**)",
  "Write(research/**)",
  "Write(.gitignore)",
  "Write(README.md)",
  "Edit(*prfaq*.tex)",
  "Edit(*prfaq*.bib)",
  "Edit(press-release-*.tex)",
  "Edit(README.md)",
  "Edit(.gitignore)",
  "WebSearch",
  "WebFetch"
]'

if command -v jq >/dev/null 2>&1; then
  # Ensure settings file exists with valid JSON
  if [ ! -f "$SETTINGS_FILE" ]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    printf '{}' > "$SETTINGS_FILE"
  elif ! jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
    warn "Existing $SETTINGS_FILE contains invalid JSON; backing up and recreating"
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak" 2>/dev/null || true
    printf '{}' > "$SETTINGS_FILE"
  fi

  # Order-preserving merge: append only rules not already present
  ADDED=$(jq -r --argjson new "$PRFAQ_RULES" '
    (.permissions.allow // []) as $orig
    | [$new[] | select(. as $r | $orig | index($r) | not)] | length
  ' "$SETTINGS_FILE")

  jq --argjson new "$PRFAQ_RULES" '
    (.permissions.allow // []) as $orig
    | .permissions.allow = $orig + [$new[] | select(. as $r | $orig | index($r) | not)]
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

  if [ "$ADDED" -gt 0 ]; then
    ok "$ADDED permission rule(s) added to $SETTINGS_FILE"
  else
    ok "permissions already configured"
  fi
else
  warn "jq not found — cannot auto-configure permissions"
  printf '\n'
  info "Add these rules manually to $SETTINGS_FILE under permissions.allow:"
  printf '%s\n' "$PRFAQ_RULES"
  printf '\n'
fi

# --- Step 6: Output toolchain checks ---

info "Checking output toolchains..."

# 6a: pandoc (needed for DOCX export)
if command -v pandoc >/dev/null 2>&1; then
  ok "pandoc found (DOCX export available)"
else
  warn "pandoc not found — /prfaq:export (DOCX) will not work"
  printf '  Install: brew install pandoc (macOS) or apt install pandoc (Linux)\n'
fi

# 6b: TeX distribution (needed for PDF output)
TEX_MISSING=0

if command -v pdflatex >/dev/null 2>&1; then
  ok "pdflatex found (PDF output available)"
else
  warn "pdflatex not found — PDF compilation will not work"
  TEX_MISSING=1
fi

if command -v biber >/dev/null 2>&1; then
  ok "biber found"
else
  warn "biber not found — citations will show as [?] in PDFs"
  TEX_MISSING=1
fi

if [ "$TEX_MISSING" -ne 0 ]; then
  printf '\n'
  info "To install a TeX distribution:"
  printf '  macOS:  brew install --cask mactex\n'
  printf '  Ubuntu: sudo apt-get install texlive-full\n'
  printf '  Fedora: sudo dnf install texlive-scheme-full\n'
  printf '  Other:  https://tug.org/texlive/\n'
  printf '\n'
  info "The plugin still generates .tex files without TeX installed."
  info "Use /prfaq:export for Word output (requires only pandoc, ~50 MB)."
fi

# --- Done ---

printf '\n%b%b%s is ready!%b\n\n' "$GREEN" "$BOLD" "$PLUGIN_NAME" "$NC"
printf 'Restart Claude Code, then type /prfaq to start a Working Backwards document.\n\n'
