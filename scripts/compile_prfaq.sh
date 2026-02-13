#!/usr/bin/env bash
set -euo pipefail

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
pdflatex -interaction=nonstopmode -output-directory="$DIR" "$TEX_FILE" > /dev/null 2>&1

if [[ -f "$DIR/$BASE.pdf" ]]; then
  echo "Success: $DIR/$BASE.pdf"
else
  echo "Error: PDF not generated. Re-running with full output:" >&2
  pdflatex -interaction=nonstopmode -output-directory="$DIR" "$TEX_FILE"
  exit 1
fi
