---
description: Incorporate feedback into PR/FAQ and redraft affected sections
argument-hint: "<feedback text>"
---

# Incorporate Feedback into PR/FAQ

Interpret user feedback, trace cascading effects across all affected sections, redraft surgically, recompile, and validate with peer review.

## Steps

1. **Parse the feedback.** Extract the feedback text from `$ARGUMENTS`. If empty, ask the user what feedback they want to apply.

2. **Find the document.** Search for `prfaq.tex` in the project root using Glob. If not found, ask the user for the path.

3. **Invoke the feedback agent** using the Task tool with `subagent_type: "prfaq:feedback"`. Pass:
   - The feedback text
   - The absolute path to the `.tex` file
   - The absolute path to the `.bib` file (same directory, same basename as `.tex`)

4. **Present the changes.** The feedback agent returns:
   - Interpreted feedback (what change was requested)
   - Impact analysis (which sections were affected and why)
   - Edits made (section-by-section before/after with rationale)
   - Citation changes (new `\cite{}` needed, `[CITATION NEEDED]` markers)
   - Cross-reference integrity status

5. **Recompile the PDF.** Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/compile_prfaq.sh <path-to-tex-file>
   ```
   If compilation fails, read the LaTeX log, identify the issue, and fix it before proceeding.

6. **Invoke peer review.** Automatically launch the peer-reviewer agent using the Task tool with `subagent_type: "prfaq:peer-reviewer"`, passing the same `.tex` file path. Present the review results alongside the changes summary.

7. **Offer iteration.** Ask if the user wants to apply more feedback, address review issues, or proceed. If they provide more feedback, loop back to step 3.
