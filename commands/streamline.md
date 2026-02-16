---
description: Tighten a PR/FAQ by removing redundancy, weasel words, and bloat
argument-hint: "[optional: section to focus on]"
---

# Streamline PR/FAQ

Invoke the `streamliner` agent to tighten a completed PR/FAQ document.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a `.tex` file path, use it. If it names a section (e.g., "TAM section"), note it for focused editing. If no argument is given, search for `prfaq.tex` in the project root.

2. **Invoke the streamliner agent** using the Task tool with `subagent_type: "prfaq:streamliner"`. Pass the file path and any section focus in the prompt.

3. **Present the results** to the user. The streamliner reports:
   - Word count reduction (before/after)
   - Changes by category (redundancy, weasel words, phrase compression, throat-clearing)
   - Sentences it considered cutting but kept (for user decision)

4. **Recompile the PDF.** Run `bash scripts/compile_prfaq.sh <path>` and verify zero overfull hbox warnings. If any appear, fix them (see SKILL.md Phase 4 for common fixes).

5. **Offer a follow-up.** Ask if the user wants to review the diff, restore any cuts, or run a peer review on the tightened version.
