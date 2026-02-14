#!/usr/bin/env bash
set -euo pipefail

# prfaq installer — sets up the Claude Code plugin for Working Backwards PR/FAQ
# Usage: curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh | bash

REPO="https://github.com/punt-labs/prfaq.git"
PLUGIN_NAME="prfaq"
PLUGINS_DIR="$HOME/.claude/plugins/local-plugins/plugins"
MARKETPLACE="$HOME/.claude/plugins/local-plugins/.claude-plugin/marketplace.json"
INSTALL_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

# LaTeX packages required by prfaq-template.tex
REQUIRED_PACKAGES=(
  geometry        # Page margins
  fontenc         # Font encoding (T1)
  newpxtext       # Palatino serif font (TeX Gyre Pagella)
  newpxmath       # Matching math font
  xcolor          # Color definitions
  booktabs        # Professional table rules
  tabularx        # Auto-width table columns
  mdframed        # Framed environments (quote boxes, risk box)
  tikz            # Required by mdframed framemethod=tikz
  enumitem        # List customization
  hyperref        # Hyperlinks and PDF metadata
  titlesec        # Section heading styles
  changepage      # adjustwidth for indented FAQ answers
)

info()   { printf '\033[0;34m%s\033[0m\n' "$*"; }
ok()     { printf '\033[0;32m  ✓ %s\033[0m\n' "$*"; }
warn()   { printf '\033[0;33m  ⚠ %s\033[0m\n' "$*"; }
fail()   { printf '\033[0;31m  ✗ %s\033[0m\n' "$*"; }
header() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# Ask a yes/no question. Returns 0 for yes, 1 for no.
ask() {
  local prompt="$1"
  # If stdin is not a terminal (piped install), default to yes
  if [[ ! -t 0 ]]; then
    return 0
  fi
  printf '\033[0;34m  %s [Y/n] \033[0m' "$prompt"
  read -r answer </dev/tty
  [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

# ── Preflight: required tools ────────────────────────────────────────────────

header "Prerequisites"

if command -v git &>/dev/null; then
  ok "git $(git --version | sed 's/git version //')"
else
  fail "git not found — install git first"
  exit 1
fi

if command -v claude &>/dev/null; then
  ok "claude CLI"
else
  warn "claude CLI not found in PATH"
fi

if command -v jq &>/dev/null; then
  ok "jq (for marketplace registration)"
else
  warn "jq not found — marketplace registration will need a manual step"
fi

# ── TeX distribution ─────────────────────────────────────────────────────────

header "TeX distribution"

MISSING_PACKAGES=()

install_tex() {
  case "$(uname -s)" in
    Darwin)
      if command -v brew &>/dev/null; then
        if ask "Install MacTeX via Homebrew? (~4GB, includes all packages)"; then
          info "  Installing MacTeX (this may take a while)..."
          brew install --cask mactex
          # Update PATH for this session
          eval "$(/usr/libexec/path_helper)"
          ok "MacTeX installed"
          return 0
        fi
      else
        info "  Install Homebrew first: https://brew.sh"
        info "  Then run: brew install --cask mactex"
      fi
      ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        if ask "Install texlive-full via apt? (~4GB)"; then
          info "  Installing texlive-full..."
          sudo apt-get update -qq && sudo apt-get install -y -qq texlive-full
          ok "texlive-full installed"
          return 0
        fi
      elif command -v dnf &>/dev/null; then
        if ask "Install texlive-scheme-full via dnf?"; then
          info "  Installing texlive-scheme-full..."
          sudo dnf install -y texlive-scheme-full
          ok "texlive-scheme-full installed"
          return 0
        fi
      elif command -v pacman &>/dev/null; then
        if ask "Install texlive via pacman?"; then
          info "  Installing texlive..."
          sudo pacman -S --noconfirm texlive
          ok "texlive installed"
          return 0
        fi
      else
        info "  Visit https://tug.org/texlive/ for installation instructions."
      fi
      ;;
    *)
      info "  Visit https://tug.org/texlive/ for installation instructions."
      ;;
  esac
  return 1
}

install_missing_packages() {
  local packages=("$@")
  if command -v tlmgr &>/dev/null; then
    if ask "Install missing packages via tlmgr? (${packages[*]})"; then
      info "  Updating tlmgr..."
      sudo tlmgr update --self 2>/dev/null || true
      info "  Installing: ${packages[*]}"
      sudo tlmgr install "${packages[@]}"
      ok "Packages installed"
      return 0
    fi
  else
    warn "tlmgr not found — cannot install individual packages"
    info "  Consider installing the full TeX distribution instead"
  fi
  return 1
}

