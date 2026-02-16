---
description: Incorporate feedback into PR/FAQ and redraft affected sections
argument-hint: "[feedback text or path/to/meeting-summary.md]"
---

# Incorporate Feedback into PR/FAQ

Interpret user feedback, trace cascading effects across all affected sections, redraft surgically, recompile, and validate with peer review. Supports single feedback or batch mode from meeting summary files.

## Steps

1. **Find the document.** Search for `prfaq.tex` in the project root using Glob. If not found, ask the user for the path.

2. **Determine mode.** Three branches based on `$ARGUMENTS`:

   **a) Feedback text** — `$ARGUMENTS` is non-empty and does NOT end in `.md`: treat it as literal feedback text (single mode). Skip step 3, proceed to step 4.

   **b) Explicit file path** — `$ARGUMENTS` is a single file path ending in `.md` and the file exists: treat it as the meeting summary file path (batch mode). Proceed to step 3. If the file does not exist, treat `$ARGUMENTS` as feedback text (single mode, same as branch a).

   **c) Auto-discover** — `$ARGUMENTS` is empty: search for `meeting-summary-*.md` files in the same directory as the `.tex` document. If one or more are found, show the most recent one's filename and ask the user via AskUserQuestion:
   - **Apply all directives** from this file (batch mode — proceed to step 3, skip its confirmation)
   - **Enter feedback manually** (single mode, ask for text, skip step 3, proceed to step 4)
   - **Cancel**

   If no meeting summary files are found, ask the user what feedback they want to apply (single mode — skip step 3, proceed to step 4).

3. **Parse batch directives (batch mode only).** Read the meeting summary file (from the path in step 2b or auto-discovered in step 2c) and extract directives from the `## Revision Queue (for /prfaq:feedback)` section. Each directive is a `### Directive N: Title` header followed by its body text.

   If the user already chose "Apply all directives" in step 2c, skip confirmation and proceed to step 4. Otherwise, confirm with the user via AskUserQuestion:
   - **Apply all N directives**
   - **Pick specific directives** (show numbered list, let user choose)
   - **Cancel**

4. **Apply feedback.**

   **Single mode:** Invoke the feedback agent once using the Task tool with `subagent_type: "prfaq:feedback"`. Pass:
   - The feedback text
   - The absolute path to the `.tex` file
   - The absolute path to the `.bib` file (same directory, same basename as `.tex`)

   Present the full output: interpreted feedback, impact analysis, edits made, citation changes, cross-reference integrity.

   **Batch mode:** For each selected directive, in order:
   - Show progress: `[N/M] Applying: "Title"`
   - Invoke the feedback agent using the Task tool with `subagent_type: "prfaq:feedback"`, passing the directive text, `.tex` path, and `.bib` path
   - Show a brief summary of sections edited (2-3 lines, not the full agent output)

   After all directives are applied, show a consolidated summary: total directives applied, all sections modified across all directives.

5. **Bump the document version.** After all feedback is applied (single or batch), increment `\prfaqversion{M}{m}` in the `.tex` preamble:

   Read the current version using Grep for `\prfaqversion{`. Evaluate the scope of changes from the feedback agent's output:

   - **Minor bump** (M stays, m+1): Evidence additions, risk re-ratings, wording improvements, research additions, localized edits within existing sections.
   - **Major bump** (M+1, minor resets to 0): Structural shifts — customer persona change, problem reframe, business model change, scope change, new or removed FAQ sections, or stage transition.

   Use judgment: if the feedback fundamentally changes who the document is about, what problem it solves, or how it makes money, that's a major bump. Everything else is minor.

   Use the Edit tool to update `\prfaqversion{M}{m}` with the new values. Tell the user: `Version: vM.m → vM'.m'`

6. **Recompile the PDF.** Run once at the end, after all directives have been applied:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/compile_prfaq.sh <path-to-tex-file>
   ```
   If compilation fails, read the LaTeX log, identify the issue, and fix it before proceeding.

7. **Invoke peer review.** Run once. Launch the peer-reviewer agent using the Task tool with `subagent_type: "prfaq:peer-reviewer"`, passing the same `.tex` file path. Present the review results alongside the changes summary.

8. **Offer iteration.** Ask if the user wants to apply more feedback, address review issues, or proceed. If they provide more feedback, loop back to step 4 (single mode).
