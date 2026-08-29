---
description: Run an autonomous PR/FAQ review meeting where four personas debate and reach consensus without user intervention
argument-hint: "[path/to/prfaq.tex]"
allowed-tools: Bash(mkdir -p meetings), Read, Write, Glob, Grep
---

# PR/FAQ Hive Meeting

Run an autonomous review meeting where four personas — a principal engineer, a target customer, a skeptical executive, and a builder-visionary — debate the weak spots in your PR/FAQ document and reach consensus without you moderating each decision. You review the final consensus, not each individual debate.

This is the "team meeting without the boss" variant of `/prfaq:meeting`.

## Decision Philosophy

Amazon's Leadership Principles seek **real debate, not social cohesion**. Arguments must win or lose — the hive does not compromise or blend positions. When Wei says "this won't scale" and Dana says "ship it anyway," one of them wins. The loser disagrees and commits.

**One-way vs two-way doors** determine how the hive weighs caution vs. action:

- **One-way door** (irreversible): Architecture choices, public API contracts, data model commitments, third-party lock-in. On these, Wei and Alex's caution carries extra weight. The bar for overriding a feasibility or strategic concern is higher.
- **Two-way door** (reversible): Feature scope, positioning language, risk rating levels, FAQ framing. On these, Dana's "ship and iterate" and Priya's "does this work for me?" carry extra weight. Bias for action.

When classifying a decision, look at Wei's IRREVERSIBLE DECISIONS section — if he identifies one, it's a one-way door.

## Prerequisites

This command requires Claude Code Agent Teams, which is off unless the project enables it. `/prfaq:permissions` sets it. If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is not set in the environment, tell the user to run `/prfaq:permissions`, or to add this to the project's `.claude/settings.json` by hand:

```json
{
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
}
```

Then restart Claude Code. Do not proceed without it — use `/prfaq:meeting` for manual moderation instead.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a path, use it. Otherwise, search for `prfaq.tex` in the project root using Glob. If no document exists, tell the user to run `/prfaq` first.

2. **Read the meeting guide.** Load `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/meeting-guide.md` for persona details and stage calibration. The hive meeting uses the same cast, reference guides, and hot spot ranking as the regular meeting.

3. **Run the pre-meeting scan.** Read the full `.tex` document. Extract `\prfaqstage{value}` to calibrate expectations. Identify 5-8 hot spots using the same criteria as the regular meeting — the four risk-lens questions (feasibility, value/customer reality, strategic fit/viability, ambition) come first; documentation and evidence issues (unsupported claims, vague language, thin evidence, hedging gaps) are valid but must be at most half the agenda. See the meeting guide's Phase 0 guardrail. Rank each as Critical, Warning, or Suggestion — calibrated to the document's stage.

4. **Classify each hot spot as a one-way or two-way door.** For each hot spot, determine whether the decision it implies is reversible (two-way door: positioning, scope, framing) or irreversible (one-way door: architecture, data model, public commitments). Mark each in the agenda.

