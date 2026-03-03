#!/usr/bin/env bash
# export_prfaq_docx.sh — Convert a prfaq .tex file to .docx via pandoc.
#
# Usage: bash export_prfaq_docx.sh input.tex [output.docx]
#
# Pipeline: input.tex → preprocess → cleaned.tex → pandoc → raw.docx → post-process → output.docx
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Helpers ──────────────────────────────────────────────────────────────────

die()  { printf 'Error: %s\n' "$1" >&2; exit 1; }
info() { printf '  → %s\n' "$1" >&2; }

# ── Arguments ────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: export_prfaq_docx.sh <input.tex> [output.docx]" >&2
  exit 1
fi

TEX_FILE="$1"
[[ -f "$TEX_FILE" ]] || die "File not found: $TEX_FILE"

# Default output: same basename, .docx extension
OUTPUT="${2:-${TEX_FILE%.tex}.docx}"

# ── Prerequisite check ───────────────────────────────────────────────────────

command -v pandoc >/dev/null 2>&1 || die "pandoc not found. Install: brew install pandoc (macOS) or apt install pandoc (Linux)"

# ── Workspace ────────────────────────────────────────────────────────────────

WORK_DIR="$(dirname "$TEX_FILE")/.tmp"
mkdir -p "$WORK_DIR"

CLEANED="$WORK_DIR/docx_cleaned_$$.tex"
RAW_DOCX="$WORK_DIR/docx_raw_$$.docx"
trap 'rm -f "$CLEANED" "$RAW_DOCX"' EXIT

# ── Step 1: Preprocess ──────────────────────────────────────────────────────

info "Preprocessing LaTeX..."
bash "$SCRIPT_DIR/preprocess_for_docx.sh" "$TEX_FILE" > "$CLEANED"

# ── Step 2: Pandoc conversion ───────────────────────────────────────────────

PANDOC_ARGS=(
  --from=latex
  --to=docx
  --output="$RAW_DOCX"
)

# Use reference.docx for styled output if available
REFERENCE_DOCX="$PLUGIN_ROOT/assets/reference.docx"
if [[ -f "$REFERENCE_DOCX" ]]; then
  PANDOC_ARGS+=(--reference-doc="$REFERENCE_DOCX")
  info "Converting with styled template..."
else
  info "Converting with default styles (reference.docx not found)..."
fi

pandoc "$CLEANED" "${PANDOC_ARGS[@]}"

# ── Step 3: Post-process header/footer ──────────────────────────────────────

# Extract title from the \title{} command in the cleaned .tex
DOC_TITLE=""
while IFS= read -r line; do
  if [[ "$line" =~ \\title\{([^}]+)\} ]]; then
    DOC_TITLE="${BASH_REMATCH[1]}"
    # Strip LaTeX commands from the title (e.g., \textmd{}, \\)
    DOC_TITLE=$(printf '%s' "$DOC_TITLE" | sed 's/\\textmd{//g; s/\\\\.*//; s/}//g; s/[[:space:]]*$//')
    break
  fi
done < "$CLEANED"

# If reference.docx has header placeholders, replace them
if [[ -n "$DOC_TITLE" ]]; then
  UNZIP_DIR="$WORK_DIR/docx_unzip_$$"
  mkdir -p "$UNZIP_DIR"
  unzip -q -o "$RAW_DOCX" -d "$UNZIP_DIR" 2>/dev/null

  # Replace header placeholders in all header XML parts
  MODIFIED=0
  for hdr in "$UNZIP_DIR"/word/header*.xml; do
    [[ -f "$hdr" ]] || continue
    if grep -q '{{TITLE}}' "$hdr" 2>/dev/null; then
      sed -i '' "s/{{TITLE}}/${DOC_TITLE//&/\\&}/g" "$hdr" 2>/dev/null || \
      sed -i "s/{{TITLE}}/${DOC_TITLE//&/\\&}/g" "$hdr"
      MODIFIED=1
    fi
  done

  if [[ $MODIFIED -eq 1 ]]; then
    (cd "$UNZIP_DIR" && zip -q -r "$RAW_DOCX" .)
    info "Header placeholders replaced."
  fi

  rm -rf "$UNZIP_DIR"
fi

# ── Step 4: Move to final location ──────────────────────────────────────────

mv "$RAW_DOCX" "$OUTPUT"
info "Done: $OUTPUT"
