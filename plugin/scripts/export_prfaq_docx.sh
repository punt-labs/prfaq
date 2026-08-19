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

# Resolve to absolute paths so cd in subshells doesn't break references
TEX_FILE="$(cd "$(dirname "$TEX_FILE")" && pwd)/$(basename "$TEX_FILE")"
OUTPUT="${2:-${TEX_FILE%.tex}.docx}"
if [[ "$OUTPUT" != /* ]]; then
  OUTPUT="$(pwd)/$OUTPUT"
fi

# ── Prerequisite check ───────────────────────────────────────────────────────

command -v pandoc >/dev/null 2>&1 || die "pandoc not found. Install: brew install pandoc (macOS) or apt install pandoc (Linux)"

# ── Workspace ────────────────────────────────────────────────────────────────

WORK_DIR="$(cd "$(dirname "$TEX_FILE")" && pwd)/.tmp"
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

# Extract metadata from the source .tex file
DOC_TITLE=""
DOC_SUBTITLE=""
DOC_STAGE=""
in_doc=0
while IFS= read -r line; do
  if [[ "$line" =~ \\prfaqstage\{([^}]+)\} ]]; then
    DOC_STAGE="${BASH_REMATCH[1]}"
  fi
  if [[ "$line" =~ \\prfaqversion\{([^}]+)\}\{([^}]+)\} ]]; then
    DOC_STAGE="${DOC_STAGE} v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
  fi
  if [[ "$line" =~ \\begin\{document\} ]]; then
    in_doc=1
    continue
  fi
  [[ $in_doc -eq 0 ]] && continue
  if [[ -z "$DOC_TITLE" && "$line" =~ \\LARGE ]]; then
    DOC_TITLE=$(printf '%s' "$line" | sed 's/\\color{[^}]*}//g; s/[{}]//g; s/\\LARGE//g; s/\\bfseries//g; s/\\\\/  /g; s/\[0\.[0-9]*em\]//g; s/^[[:space:]]*//; s/[[:space:]]*$//; s/  */ /g')
  fi
  if [[ -z "$DOC_SUBTITLE" && "$line" =~ \\large ]]; then
    DOC_SUBTITLE=$(printf '%s' "$line" | sed 's/\\color{[^}]*}//g; s/[{}]//g; s/\\large//g; s/\\\\/  /g; s/^[[:space:]]*//; s/[[:space:]]*$//; s/  */ /g')
  fi
done < "$TEX_FILE"
DOC_STAGE=$(printf '%s' "$DOC_STAGE" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
DOC_STAGE="$(echo "${DOC_STAGE:0:1}" | tr '[:lower:]' '[:upper:]')${DOC_STAGE:1}"

# Post-process the docx: header/footer placeholders + title centering
UNZIP_DIR="$WORK_DIR/docx_unzip_$$"
mkdir -p "$UNZIP_DIR"
unzip -q -o "$RAW_DOCX" -d "$UNZIP_DIR" 2>/dev/null

# Replace {{TITLE}} in headers using python to avoid sed escaping issues
if [[ -n "$DOC_TITLE" ]]; then
  for hdr in "$UNZIP_DIR"/word/header*.xml; do
    [[ -f "$hdr" ]] || continue
    if grep -q '{{TITLE}}' "$hdr" 2>/dev/null; then
      python3 -c "
import sys; p=sys.argv[1]; t=sys.argv[2]
with open(p) as f: s=f.read()
with open(p,'w') as f: f.write(s.replace('{{TITLE}}',t))
" "$hdr" "$DOC_TITLE"
    fi
  done
fi

# Replace {{STAGE}} in footers
if [[ -n "$DOC_STAGE" ]]; then
  for ftr in "$UNZIP_DIR"/word/footer*.xml; do
    [[ -f "$ftr" ]] || continue
    if grep -q '{{STAGE}}' "$ftr" 2>/dev/null; then
      python3 -c "
import sys; p=sys.argv[1]; t=sys.argv[2]
with open(p) as f: s=f.read()
with open(p,'w') as f: f.write(s.replace('{{STAGE}}','Stage: '+t))
" "$ftr" "$DOC_STAGE"
    fi
  done
fi

# Center title and subtitle paragraphs in document.xml
DOC_XML="$UNZIP_DIR/word/document.xml"
if [[ -f "$DOC_XML" && ( -n "$DOC_TITLE" || -n "$DOC_SUBTITLE" ) ]]; then
  python3 - "$DOC_XML" "$DOC_TITLE" "$DOC_SUBTITLE" << 'PYPOST'
import sys
import warnings
warnings.filterwarnings('ignore', category=DeprecationWarning)
import xml.etree.ElementTree as ET

doc_path, title_text, subtitle_text = sys.argv[1], sys.argv[2], sys.argv[3]
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
ns = {'w': W}
for prefix, uri in ns.items():
    ET.register_namespace(prefix, uri)
ET.register_namespace('r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
ET.register_namespace('mc', 'http://schemas.openxmlformats.org/markup-compatibility/2006')
ET.register_namespace('w14', 'http://schemas.microsoft.com/office/word/2010/wordml')
ET.register_namespace('w15', 'http://schemas.microsoft.com/office/word/2012/wordml')
ET.register_namespace('wp', 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing')
ET.register_namespace('m', 'http://schemas.openxmlformats.org/officeDocument/2006/math')

tree = ET.parse(doc_path)
root = tree.getroot()

def get_paragraph_text(p):
    texts = []
    for r in p.findall('.//w:t', ns):
        if r.text:
            texts.append(r.text)
    return ''.join(texts)

def center_paragraph(p):
    ppr = p.find(f'{{{W}}}pPr')
    if ppr is None:
        ppr = ET.SubElement(p, f'{{{W}}}pPr')
        p.insert(0, ppr)
    jc = ppr.find(f'{{{W}}}jc')
    if jc is None:
        jc = ET.SubElement(ppr, f'{{{W}}}jc')
    jc.set(f'{{{W}}}val', 'center')

def set_run_props(p, size_half_pts, color_hex, bold=False):
    for r in p.findall(f'{{{W}}}r', ns):
        rpr = r.find(f'{{{W}}}rPr')
        if rpr is None:
            rpr = ET.SubElement(r, f'{{{W}}}rPr')
            r.insert(0, rpr)
        sz = rpr.find(f'{{{W}}}sz')
        if sz is None:
            sz = ET.SubElement(rpr, f'{{{W}}}sz')
        sz.set(f'{{{W}}}val', str(size_half_pts))
        szCs = rpr.find(f'{{{W}}}szCs')
        if szCs is None:
            szCs = ET.SubElement(rpr, f'{{{W}}}szCs')
        szCs.set(f'{{{W}}}val', str(size_half_pts))
        c = rpr.find(f'{{{W}}}color')
        if c is None:
            c = ET.SubElement(rpr, f'{{{W}}}color')
        c.set(f'{{{W}}}val', color_hex)
        if bold:
            b = rpr.find(f'{{{W}}}b')
            if b is None:
                ET.SubElement(rpr, f'{{{W}}}b')

body = root.find(f'{{{W}}}body')
paragraphs = body.findall(f'{{{W}}}p') if body is not None else []

for p in paragraphs:
    text = get_paragraph_text(p)
    if title_text and title_text in text:
        center_paragraph(p)
        set_run_props(p, 36, '1B3A5C', bold=True)  # 18pt, SectionBlue, bold
    elif subtitle_text and subtitle_text[:40] in text:
        center_paragraph(p)
        set_run_props(p, 24, '4A4A4A')  # 12pt, AccentGray

tree.write(doc_path, xml_declaration=True, encoding='UTF-8')
PYPOST
  info "Title/subtitle centered."
fi

(cd "$UNZIP_DIR" && zip -q -r "$RAW_DOCX" .)
rm -rf "$UNZIP_DIR"
info "Post-processing complete."

# ── Step 4: Move to final location ──────────────────────────────────────────

mv "$RAW_DOCX" "$OUTPUT"
info "Done: $OUTPUT"
