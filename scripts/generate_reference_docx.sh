#!/usr/bin/env bash
# generate_reference_docx.sh — Build a styled reference.docx for pandoc.
#
# Usage: bash generate_reference_docx.sh [output_path]
#
# Creates a pandoc reference.docx with styles tuned for prfaq documents:
# - Palatino-like serif body (Palatino Linotype / Palatino / Georgia fallback)
# - SectionBlue (#1B3A5C) headings
# - Styled block quotes
# - Consistent spacing
#
# The reference.docx is used by export_prfaq_docx.sh to style the Word output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Resolve to absolute path immediately so subshells don't lose context
OUTPUT="${1:-$SCRIPT_DIR/../assets/reference.docx}"
OUTPUT="$(cd "$(dirname "$OUTPUT")" 2>/dev/null && pwd)/$(basename "$OUTPUT")" || OUTPUT="$(pwd)/${1:-assets/reference.docx}"
mkdir -p "$(dirname "$OUTPUT")"

command -v pandoc >/dev/null 2>&1 || { echo "Error: pandoc required" >&2; exit 1; }

WORK_DIR="$(dirname "$OUTPUT")/.tmp"
mkdir -p "$WORK_DIR"

RAW_REF="$WORK_DIR/ref_raw_$$.docx"
UNZIP_DIR="$WORK_DIR/ref_unzip_$$"
trap 'rm -f "$RAW_REF"; rm -rf "$UNZIP_DIR"' EXIT

# Step 1: Extract pandoc's default reference.docx
pandoc --print-default-data-file reference.docx > "$RAW_REF"

# Step 2: Unpack
mkdir -p "$UNZIP_DIR"
unzip -q -o "$RAW_REF" -d "$UNZIP_DIR"

# Step 3: Patch styles.xml with prfaq styles
STYLES_XML="$UNZIP_DIR/word/styles.xml"

if [[ ! -f "$STYLES_XML" ]]; then
  echo "Error: styles.xml not found in reference.docx" >&2
  exit 1
fi

# Color constants matching prfaq-template.tex
SECTION_BLUE="1B3A5C"
ACCENT_GRAY="4A4A4A"
# Font: Palatino Linotype (Windows), Palatino (macOS), Georgia (fallback)
BODY_FONT="Palatino Linotype"

# Patch body text font (Normal style) — change rFonts ascii and hAnsi
# Use sed to find the Normal style block and update the font
python3 - "$STYLES_XML" "$SECTION_BLUE" "$BODY_FONT" << 'PYTHON'
import sys
import warnings
warnings.filterwarnings('ignore', category=DeprecationWarning)
import xml.etree.ElementTree as ET

styles_path = sys.argv[1]
section_blue = sys.argv[2]
body_font = sys.argv[3]

ns = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
}
# Register namespaces to preserve them on output
for prefix, uri in ns.items():
    ET.register_namespace(prefix, uri)
# Also register other common OOXML namespaces that may appear
ET.register_namespace('mc', 'http://schemas.openxmlformats.org/markup-compatibility/2006')
ET.register_namespace('w14', 'http://schemas.microsoft.com/office/word/2010/wordml')
ET.register_namespace('w15', 'http://schemas.microsoft.com/office/word/2012/wordml')

tree = ET.parse(styles_path)
root = tree.getroot()

def find_style(style_id):
    for s in root.findall('.//w:style', ns):
        if s.get(f'{{{ns["w"]}}}styleId') == style_id:
            return s
    return None

def get_or_create(parent, tag, ns_uri):
    el = parent.find(f'{{{ns_uri}}}{tag}')
    if el is None:
        el = ET.SubElement(parent, f'{{{ns_uri}}}{tag}')
    return el

def set_font(style_el, font_name):
    rpr = get_or_create(style_el, 'rPr', ns['w'])
    rfonts = get_or_create(rpr, 'rFonts', ns['w'])
    rfonts.set(f'{{{ns["w"]}}}ascii', font_name)
    rfonts.set(f'{{{ns["w"]}}}hAnsi', font_name)

def set_color(style_el, hex_color):
    rpr = get_or_create(style_el, 'rPr', ns['w'])
    color = get_or_create(rpr, 'color', ns['w'])
    color.set(f'{{{ns["w"]}}}val', hex_color)

