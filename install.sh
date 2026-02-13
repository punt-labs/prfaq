#!/usr/bin/env bash
set -euo pipefail

# prfaq installer — sets up the Claude Code plugin for Working Backwards PR/FAQ
# Usage: curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh | bash

REPO="https://github.com/punt-labs/prfaq.git"
PLUGIN_NAME="prfaq"
PLUGINS_DIR="$HOME/.claude/plugins/local-plugins/plugins"
MARKETPLACE="$HOME/.claude/plugins/local-plugins/.claude-plugin/marketplace.json"
INSTALL_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

info()  { printf '\033[0;34m%s\033[0m\n' "$*"; }
ok()    { printf '\033[0;32m%s\033[0m\n' "$*"; }
warn()  { printf '\033[0;33m%s\033[0m\n' "$*"; }
error() { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }

# ── Preflight checks ────────────────────────────────────────────────────────

if ! command -v git &>/dev/null; then
  error "git is required but not found. Install git first."
  exit 1
fi

if ! command -v claude &>/dev/null; then
  warn "claude CLI not found in PATH. Make sure Claude Code is installed."
fi

# ── Check for TeX distribution ───────────────────────────────────────────────

if command -v pdflatex &>/dev/null; then
  ok "pdflatex found: $(command -v pdflatex)"
else
  warn "pdflatex not found. PDF compilation requires a TeX distribution."
  warn ""
  case "$(uname -s)" in
    Darwin)
      warn "  Install on macOS:  brew install --cask mactex"
      warn "                     or: brew install basictex"
      ;;
    Linux)
      warn "  Install on Ubuntu/Debian:  sudo apt install texlive-full"
      warn "  Install on Fedora:         sudo dnf install texlive-scheme-full"
      warn "  Install on Arch:           sudo pacman -S texlive"
      ;;
    *)
      warn "  Visit https://tug.org/texlive/ for installation instructions."
      ;;
  esac
  warn ""
  warn "The plugin will still generate .tex files without pdflatex."
  warn "You can install TeX later and compile manually."
fi

# ── Install plugin ───────────────────────────────────────────────────────────

if [[ -d "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
  info "Existing installation found at $INSTALL_DIR"
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating via git pull..."
    git -C "$INSTALL_DIR" pull --quiet
    ok "Updated."
  else
    # Symlink to a dev checkout — leave it alone
    ok "Symlink detected. Skipping (developer mode)."
  fi
else
  info "Cloning $REPO into $INSTALL_DIR..."
  mkdir -p "$PLUGINS_DIR"
  git clone --quiet "$REPO" "$INSTALL_DIR"
  ok "Cloned."
fi

# ── Register in marketplace.json ─────────────────────────────────────────────

MARKETPLACE_DIR="$(dirname "$MARKETPLACE")"
if [[ ! -f "$MARKETPLACE" ]]; then
  info "Creating marketplace.json..."
  mkdir -p "$MARKETPLACE_DIR"
  cat > "$MARKETPLACE" <<'MANIFEST'
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "local",
  "description": "Local plugins",
  "owner": {
    "name": "local",
    "email": "local@localhost"
  },
  "plugins": []
}
MANIFEST
fi

# Check if already registered
if grep -q "\"$PLUGIN_NAME\"" "$MARKETPLACE" 2>/dev/null; then
  ok "Already registered in marketplace.json."
else
  info "Registering plugin in marketplace.json..."
  # Use a temp file to avoid partial writes
  TMPFILE="$(mktemp)"
  if command -v jq &>/dev/null; then
    jq --arg name "$PLUGIN_NAME" \
       '.plugins += [{
         "name": $name,
         "description": "Amazon Working Backwards PR/FAQ process — generate professional LaTeX documents for product discovery and decision-making",
         "version": "0.1.0",
         "author": {"name": "punt-labs", "email": "hello@punt-labs.com"},
         "source": ("./plugins/" + $name),
         "category": "development"
       }]' "$MARKETPLACE" > "$TMPFILE"
    mv "$TMPFILE" "$MARKETPLACE"
  else
    warn "jq not found — please add the plugin entry to $MARKETPLACE manually."
    warn "See https://github.com/punt-labs/prfaq#installation for details."
  fi
  ok "Registered."
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
ok "prfaq installed successfully."
echo ""
info "Next steps:"
info "  1. Restart Claude Code (or start a new session)"
info "  2. Type /prfaq to start a Working Backwards PR/FAQ"
echo ""
