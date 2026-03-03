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

  # Metadata after \begin{document}
  if [[ "$line" =~ ^\\begin\{document\} ]]; then
    echo "$line"
    if [[ -n "$stage" || -n "$version_major" ]]; then
      echo ""
      echo "\\begin{center}"
      printf '{\\footnotesize Stage: %s \\enspace\\textbar\\enspace v%s.%s}\n' \
        "$stage" "$version_major" "$version_minor"
      echo "\\end{center}"
      echo "\\vspace{0.5em}"
    fi
    continue
  fi

  # tabularx → tabular
  if [[ "$line" =~ \\begin\{tabularx\} ]]; then
    in_table=1
    echo "\\begin{tabular}{l l p{4in}}"
    continue
  fi
  if [[ $in_table -ne 0 ]]; then
    if [[ "$line" =~ \\end\{tabularx\} ]]; then
      in_table=0
      echo "\\end{tabular}"
      continue
    fi
    echo "$line"
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

  # Pass through everything else
  echo "$line"

done < "$TEX_FILE" > "$BLOCK_OUT"

# ═══════════════════════════════════════════════════════════════════════
# Apply inline sed substitutions (cross-refs + cleanup) in one pass
# ═══════════════════════════════════════════════════════════════════════

sed -f "$SED_SCRIPT" "$BLOCK_OUT"
