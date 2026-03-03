---
description: Export the PR/FAQ as a Word document (.docx) via pandoc — no TeX installation required
argument-hint: "[filename.tex]"
allowed-tools: Bash(bash */export_prfaq_docx.sh *), Bash(bash scripts/export_prfaq_docx.sh *), Bash(pandoc --version), Read, Glob
---

# Export PR/FAQ to Word (.docx)

Convert the PR/FAQ LaTeX document into a Word file using pandoc. This provides a lightweight alternative to PDF compilation that does not require a ~4 GB TeX distribution.

## Steps

1. **Locate the .tex file.** Use `$ARGUMENTS` if provided, otherwise look for `prfaq.tex` or `*prfaq*.tex` in the current directory. If no `.tex` file is found, tell the user and stop.

2. **Check pandoc.** Run `pandoc --version` to confirm it's available. If not, tell the user:
   ```
   pandoc is required for DOCX export. Install it:
     macOS:  brew install pandoc
     Ubuntu: sudo apt install pandoc
     Other:  https://pandoc.org/installing.html
   ```

3. **Export.** Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/export_prfaq_docx.sh <file.tex>
   ```
   This preprocesses custom LaTeX environments, converts via pandoc, and produces a `.docx` file next to the original `.tex`.

4. **Report result.** Tell the user where the `.docx` file was written. Note that the Word output covers ~80% of the PDF's visual quality — styled headings, numbered FAQs and features, and clean body text — but does not include colored risk ratings, custom quote boxes, or the full typographic treatment of the LaTeX PDF.