if command -v pdflatex &>/dev/null; then
  ok "pdflatex found"

  # Check each required package via kpsewhich
  if command -v kpsewhich &>/dev/null; then
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
      sty="$pkg.sty"
      if [[ "$pkg" == "tikz" ]]; then
        sty="tikz.sty"
      fi

      if kpsewhich "$sty" &>/dev/null; then
        ok "$pkg"
      else
        fail "$pkg — not found"
        MISSING_PACKAGES+=("$pkg")
      fi
    done
  else
    warn "kpsewhich not found — cannot verify individual packages"
  fi
else
  fail "pdflatex not found — PDF compilation requires a TeX distribution"
  echo ""
  if install_tex; then
    # Re-check after install
    if command -v pdflatex &>/dev/null; then
      ok "pdflatex now available"
    fi
  else
    info "  You can install TeX later. The plugin will still generate .tex files."
  fi
fi

if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
  echo ""
  warn "Missing ${#MISSING_PACKAGES[@]} LaTeX package(s): ${MISSING_PACKAGES[*]}"
  echo ""
  if install_missing_packages "${MISSING_PACKAGES[@]}"; then
    MISSING_PACKAGES=()
  else
    info "  You can install these later. PDF compilation will fail without them."
  fi
fi

# ── Install plugin ───────────────────────────────────────────────────────────

header "Plugin"

