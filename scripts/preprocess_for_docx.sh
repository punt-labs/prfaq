#!/usr/bin/env bash
# preprocess_for_docx.sh — Transform prfaq custom LaTeX into pandoc-friendly LaTeX.
#
# Usage: bash preprocess_for_docx.sh input.tex > cleaned.tex
#
# Two-pass processing:
#   Pass 1: Scan for faqpair/featureitem counters, build cross-reference sed script.
#   Pass 2: Line-by-line block transformation (bash) + inline cleanup (sed).
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: preprocess_for_docx.sh <file.tex>" >&2
  exit 1
fi

TEX_FILE="$1"
if [[ ! -f "$TEX_FILE" ]]; then
  echo "Error: File not found: $TEX_FILE" >&2
  exit 1
fi

# Workspace scratch directory (per CLAUDE.md: use .tmp/ not /tmp)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(dirname "$TEX_FILE")/.tmp"
mkdir -p "$WORK_DIR"

SED_SCRIPT="$WORK_DIR/docx_sed_$$"
BLOCK_OUT="$WORK_DIR/docx_block_$$"
trap 'rm -f "$SED_SCRIPT" "$BLOCK_OUT"' EXIT

# ═══════════════════════════════════════════════════════════════════════
# Pass 1: Scan labels, extract metadata, generate sed substitution script
# ═══════════════════════════════════════════════════════════════════════

faq_ctr=0
feat_ctr=0
stage=""
version_major=""
version_minor=""

while IFS= read -r line; do
  # Skip comment lines
  [[ "$line" =~ ^[[:space:]]*% ]] && continue

  if [[ "$line" =~ \\begin\{faqpair\} ]]; then
    faq_ctr=$((faq_ctr + 1))
    if [[ "$line" =~ \\label\{([^}]+)\} ]]; then
      slug="${BASH_REMATCH[1]}"
      escaped=$(printf '%s' "$slug" | sed 's/[.[\/*^$]/\\&/g')
      echo "s|\\\\faqref{${escaped}}|FAQ~${faq_ctr}|g" >> "$SED_SCRIPT"
    fi
  fi

  if [[ "$line" =~ \\featureitem\{ ]]; then
    feat_ctr=$((feat_ctr + 1))
    if [[ "$line" =~ \\label\{([^}]+)\} ]]; then
      slug="${BASH_REMATCH[1]}"
      escaped=$(printf '%s' "$slug" | sed 's/[.[\/*^$]/\\&/g')
      echo "s|\\\\featureref{${escaped}}|Feature~${feat_ctr}|g" >> "$SED_SCRIPT"
    fi
  fi

  if [[ "$line" =~ \\prfaqstage\{([^}]+)\} ]]; then
    stage="${BASH_REMATCH[1]}"
  fi
  if [[ "$line" =~ \\prfaqversion\{([^}]+)\}\{([^}]+)\} ]]; then
    version_major="${BASH_REMATCH[1]}"
    version_minor="${BASH_REMATCH[2]}"
  fi
done < "$TEX_FILE"

# Append inline cleanup rules to the same sed script
cat >> "$SED_SCRIPT" << 'INLINE'
# Strip \textcolor{RiskRed|RiskAmber|RiskGreen}{text} → text
s/\\textcolor{Risk[A-Za-z]*}{\([^}]*\)}/\1/g
# Strip \textcolor{SectionBlue}{text} → text
s/\\textcolor{SectionBlue}{\([^}]*\)}/\1/g
# Strip other \textcolor{X}{text} → text
s/\\textcolor{[^}]*}{\([^}]*\)}/\1/g
# Strip bare \color{Name}
s/\\color{[^}]*}//g
# \texttildelow → \textasciitilde
s/\\texttildelow/\\textasciitilde/g
# \needspace{...} → nothing
s/\\needspace{[^}]*}//g
# \discretionary{-}{}{-} → -
s/\\discretionary{-}{}{-}/-/g
# \raggedleft → nothing
s/\\raggedleft//g
# \nopagebreak[N] → nothing
s/\\nopagebreak\[[0-9]\]//g
INLINE

