#!/bin/sh
# Install prfaq — Working Backwards PR/FAQ process for Claude Code.
# Usage: curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/<SHA>/install.sh | sh
#
# The plugin generates .tex files. You need at least one output toolchain:
#   - pandoc (~50 MB) for Word (.docx) output via /prfaq:export
#   - TeX distribution (~4 GB) for PDF output via pdflatex
# The installer checks for both but does not install them automatically.
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

# `claude plugin marketplace list` prints the name on its own line and the
# source repo on the next one:
#
#     ❯ punt-labs
#       Source: GitHub (punt-labs/claude-plugins)
#
# so a substring test for the name also matches any other marketplace whose
# source repo happens to contain it. Match a line that holds nothing but the
# name (any leading decoration allowed) to read the name field alone.
marketplace_listed() {
  claude plugin marketplace list </dev/null 2>/dev/null \
    | grep -qE "^[^A-Za-z0-9]*[[:space:]]*${MARKETPLACE_NAME}[[:space:]]*$"
}

# Neither match direction is trusted on its own: the format above is not a
# stable contract, so a future change could make the check miss an entry that
# is in fact registered. Registering again is then the recoverable path — if
# add fails, look for the name anywhere in the listing before giving up.
marketplace_mentioned() {
  claude plugin marketplace list </dev/null 2>/dev/null | grep -q "$MARKETPLACE_NAME"
}

# Every already-registered path has to refresh. Skipping it on one of them
# resolves the install against whatever ref was cached last time, silently —
# which is the failure this warning exists to surface.
refresh_marketplace() {
  if ! claude plugin marketplace update "$MARKETPLACE_NAME" </dev/null >/dev/null 2>&1; then
    # Not fatal — the cached marketplace still resolves. But say so.
    warn "could not refresh the marketplace; installing from the cached copy"
    warn "if you end up on an old version, re-run this installer when back online"
  fi
}

if marketplace_listed; then
  ok "marketplace already registered"
  refresh_marketplace
elif claude plugin marketplace add "$MARKETPLACE_REPO" </dev/null; then
  ok "marketplace registered"
elif marketplace_mentioned; then
  ok "marketplace already registered"
  refresh_marketplace
else
  fail "Failed to register marketplace"
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

if ! ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com </dev/null 2>&1 | grep -q "successfully authenticated"; then
  warn "SSH auth to GitHub unavailable, using HTTPS fallback"
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  NEED_HTTPS_REWRITE=1
fi

# --- Step 4: Install plugin ---

info "Installing $PLUGIN_NAME..."

claude plugin uninstall "${PLUGIN_NAME}@${MARKETPLACE_NAME}" </dev/null 2>/dev/null || true
if ! claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" </dev/null; then
  cleanup_https_rewrite
  fail "Failed to install $PLUGIN_NAME"
fi
if ! claude plugin list </dev/null 2>/dev/null | grep -q "$PLUGIN_NAME@$MARKETPLACE_NAME"; then
  cleanup_https_rewrite
  fail "$PLUGIN_NAME install reported success but plugin not found"
fi
ok "$PLUGIN_NAME installed"

cleanup_https_rewrite

# --- Step 5: Output toolchain checks ---

info "Checking output toolchains..."

# 6a: pandoc (needed for DOCX export)
PANDOC_FOUND=0
if command -v pandoc >/dev/null 2>&1; then
  ok "pandoc found (DOCX export available)"
  PANDOC_FOUND=1
else
  warn "pandoc not found — /prfaq:export (DOCX) will not work"
  printf '  Install: brew install pandoc (macOS) or apt install pandoc (Linux)\n'
fi

# 6b: TeX distribution (needed for PDF output)
TEX_FOUND=1

if command -v pdflatex >/dev/null 2>&1; then
  ok "pdflatex found (PDF output available)"
else
  warn "pdflatex not found — PDF compilation will not work"
  TEX_FOUND=0
fi

if command -v biber >/dev/null 2>&1; then
  ok "biber found"
else
  warn "biber not found — citations will show as [?] in PDFs"
fi

# 6c: At least one output toolchain required
if [ "$PANDOC_FOUND" -eq 0 ] && [ "$TEX_FOUND" -eq 0 ]; then
  printf '\n'
  warn "Neither pandoc nor TeX found — you need at least one to produce output."
  printf '\n'
  info "Recommended: install a TeX distribution for PDF output (~4 GB):"
  printf '  macOS:  brew install --cask mactex\n'
  printf '  Ubuntu: sudo apt-get install texlive-full\n'
  printf '  Fedora: sudo dnf install texlive-scheme-full\n'
  printf '  Other:  https://tug.org/texlive/\n'
  printf '\n'
  info "Lightweight alternative: install pandoc (~50 MB) for Word output:"
  printf '  macOS:  brew install pandoc\n'
  printf '  Ubuntu: sudo apt-get install pandoc\n'
elif [ "$TEX_FOUND" -eq 0 ]; then
  printf '\n'
  info "The plugin generates .tex source without TeX installed."
  info "You have pandoc, so /prfaq:export will produce Word (.docx) output."
  info "For PDF output, install a TeX distribution:"
  printf '  macOS:  brew install --cask mactex\n'
  printf '  Ubuntu: sudo apt-get install texlive-full\n'
fi

# --- Done ---

printf '\n%b%b%s is ready!%b\n\n' "$GREEN" "$BOLD" "$PLUGIN_NAME" "$NC"
printf 'Restart Claude Code, then type /prfaq to start a Working Backwards document.\n\n'