5. **Get the opening assessment.** Launch a single `prfaq:meeting-executive` (Alex) agent, standalone (not part of the `prfaq-hive` team — there's no back-and-forth to coordinate for a solo read), with the document's stage, the Risk Assessment table, and the hot spot titles/severities/door classifications from steps 3-4. Tell Alex explicitly: this is a meeting-opening assessment, not a section evaluation — reply in 3-5 sentences of continuous prose, not the structured format (see the Exception in `meeting-executive.md`). Ask for a 3-5 sentence holistic opening read, organized around Phase 0b's three questions (problem worth solving / strong and differentiated solution / build it now) in the meeting guide. Present it to the user before the agenda. If the agent call fails, times out, or returns ungrounded content, tell the user the opening assessment could not be generated and proceed to the agenda without one.

6. **Show the agenda.** Present the hot spots ranked by severity with door classification. All items will be debated — the user does not select scope. Tell the user: "The hive will debate these autonomously. I'll present the consensus when they're done."

7. **Create the team and task list.** Create a team named `prfaq-hive`. Create one task per hot spot using TaskCreate, named `Debate: [hot spot title]` with the hot spot description and door classification. This gives the user visible progress during the autonomous run.

8. **Run the debate loop.** For each hot spot (processing sequentially, one at a time):

   Mark the hot spot task in-progress via TaskUpdate.

   **Round 1 — Independent evaluation:**
   Spawn all four persona agents as teammates using the Task tool with `team_name: "prfaq-hive"`:
   - `subagent_type: "prfaq:meeting-engineer"`, `name: "wei"` (Wei)
   - `subagent_type: "prfaq:meeting-customer"`, `name: "priya"` (Priya)
   - `subagent_type: "prfaq:meeting-executive"`, `name: "alex"` (Alex)
   - `subagent_type: "prfaq:meeting-builder"`, `name: "dana"` (Dana)

   Launch all four in parallel. Each receives in their spawn prompt:
   - The hot spot description, severity, and door classification
   - The exact quoted text from the document section under debate
   - The document stage (`\prfaqstage` value)
   - Meeting state so far: decisions made on prior hot spots (or "None — this is the first hot spot")
   - Instruction: "Produce your standard structured response using your mandatory format, then send the complete response to the team lead using the SendMessage tool."

   Collect all four structured positions from their responses.

   **Resolve the debate — arguments win, not averages:**

   Count APPROVE / ITERATE / REJECT across all four positions. Define the **action side** as APPROVE or ITERATE; define the **caution side** as REJECT. Apply door-weighted resolution:

   *Two-way door (reversible):*
   - 3-1 or 4-0 in any direction → majority wins
   - 2-2 split → bias for action (ITERATE, not REJECT). Two-way doors are reversible — ship and learn. Proceed to Round 2 only if the caution side raises a specific falsifiable concern.

   *One-way door (irreversible):*
   - 4-0 APPROVE → KEEP
   - Any REJECT from Wei or Alex → must be addressed regardless of other votes. Proceed to Round 2.
   - 3-1 where the dissenter is Wei or Alex → proceed to Round 2 (their caution carries weight on irreversible decisions)
   - 3-1 where the dissenter is Dana or Priya → majority wins

   **Round 2 — Rebuttal (when required):**
   Spawn all four persona agents again as teammates with ALL Round 1 positions included in each spawn prompt:

   "Here are all four positions from Round 1:
   - Wei: [full Round 1 response]
   - Priya: [full Round 1 response]
   - Alex: [full Round 1 response]
   - Dana: [full Round 1 response]

   The question is a [one-way/two-way] door. Respond to the strongest argument against your position. You may change your verdict if genuinely persuaded, but do not compromise — either your concern stands or it doesn't. Produce your structured response, then send it to the team lead using the SendMessage tool."

   Resolve after Round 2:
   - Clear majority → that side wins. The minority disagrees and commits.
   - Persistent split on a one-way door → mark the hot spot `ESCALATED` and record both sides' strongest single argument. **Do not ask the user yet** — the hive keeps running autonomously; step 11 resolves every escalation in one batch after the full debate loop finishes.
   - Persistent split on a two-way door → **bias for action**. The action side wins. Note the dissent in the summary so the user can revisit after learning more.

   Mark the hot spot task complete via TaskUpdate after resolution.

9. **Synthesize the debate.** For each hot spot, write a brief narrative (3-5 sentences) that shows which argument won and why. Name the winner and the loser. Do not soften — "Wei's scalability concern overruled Dana's push to ship" is better than "the group balanced speed and caution." For a hot spot marked `ESCALATED`, there is no winner yet — state both sides' strongest argument instead and note that the call is the user's, pending step 11; do not fabricate a winner. Ground every sentence in a specific from the document (a quoted phrase, a real number, a named competitor or customer segment) — never in an abstract metaphor standing in for the reasoning, and never in a reference to another hot spot's position in this meeting ("third hot spot in a row," "unlike the previous item"). A cross-hot-spot pattern, if one emerges, belongs in the summary's Notes section, not spoken in a persona's voice. Follow the synthesis voice guidelines from the meeting guide.

10. **Shut down the team.** Send a shutdown request to each teammate using SendMessage with `type: "shutdown_request"`. Wait for acknowledgment, then clean up the team.

11. **Resolve any escalated decisions.** If any hot spot's resolution is `ESCALATED` (a persistent one-way-door split after Round 2), present both sides' strongest argument to the user now, one at a time or batched, via AskUserQuestion: REVISE / KEEP / DEFER.

    - **REVISE or KEEP:** record it as that hot spot's final decision.
    - **DEFER:** this hot spot stays unresolved — it is *not* a final decision. Track it separately as a deferred item; do not pass it to step 12 as if decided.

    **This must happen before step 12** — the closing assessment needs the complete, final set of REVISE/KEEP decisions (deferred items are handled separately, not folded into that set). If nothing escalated, skip this step.

12. **Get the closing assessment.** Launch a single `prfaq:meeting-executive` (Alex) agent, standalone, with the opening assessment and the full list of *final* REVISE/KEEP decisions made across every hot spot (title, decision, one-line rationale each) — including the resolutions from step 11, but excluding any item deferred in step 11. If one or more items were deferred, tell Alex how many and let the closing read acknowledge them honestly rather than assume full closure. Tell Alex explicitly: this is a meeting-closing assessment, not a section evaluation — reply in 3-5 sentences of continuous prose, not the structured format (see the Exception in `meeting-executive.md`). Ask for a 3-5 sentence closing read that revisits Phase 2b's three questions in light of the meeting's decisions, ending in a concrete next-step/reconvene proposal (see Phase 2b in the meeting guide). If the agent call fails, times out, or returns ungrounded content, tell the user the closing assessment could not be generated and proceed to step 13 without one.

13. **Present the consensus summary.** Show:
    - **Overall assessment:** The opening and closing reads from steps 5 and 12.
    - **Consensus decisions:** Items where the hive reached resolution. Show the decision (REVISE/KEEP), the door type, the winning argument, and the noted dissent (if any).
    - **Escalated decisions (resolved):** Items that were escalated in step 11 and resolved REVISE or KEEP. Show both sides' strongest argument and the user's resolution — this is now a historical record, not a live prompt, since the resolution already happened.
    - **Deferred decisions:** Items escalated in step 11 where the user chose DEFER. Show both sides' strongest argument and what needs to happen before deciding.
    - **Revision queue:** Specific feedback directives for each REVISE decision, written to work as `/prfaq:feedback` input.

14. **Persist the summary.** Write to `./meetings/meeting-hive-summary-YYYY-MM-DD.md`. If that filename exists, append a counter (`-2`, `-3`, etc.). Use the same format as regular meeting summaries (see Phase 3b in the meeting guide), including the `## Overall Assessment` section, with `**Mode:** Hive (autonomous consensus, Agent Teams)` in the header and this decisions table schema:

    **Migration:** Before writing, use Glob to check for `meeting-summary-*.md` and `meeting-hive-summary-*.md` in the project root (same directory as the `.tex` file). If any are found, move them to `./meetings/` using the Read and Write tools (read content, write to new path, delete old file via Bash `rm`). Tell the user: "Moved N meeting summary file(s) to ./meetings/ for organization."

    | # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
    |---|----------|------|----------|------------|------------------|---------|
    | 1 | Example  | Two-way | REVISE | CONSENSUS | Wei: scalability concern | Dana: disagreed, committed |
    | 2 | Example  | One-way | DEFER | ESCALATED | — (escalated, no winner) | — (escalated, no winner) |

    - **Door**: `one-way` or `two-way`
    - **Decision**: `REVISE`, `KEEP`, or `DEFER` (a deferred row has no closing-assessment input — see step 12)
    - **Resolution**: `CONSENSUS`, `BIAS-FOR-ACTION`, or `ESCALATED` (escalated rows resolved REVISE or KEEP in step 11, before this file was written; an escalated row resolved DEFER instead is still `ESCALATED` here, but lists in `## Deferred Items` below too, not just this table)
    - A `DEFER` row's **Winning Argument** and **Dissent** cells are always `— (escalated, no winner)` — an escalated hot spot never produced a winner (see step 9), so there is nothing to name in either column
    - Items that were escalated and resolved REVISE/KEEP get an `Escalated Decisions (Resolved)` section near the top of the summary, recording each item's competing arguments and the user's resolution from step 11
    - Items that were escalated and deferred get a `## Deferred Items` entry, in the same format as the meeting guide's Phase 3b template (see Phase 3b) — do not re-derive the field list here

15. **Offer to apply revisions.** If the revision queue is non-empty, tell the user to run `/prfaq:feedback` (no arguments) to automatically discover this meeting summary and apply all directives.
