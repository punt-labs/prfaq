---
description: Run a simulated PR/FAQ review meeting with agentic personas
argument-hint: "[path/to/prfaq.tex]"
allowed-tools: Bash(mkdir -p meetings), Read, Write, Glob, Grep
---

# PR/FAQ Review Meeting

Run an interactive review meeting where four personas — a principal engineer, a target customer, a skeptical executive, and a builder-visionary — debate the weak spots in your PR/FAQ document. You are the PM and final decision-maker.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a path, use it. Otherwise, search for `prfaq.tex` in the project root using Glob. If no document exists, tell the user to run `/prfaq` first — the meeting validates an existing document, it doesn't generate one.

2. **Read the meeting guide.** Load `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/meeting-guide.md` for the full meeting flow, synthesis guidelines, and persona details.

3. **Run the pre-meeting scan.** Read the full `.tex` document. Extract `\prfaqstage{value}` to calibrate expectations (see Stage Calibration in the meeting guide). Identify 5-8 hot spots using the four risk-lens questions first (feasibility, value/customer reality, strategic fit/viability, ambition — see Phase 0 in the meeting guide) — documentation issues (unsupported claims, vague language, thin evidence, hedging gaps) are valid but must be at most half the agenda. Rank each as Critical, Warning, or Suggestion — calibrated to the document's stage.

4. **Get the opening assessment.** Launch a single `prfaq:meeting-executive` (Alex) agent, standalone, with the document's stage, the Risk Assessment table, and the hot spot titles/severities from step 3. Tell Alex explicitly: this is a meeting-opening assessment, not a section evaluation — reply in 3-5 sentences of continuous prose, not the structured format (see the Exception in `meeting-executive.md`). Ask for a 3-5 sentence holistic opening read (see Phase 0b in the meeting guide). Present it to the user before the agenda. If the agent call fails, times out, or returns ungrounded content, tell the user the opening assessment could not be generated and proceed to the agenda without one.

5. **Present the agenda.** Show the user the hot spots ranked by severity and offer scope options via AskUserQuestion:
   - Full meeting (all items)
   - Critical only
   - Pick specific items
   - Skip meeting (show written report via peer-reviewer instead)

6. **Run the debate loop.** For each selected agenda item:
   a. Quote the specific text under discussion
   b. Launch all four persona agents in parallel using the Task tool:
      - `subagent_type: "prfaq:meeting-engineer"` (Wei)
      - `subagent_type: "prfaq:meeting-customer"` (Priya)
      - `subagent_type: "prfaq:meeting-executive"` (Alex)
      - `subagent_type: "prfaq:meeting-builder"` (Dana)
   c. Synthesize their responses into a dramatic debate narrative (not concatenation). Ground every sentence in a specific from the document — a quoted phrase, a real number, a named competitor or customer segment — never an abstract metaphor, and never a reference to another hot spot's position in this meeting. See "Ground Every Line in Specifics" and "Never Reference the Meeting's Own Structure" in the meeting guide.
   d. Present the decision via AskUserQuestion: Revise / Keep as-is / Research / Defer
   e. Show cascade consequences (which other sections are affected)

7. **Get the closing assessment.** Once every selected agenda item has a decision — or the user exits early (see Early Exit in the meeting guide) — launch a single `prfaq:meeting-executive` (Alex) agent, standalone, with the opening assessment and the full list of decisions actually made (hot spot, decision, one-line rationale each). On an early exit, tell Alex explicitly the meeting was cut short and exclude "Not discussed" items from the decision list. Tell Alex explicitly: this is a meeting-closing assessment, not a section evaluation — reply in 3-5 sentences of continuous prose, not the structured format (see the Exception in `meeting-executive.md`). Ask for a 3-5 sentence closing read ending in a concrete next-step/reconvene proposal (see Phase 2b in the meeting guide). Present it before the mechanical summary. If the agent call fails, times out, or returns ungrounded content, tell the user the closing assessment could not be generated and proceed to step 8 without one.

8. **Present the post-meeting summary.** List all decisions, build a revision queue with specific feedback directives for `/prfaq:feedback`, and note deferred and not-discussed items. (The opening and closing assessments were already shown in steps 4 and 7 — this step is the mechanical decisions log, not a repeat of them.)

9. **Persist the summary.** Write the meeting summary to `./meetings/meeting-summary-YYYY-MM-DD.md` (today's date). If that file already exists, append a counter (`-2`, `-3`, etc.). See Phase 3b in the meeting guide for the full file format, including the `## Overall Assessment` section. Tell the user where the file was saved.

   **Migration:** Before writing, use Glob to check for `meeting-summary-*.md` and `meeting-hive-summary-*.md` in the project root (same directory as the `.tex` file). If any are found, move them to `./meetings/` using the Read and Write tools (read content, write to new path, delete old file via Bash `rm`). Tell the user: "Moved N meeting summary file(s) to ./meetings/ for organization."

10. **Offer to apply revisions.** If the revision queue is non-empty, tell the user to run `/prfaq:feedback` (no arguments) to automatically discover this meeting summary and apply all directives sequentially.