if [[ -d "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
  if [[ -L "$INSTALL_DIR" ]]; then
    ok "Symlink detected at $INSTALL_DIR (developer mode)"
  elif [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Existing installation found — updating..."
    git -C "$INSTALL_DIR" pull --quiet
    ok "Updated via git pull"
  else
    ok "Installed at $INSTALL_DIR"
  fi
else
  info "Cloning $REPO..."
  mkdir -p "$PLUGINS_DIR"
  git clone --quiet "$REPO" "$INSTALL_DIR"
  ok "Cloned to $INSTALL_DIR"
fi

# ── Read metadata from plugin.json ─────────────────────────────────────────

PLUGIN_JSON="$INSTALL_DIR/.claude-plugin/plugin.json"
if [[ -f "$PLUGIN_JSON" ]] && command -v jq &>/dev/null; then
  PLUGIN_VERSION=$(jq -r '.version // "0.0.0"' "$PLUGIN_JSON")
  PLUGIN_DESCRIPTION=$(jq -r '.description // ""' "$PLUGIN_JSON")
  ok "Plugin version: $PLUGIN_VERSION"
else
  PLUGIN_VERSION="0.0.0"
  PLUGIN_DESCRIPTION="Amazon Working Backwards PR/FAQ process — generate professional LaTeX documents for product discovery and decision-making"
  warn "Could not read plugin.json — using defaults"
fi

# ── Registration ─────────────────────────────────────────────────────────────

header "Registration"

# Determine defaults for author: git config > generic
DEFAULT_NAME="local"
DEFAULT_EMAIL="local@localhost"

MARKETPLACE_DIR="$(dirname "$MARKETPLACE")"
if command -v git &>/dev/null; then
  GIT_NAME=$(git config user.name 2>/dev/null || true)
  GIT_EMAIL=$(git config user.email 2>/dev/null || true)
  [[ -n "$GIT_NAME" ]] && DEFAULT_NAME="$GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && DEFAULT_EMAIL="$GIT_EMAIL"
fi

if [[ -t 0 ]]; then
  printf '\033[0;34m  Author name [%s]: \033[0m' "$DEFAULT_NAME"
  read -r AUTHOR_NAME </dev/tty
  [[ -z "$AUTHOR_NAME" ]] && AUTHOR_NAME="$DEFAULT_NAME"
  printf '\033[0;34m  Author email [%s]: \033[0m' "$DEFAULT_EMAIL"
  read -r AUTHOR_EMAIL </dev/tty
  [[ -z "$AUTHOR_EMAIL" ]] && AUTHOR_EMAIL="$DEFAULT_EMAIL"
else
  AUTHOR_NAME="$DEFAULT_NAME"
  AUTHOR_EMAIL="$DEFAULT_EMAIL"
fi
ok "Author: $AUTHOR_NAME <$AUTHOR_EMAIL>"

# ── Create or update marketplace.json ────────────────────────────────────────

if [[ ! -f "$MARKETPLACE" ]]; then
  info "Creating marketplace.json..."
  mkdir -p "$MARKETPLACE_DIR"
  if command -v jq &>/dev/null; then
    jq -n \
      --arg name "$AUTHOR_NAME" \
      --arg email "$AUTHOR_EMAIL" \
      '{
        "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
        "name": "local",
        "description": "Local plugins",
        "owner": {"name": $name, "email": $email},
        "plugins": []
      }' > "$MARKETPLACE"
  else
    cat > "$MARKETPLACE" <<MANIFEST
{
  "\$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "local",
  "description": "Local plugins",
  "owner": {
    "name": "$AUTHOR_NAME",
    "email": "$AUTHOR_EMAIL"
  },
  "plugins": []
}
MANIFEST
  fi
  ok "Created $MARKETPLACE"
fi

if grep -q "\"$PLUGIN_NAME\"" "$MARKETPLACE" 2>/dev/null; then
  if command -v jq &>/dev/null; then
    CURRENT_VERSION=$(jq -r --arg name "$PLUGIN_NAME" \
      '.plugins[] | select(.name == $name) | .version' "$MARKETPLACE")
    if [[ "$CURRENT_VERSION" != "$PLUGIN_VERSION" ]]; then
      TMPFILE="$(mktemp)"
      jq --arg name "$PLUGIN_NAME" \
         --arg version "$PLUGIN_VERSION" \
         --arg desc "$PLUGIN_DESCRIPTION" \
         --arg author_name "$AUTHOR_NAME" \
         --arg author_email "$AUTHOR_EMAIL" \
         '(.plugins[] | select(.name == $name)) |= . + {
           "version": $version,
           "description": $desc,
           "author": {"name": $author_name, "email": $author_email}
         }' "$MARKETPLACE" > "$TMPFILE"
      mv "$TMPFILE" "$MARKETPLACE"
      ok "Updated marketplace entry: $CURRENT_VERSION → $PLUGIN_VERSION"
    else
      ok "Already registered (v$PLUGIN_VERSION)"
    fi
  else
    ok "Already registered in marketplace.json"
  fi
else
  if command -v jq &>/dev/null; then
    TMPFILE="$(mktemp)"
    jq --arg name "$PLUGIN_NAME" \
       --arg version "$PLUGIN_VERSION" \
       --arg desc "$PLUGIN_DESCRIPTION" \
       --arg author_name "$AUTHOR_NAME" \
       --arg author_email "$AUTHOR_EMAIL" \
       '.plugins += [{
         "name": $name,
         "description": $desc,
         "version": $version,
         "author": {"name": $author_name, "email": $author_email},
         "source": ("./plugins/" + $name),
         "category": "development"
       }]' "$MARKETPLACE" > "$TMPFILE"
    mv "$TMPFILE" "$MARKETPLACE"
    ok "Registered in marketplace.json"
  else
    warn "jq not found — add the plugin entry to $MARKETPLACE manually"
    info "  See https://github.com/punt-labs/prfaq#installation"
  fi
fi

# ── Clean stale cache versions ───────────────────────────────────────────────

CACHE_DIR="$HOME/.claude/plugins/cache/local/$PLUGIN_NAME"
if [[ -d "$CACHE_DIR" ]]; then
  for version_dir in "$CACHE_DIR"/*/; do
    [[ -d "$version_dir" ]] || continue
    version_name=$(basename "$version_dir")
    if [[ "$version_name" != "$PLUGIN_VERSION" ]]; then
      rm -rf "$version_dir"
      ok "Removed stale cache: v$version_name"
    fi
  done
fi

# ── Summary ──────────────────────────────────────────────────────────────────

header "Done"

if [[ ${#MISSING_PACKAGES[@]} -eq 0 ]] && command -v pdflatex &>/dev/null; then
  ok "prfaq installed — all dependencies satisfied"
else
  ok "prfaq installed"
  if ! command -v pdflatex &>/dev/null; then
    warn "Install a TeX distribution for PDF output"
  elif [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
    warn "Install missing LaTeX packages for PDF output"
  fi
fi

echo ""
info "Next steps:"
info "  1. Restart Claude Code (or start a new session)"
info "  2. Type /prfaq to start a Working Backwards PR/FAQ"
echo ""
