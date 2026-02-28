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

This command requires Claude Code Agent Teams. The plugin ships `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `.claude/settings.json`, so it should be enabled automatically. If it is not set in the environment, tell the user to ensure `.claude/settings.json` contains:

```json
{
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
}
```

Then restart Claude Code. Do not proceed without it — use `/prfaq:meeting` for manual moderation instead.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a path, use it. Otherwise, search for `prfaq.tex` in the project root using Glob. If no document exists, tell the user to run `/prfaq` first.

2. **Read the meeting guide.** Load `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/meeting-guide.md` for persona details and stage calibration. The hive meeting uses the same cast, reference guides, and hot spot ranking as the regular meeting.

3. **Run the pre-meeting scan.** Read the full `.tex` document. Extract `\prfaqstage{value}` to calibrate expectations. Identify 5-8 hot spots using the same criteria as the regular meeting (unsupported claims, vague language, thin evidence, risk rating mismatches, confidence/hedging gaps). Rank each as Critical, Warning, or Suggestion — calibrated to the document's stage.

4. **Classify each hot spot as a one-way or two-way door.** For each hot spot, determine whether the decision it implies is reversible (two-way door: positioning, scope, framing) or irreversible (one-way door: architecture, data model, public commitments). Mark each in the agenda.

5. **Show the agenda.** Present the hot spots ranked by severity with door classification. All items will be debated — the user does not select scope. Tell the user: "The hive will debate these autonomously. I'll present the consensus when they're done."

6. **Create the team and task list.** Create a team named `prfaq-hive`. Create one task per hot spot using TaskCreate, named `Debate: [hot spot title]` with the hot spot description and door classification. This gives the user visible progress during the autonomous run.

7. **Run the debate loop.** For each hot spot (processing sequentially, one at a time):

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
   - Persistent split on a one-way door → **escalate to user**. Present both sides' strongest single argument.
   - Persistent split on a two-way door → **bias for action**. The action side wins. Note the dissent in the summary so the user can revisit after learning more.

   Mark the hot spot task complete via TaskUpdate after resolution.

8. **Synthesize the debate.** For each hot spot, write a brief narrative (3-5 sentences) that shows which argument won and why. Name the winner and the loser. Do not soften — "Wei's scalability concern overruled Dana's push to ship" is better than "the group balanced speed and caution." Follow the synthesis voice guidelines from the meeting guide.

9. **Shut down the team.** Send a shutdown request to each teammate using SendMessage with `type: "shutdown_request"`. Wait for acknowledgment, then clean up the team.

10. **Present the consensus summary.** Show:
    - **Consensus decisions:** Items where the hive reached resolution. Show the decision (REVISE/KEEP), the door type, the winning argument, and the noted dissent (if any).
    - **Escalated decisions:** One-way door splits that require user input. Show both sides' strongest argument. Ask the user to decide via AskUserQuestion: REVISE / KEEP / DEFER.
    - **Revision queue:** Specific feedback directives for each REVISE decision, written to work as `/prfaq:feedback` input.

11. **Persist the summary.** Write to `./meetings/meeting-hive-summary-YYYY-MM-DD.md`. If that filename exists, append a counter (`-2`, `-3`, etc.). Use the same format as regular meeting summaries (see Phase 3b in the meeting guide), with `**Mode:** Hive (autonomous consensus, Agent Teams)` in the header and this decisions table schema:

    **Migration:** Before writing, use Glob to check for `meeting-summary-*.md` and `meeting-hive-summary-*.md` in the project root (same directory as the `.tex` file). If any are found, move them to `./meetings/` using the Read and Write tools (read content, write to new path, delete old file via Bash `rm`). Tell the user: "Moved N meeting summary file(s) to ./meetings/ for organization."

    | # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
    |---|----------|------|----------|------------|------------------|---------|
    | 1 | Example  | Two-way | REVISE | CONSENSUS | Wei: scalability concern | Dana: disagreed, committed |

    - **Door**: `one-way` or `two-way`
    - **Resolution**: `CONSENSUS`, `BIAS-FOR-ACTION`, or `ESCALATED`
    - Escalated decisions get a `User Action Required` section at the top of the summary listing each escalated item, the competing arguments, and a prompt for the user to choose REVISE / KEEP / DEFER

12. **Offer to apply revisions.** If the revision queue is non-empty, tell the user to run `/prfaq:feedback` (no arguments) to automatically discover this meeting summary and apply all directives.
