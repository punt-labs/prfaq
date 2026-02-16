---
description: Research evidence for PR/FAQ claims and generate biblatex citations
argument-hint: "[claim or topic or path/to/prfaq.tex]"
---

# Research Evidence for PR/FAQ

Invoke the `researcher` agent to find evidence for claims in a PR/FAQ document.

## Steps

1. **Determine the input.** If `$ARGUMENTS` specifies a `.tex` file path, pass it to the researcher to extract and verify all `[CITATION NEEDED]` markers and factual claims. If it specifies a claim or topic, pass that directly. If no argument is given, search for `prfaq.tex` in the project root and pass its path.

2. **Invoke the researcher agent** using the Task tool with `subagent_type: "prfaq:researcher"`. Pass the file path, claim, or topic in the prompt.

3. **Present the results** to the user. The researcher returns:
   - Evidence found per claim (with verdict: supported/unsupported/contradicted)
   - Bibliography entries ready to append to the `.bib` file
   - Research gaps where no evidence was found

   The researcher automatically saves its findings to `./research/research-YYYY-MM-DD-TOPIC.md`. Future runs reuse cached results instead of re-searching the web.

4. **Offer to update the document.** If the researcher found new sources:
   - Append new `.bib` entries to the bibliography file
   - Add `\cite{}` commands to the `.tex` file where claims now have sources
   - Replace `[CITATION NEEDED]` markers with proper citations
   - Recompile the PDF
