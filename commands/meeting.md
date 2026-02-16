---
description: Run a simulated PR/FAQ review meeting with agentic personas
argument-hint: "[path/to/prfaq.tex]"
---

# PR/FAQ Review Meeting

Run an interactive review meeting where four personas — a principal engineer, a target customer, a skeptical executive, and a builder-visionary — debate the weak spots in your PR/FAQ document. You are the PM and final decision-maker.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a path, use it. Otherwise, search for `prfaq.tex` in the project root using Glob. If no document exists, tell the user to run `/prfaq` first — the meeting validates an existing document, it doesn't generate one.

2. **Read the meeting guide.** Load `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/meeting-guide.md` for the full meeting flow, synthesis guidelines, and persona details.

3. **Run the pre-meeting scan.** Read the full `.tex` document. Extract `\prfaqstage{value}` to calibrate expectations (see Stage Calibration in the meeting guide). Identify 5-8 hot spots: sections with unsupported claims, vague language, thin evidence, risk rating mismatches, or gaps between press release confidence and FAQ hedging. Rank each as Critical, Warning, or Suggestion — calibrated to the document's stage.

4. **Present the agenda.** Show the user the hot spots ranked by severity and offer scope options via AskUserQuestion:
   - Full meeting (all items)
   - Critical only
   - Pick specific items
   - Skip meeting (show written report via peer-reviewer instead)

5. **Run the debate loop.** For each selected agenda item:
   a. Quote the specific text under discussion
   b. Launch all four persona agents in parallel using the Task tool:
      - `subagent_type: "prfaq:meeting-engineer"` (Wei)
      - `subagent_type: "prfaq:meeting-customer"` (Priya)
      - `subagent_type: "prfaq:meeting-executive"` (Alex)
      - `subagent_type: "prfaq:meeting-builder"` (Dana)
   c. Synthesize their responses into a dramatic debate narrative (not concatenation)
   d. Present the decision via AskUserQuestion: Revise / Keep as-is / Research / Defer
   e. Show cascade consequences (which other sections are affected)

6. **Present the post-meeting summary.** List all decisions, build a revision queue with specific feedback directives for `/prfaq:feedback`, and note deferred items.

7. **Persist the summary.** Write the meeting summary to a markdown file in the same directory as the `.tex` document. Use the filename `meeting-summary-YYYY-MM-DD.md` (today's date). If that file already exists, append a counter (`-2`, `-3`, etc.). See Phase 3b in the meeting guide for the full file format. Tell the user where the file was saved.

8. **Offer to apply revisions.** If the revision queue is non-empty, tell the user to run `/prfaq:feedback` (no arguments) to automatically discover this meeting summary and apply all directives sequentially.
