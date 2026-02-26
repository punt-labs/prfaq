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

info() { printf '%b==>%b %s\n' "$BOLD" "$NC" "$1"; }
ok()   { printf '  %b✓%b %s\n' "$GREEN" "$NC" "$1"; }
warn() { printf '  %b!%b %s\n' "$YELLOW" "$NC" "$1"; }
fail() { printf '  %b✗%b %s\n' "$YELLOW" "$NC" "$1"; exit 1; }

MARKETPLACE_REPO="punt-labs/claude-plugins"
MARKETPLACE_NAME="punt-labs"
PLUGIN_NAME="prfaq"

# --- Step 1: Claude Code CLI ---

info "Checking Claude Code..."

if command -v claude >/dev/null 2>&1; then
  ok "claude CLI found"
else
  fail "'claude' CLI not found. Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
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

if ! claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"; then
  cleanup_https_rewrite
  fail "Failed to install $PLUGIN_NAME"
fi
ok "$PLUGIN_NAME installed"

cleanup_https_rewrite

# --- Step 5: TeX distribution check ---

info "Checking TeX distribution (optional, needed for PDF output)..."

MISSING=0

if command -v pdflatex >/dev/null 2>&1; then
  ok "pdflatex found"
else
  warn "pdflatex not found — PDF compilation will not work"
  MISSING=1
fi

if command -v biber >/dev/null 2>&1; then
  ok "biber found"
else
  warn "biber not found — citations will show as [?] in PDFs"
  MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
  printf '\n'
  info "To install a TeX distribution:"
  printf '  macOS:  brew install --cask mactex\n'
  printf '  Ubuntu: sudo apt-get install texlive-full\n'
  printf '  Fedora: sudo dnf install texlive-scheme-full\n'
  printf '  Other:  https://tug.org/texlive/\n'
  printf '\n'
  info "The plugin still generates .tex files without TeX installed."
fi

# --- Done ---

printf '\n%b%b%s is ready!%b\n\n' "$GREEN" "$BOLD" "$PLUGIN_NAME" "$NC"
printf 'Restart Claude Code, then type /prfaq to start a Working Backwards document.\n\n'
