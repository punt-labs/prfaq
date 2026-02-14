#!/usr/bin/env bash
set -euo pipefail

if ! command -v pdflatex &>/dev/null; then
  echo "Error: pdflatex not found. Install a TeX distribution or run the prfaq installer:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh | bash" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: compile_prfaq.sh <file.tex>" >&2
  exit 1
fi

TEX_FILE="$1"
if [[ ! -f "$TEX_FILE" ]]; then
  echo "Error: File not found: $TEX_FILE" >&2
  exit 1
fi

DIR="$(dirname "$TEX_FILE")"
BASE="$(basename "$TEX_FILE" .tex)"

echo "Compiling $TEX_FILE ..."
pdflatex -interaction=nonstopmode -output-directory="$DIR" "$TEX_FILE" > /dev/null 2>&1

# Run biber for bibliography if a .bib file exists alongside the .tex file
if [[ -f "$DIR/$BASE.bib" ]]; then
  if command -v biber &>/dev/null; then
    (cd "$DIR" && biber "$BASE") > /dev/null 2>&1 || echo "Warning: biber failed — citations may show as [?]" >&2
  else
    echo "Warning: biber not found — citations will show as [?]" >&2
  fi
  pdflatex -interaction=nonstopmode -output-directory="$DIR" "$TEX_FILE" > /dev/null 2>&1
fi

pdflatex -interaction=nonstopmode -output-directory="$DIR" "$TEX_FILE" > /dev/null 2>&1

if [[ -f "$DIR/$BASE.pdf" ]]; then
  echo "Success: $DIR/$BASE.pdf"
else
  echo "Error: PDF not generated. Re-running with full output:" >&2
  pdflatex -interaction=nonstopmode -output-directory="$DIR" "$TEX_FILE"
  exit 1
fi