# ═══════════════════════════════════════════════════════════════════════
# Pass 2: Block transformations (need counter state) → temp file
# ═══════════════════════════════════════════════════════════════════════

faq_ctr=0
feat_ctr=0
in_skip_block=0
skip_brace_target=0
in_table=0
past_begin_doc=0
in_headline_center=0
seen_headline_center=0

while IFS= read -r line; do

  # --- Skip multi-line custom definitions ---
  if [[ $in_skip_block -ne 0 ]]; then
    if [[ "$line" == "}" ]] || [[ "$line" == "}{%" ]]; then
      skip_brace_target=$((skip_brace_target - 1))
      if [[ $skip_brace_target -le 0 ]]; then
        in_skip_block=0
      fi
    fi
    continue
  fi

  # Detect multi-line definitions to skip
  if [[ "$line" =~ ^\\newenvironment\{faqpair\} ]]; then
    in_skip_block=1; skip_brace_target=2; continue
  fi
  if [[ "$line" =~ ^\\newcommand\{\\prsection\} ]]; then
    in_skip_block=1; skip_brace_target=1; continue
  fi
  if [[ "$line" =~ ^\\newcommand\{\\featureitem\} ]]; then
    in_skip_block=1; skip_brace_target=1; continue
  fi

  # Skip single-line preamble definitions
  [[ "$line" =~ ^\\newmdenv ]] && continue
  [[ "$line" =~ ^\\newcounter\{(faqnum|featurenum)\} ]] && continue
  [[ "$line" =~ ^\\newcommand\{\\faqref\} ]] && continue
  [[ "$line" =~ ^\\newcommand\{\\featureref\} ]] && continue
  [[ "$line" =~ ^\\newcommand\{\\prfaqstage\} ]] && continue
  [[ "$line" =~ ^\\newcommand\{\\prfaqversion\} ]] && continue
  [[ "$line" =~ ^\\prfaqstage\{ ]] && continue
  [[ "$line" =~ ^\\prfaqversion\{ ]] && continue

  # Skip layout-only commands
  [[ "$line" =~ ^\\renewcommand\{\\arraystretch\} ]] && continue
  [[ "$line" =~ ^\\renewcommand\{\\headrulewidth\} ]] && continue
  [[ "$line" =~ ^\\titleformat ]] && continue
  [[ "$line" =~ ^\\titlespacing ]] && continue
  [[ "$line" =~ ^\\pagestyle\{fancy\} ]] && continue
  [[ "$line" =~ ^\\fancyhf ]] && continue
  [[ "$line" =~ ^\\fancyhead ]] && continue
  [[ "$line" =~ ^\\brokenpenalty ]] && continue
  [[ "$line" =~ ^\\raggedbottom ]] && continue
  [[ "$line" =~ ^\\printbibliography ]] && continue

  # --- Block transformations ---

  # \begin{document} — stage metadata is in the footer, not the body
  if [[ "$line" =~ ^\\begin\{document\} ]]; then
    echo "$line"
    past_begin_doc=1
    continue
  fi

  # Detect headline center block (first \begin{center} after \begin{document})
  if [[ $past_begin_doc -eq 1 && $seen_headline_center -eq 0 && "$line" =~ ^[[:space:]]*\\begin\{center\} ]]; then
    in_headline_center=1
    seen_headline_center=1
    continue
  fi

  if [[ $in_headline_center -eq 1 ]]; then
    if [[ "$line" =~ \\end\{center\} ]]; then
      in_headline_center=0
      continue
    fi
    # Title line: {\LARGE\bfseries\color{...} text} \\[0.8em]
    if [[ "$line" =~ \\LARGE ]]; then
      clean=$(printf '%s' "$line" | sed 's/\\color{[^}]*}//g; s/[{}]//g; s/\\LARGE//g; s/\\bfseries//g; s/\\\\/  /g; s/\[0\.[0-9]*em\]//g; s/^[[:space:]]*//; s/[[:space:]]*$//; s/  */ /g')
      echo "$clean"
      echo ""
      continue
    fi
    # Subtitle line: {\large\color{...} text}
    if [[ "$line" =~ \\large ]]; then
      clean=$(printf '%s' "$line" | sed 's/\\color{[^}]*}//g; s/[{}]//g; s/\\large//g; s/\\\\/  /g; s/^[[:space:]]*//; s/[[:space:]]*$//; s/  */ /g')
      echo "$clean"
      continue
    fi
    # Skip \vspace and other spacing within the block
    continue
  fi

  # Skip \vspace immediately after headline block
  if [[ $seen_headline_center -eq 1 && "$line" =~ ^\\vspace ]]; then
    seen_headline_center=2  # Only skip once
    continue
  fi

  # tabularx → paragraphs (tables render too narrow in Word)
  if [[ "$line" =~ \\begin\{tabularx\} ]]; then
    in_table=1
    continue
  fi
  if [[ $in_table -ne 0 ]]; then
    if [[ "$line" =~ \\end\{tabularx\} ]]; then
      in_table=0
      continue
    fi
    # Skip table chrome
    [[ "$line" =~ ^\\toprule ]] && continue
    [[ "$line" =~ ^\\midrule ]] && continue
    [[ "$line" =~ ^\\bottomrule ]] && continue
    # Skip header row (bold column titles)
    [[ "$line" =~ ^\\textbf.*Risk.*Rating.*Assessment ]] && continue
    # Data rows: "Name & Rating & Assessment \\"
    if [[ "$line" =~ ^([^&]+)\&([^&]+)\&(.*)[[:space:]]*\\\\[[:space:]]*$ ]]; then
      risk_name=$(printf '%s' "${BASH_REMATCH[1]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
      risk_rating=$(printf '%s' "${BASH_REMATCH[2]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
      risk_text=$(printf '%s' "${BASH_REMATCH[3]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
      echo ""
      echo "\\paragraph*{${risk_name} --- ${risk_rating}}"
      echo "${risk_text}"
      echo ""
    else
      echo "$line"
    fi
    continue
  fi

  # Quote environments → standard quote
  [[ "$line" =~ ^\\begin\{customerquote\} ]] && { echo "\\begin{quote}"; continue; }
  [[ "$line" =~ ^\\end\{customerquote\} ]] && { echo "\\end{quote}"; continue; }
  [[ "$line" =~ ^\\begin\{spokespersonquote\} ]] && { echo "\\begin{quote}"; continue; }
  [[ "$line" =~ ^\\end\{spokespersonquote\} ]] && { echo "\\end{quote}"; continue; }

  # faqpair → paragraph heading
  if [[ "$line" =~ \\begin\{faqpair\}\{(.+)\} ]]; then
    faq_ctr=$((faq_ctr + 1))
    question="${BASH_REMATCH[1]}"
    label_part=""
    if [[ "$question" =~ (\\label\{[^}]+\})$ ]]; then
      label_part="${BASH_REMATCH[1]}"
      question="${question%"$label_part"}"
    fi
    echo "\\paragraph*{Q${faq_ctr}: ${question}}${label_part}"
    continue
  fi
  [[ "$line" =~ ^\\end\{faqpair\} ]] && { echo ""; continue; }

  # featureitem → standard list item
  if [[ "$line" =~ ^[[:space:]]*\\featureitem\{([^}]+)\}\{([^}]+)\}(.*) ]]; then
    feat_ctr=$((feat_ctr + 1))
    echo "  \\item \\textbf{F${feat_ctr}. ${BASH_REMATCH[1]}} --- ${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    continue
  fi

  # prsection → subsection
  if [[ "$line" =~ \\prsection\{([^}]+)\} ]]; then
    echo "\\subsection*{${BASH_REMATCH[1]}}"
    continue
  fi

  # Page breaks before major sections
  if [[ "$line" =~ \\section\*\{Risk\ Assessment\} ]] || [[ "$line" =~ \\section\*\{Feature\ Appendix\} ]]; then
    echo "\\newpage"
    echo "$line"
    continue
  fi

  # Pass through everything else
  echo "$line"

done < "$TEX_FILE" > "$BLOCK_OUT"

# ═══════════════════════════════════════════════════════════════════════
# Apply inline sed substitutions (cross-refs + cleanup) in one pass
# ═══════════════════════════════════════════════════════════════════════

sed -f "$SED_SCRIPT" "$BLOCK_OUT"
