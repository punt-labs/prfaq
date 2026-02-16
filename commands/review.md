---
description: Peer review a PR/FAQ document for quality and decision readiness
argument-hint: "[path/to/prfaq.tex]"
---

# Peer Review PR/FAQ

Invoke the `peer-reviewer` agent to critically evaluate a PR/FAQ document against Working Backwards principles and the Kahneman decision quality framework.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a path, use it. Otherwise, search for `prfaq.tex` in the project root.

2. **Launch the peer-reviewer agent** using the Task tool with `subagent_type: "prfaq:peer-reviewer"`. Pass the file path in the prompt. The peer reviewer reads `\prfaqstage{}` from the document and calibrates its evidence expectations accordingly.

3. **Present the results** to the user. The peer reviewer returns:
   - Overall assessment (PASS / ITERATE / REJECT)
   - Critical issues and warnings with specific locations and recommendations
   - Document strengths
   - Ordered next steps

4. **Offer to iterate.** If the review flags issues, ask the user which they want to address. For accepted issues, make the revisions to the `.tex` file, recompile, and offer to re-run the review.