def set_bold(style_el):
    rpr = get_or_create(style_el, 'rPr', ns['w'])
    b = rpr.find(f'{{{ns["w"]}}}b')
    if b is None:
        ET.SubElement(rpr, f'{{{ns["w"]}}}b')

def set_size(style_el, half_points):
    rpr = get_or_create(style_el, 'rPr', ns['w'])
    sz = get_or_create(rpr, 'sz', ns['w'])
    sz.set(f'{{{ns["w"]}}}val', str(half_points))
    szCs = get_or_create(rpr, 'szCs', ns['w'])
    szCs.set(f'{{{ns["w"]}}}val', str(half_points))

# Normal (body text): Palatino, 11pt, dark gray
normal = find_style('Normal')
if normal:
    set_font(normal, body_font)
    set_size(normal, 22)  # 11pt
    set_color(normal, '333333')

# Heading 1: SectionBlue, bold, 16pt
h1 = find_style('Heading1')
if h1:
    set_font(h1, body_font)
    set_color(h1, section_blue)
    set_bold(h1)
    set_size(h1, 32)  # 16pt

# Heading 2: SectionBlue, bold, 13pt
h2 = find_style('Heading2')
if h2:
    set_font(h2, body_font)
    set_color(h2, section_blue)
    set_bold(h2)
    set_size(h2, 26)  # 13pt

# Heading 3: SectionBlue, bold, 11pt
h3 = find_style('Heading3')
if h3:
    set_font(h3, body_font)
    set_color(h3, section_blue)
    set_bold(h3)
    set_size(h3, 22)  # 11pt

# Block Text (used for quotes): italic, indented, gray
block = find_style('BlockText')
if block:
    set_font(block, body_font)
    set_color(block, '555555')

tree.write(styles_path, xml_declaration=True, encoding='UTF-8')
PYTHON

# Step 4: Add a header with a title placeholder
# Create header1.xml with {{TITLE}} placeholder
HEADER_XML="$UNZIP_DIR/word/header1.xml"
cat > "$HEADER_XML" << 'HEADER'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
       xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:p>
    <w:pPr>
      <w:jc w:val="right"/>
      <w:rPr>
        <w:color w:val="999999"/>
        <w:sz w:val="16"/>
      </w:rPr>
    </w:pPr>
    <w:r>
      <w:rPr>
        <w:color w:val="999999"/>
        <w:sz w:val="16"/>
      </w:rPr>
      <w:t>{{TITLE}}</w:t>
    </w:r>
  </w:p>
</w:hdr>
HEADER

# Ensure the header relationship exists in document.xml.rels
RELS_FILE="$UNZIP_DIR/word/_rels/document.xml.rels"
if [[ -f "$RELS_FILE" ]] && ! grep -q 'header1.xml' "$RELS_FILE"; then
  # Add header relationship before closing tag
  sed -i '' 's|</Relationships>|<Relationship Id="rIdHeader1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/></Relationships>|' "$RELS_FILE" 2>/dev/null || \
  sed -i 's|</Relationships>|<Relationship Id="rIdHeader1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/></Relationships>|' "$RELS_FILE"
fi

# Add header reference to document.xml sectPr
DOC_XML="$UNZIP_DIR/word/document.xml"
if [[ -f "$DOC_XML" ]] && ! grep -q 'rIdHeader1' "$DOC_XML"; then
  # Insert headerReference inside sectPr
  sed -i '' 's|<w:sectPr|<w:sectPr><w:headerReference w:type="default" r:id="rIdHeader1"/></w:sectPr><w:sectPr|' "$DOC_XML" 2>/dev/null || true
fi

# Ensure header1.xml is in [Content_Types].xml
CONTENT_TYPES="$UNZIP_DIR/[Content_Types].xml"
if [[ -f "$CONTENT_TYPES" ]] && ! grep -q 'header1.xml' "$CONTENT_TYPES"; then
  sed -i '' 's|</Types>|<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/></Types>|' "$CONTENT_TYPES" 2>/dev/null || \
  sed -i 's|</Types>|<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/></Types>|' "$CONTENT_TYPES"
fi

# Step 5: Repack
(cd "$UNZIP_DIR" && zip -q -r "$OUTPUT" .)

echo "Generated: $OUTPUT"
