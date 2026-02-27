---
description: Generate a stage-colored badge and embed it in your README
argument-hint: "[path/to/prfaq.tex]"
---

# Embed PR/FAQ Badge in README

Generate a shields.io badge that shows your document's Working Backwards stage
and links to the compiled PDF. Embed it in the project's README.

## Steps

1. **Find the document.** If `$ARGUMENTS` contains a `.tex` path, use that.
   Otherwise, use Glob to find `prfaq.tex` or `*.tex` files containing
   `\prfaqstage` in the current project directory.

2. **Extract metadata.** Use Grep to extract from the `.tex` file:
   - `\prfaqstage{value}` — the document stage (hypothesis, validated, or growth)
   - `\prfaqversion{M}{m}` — the document version (e.g., 1.0)

3. **Map stage to color.**
   - `hypothesis` → `lightgrey`
   - `validated` → `blue`
   - `growth` → `brightgreen`
   - Unknown or missing → `lightgrey`

4. **Determine the PDF link.** Use the `.tex` file path to derive the `.pdf`
   path. The link target should be a relative path from the README location
   (typically `./prfaq.pdf`).

5. **Generate badge markdown.** The shields.io URL format is:

   ```
   https://img.shields.io/badge/Working_Backwards-STAGE-COLOR
   ```

   The full markdown is:

   ```markdown
   [![Working Backwards](https://img.shields.io/badge/Working_Backwards-STAGE-COLOR)](./BASENAME.pdf)
   ```

6. **Embed in README.** Read the project's `README.md` and embed the badge.

   - **If an existing Working Backwards badge is found**
     (`img.shields.io/badge/Working_Backwards`): replace it in place with the
     updated badge (the stage may have changed).

   - **If no Working Backwards badge exists but other shields.io badges do:**
     add the Working Backwards badge on the line after the last existing badge
     line.

   - **If no badge section exists:** insert the badge on its own line
     immediately after the first `# Heading` line, with a blank line after it.

   - **If no README.md exists:** create one with `# {project-directory-name}`
     as the heading and the badge on the next line.

7. **Report.** Show the badge markdown that was embedded. Remind the user to
   commit the README change.
