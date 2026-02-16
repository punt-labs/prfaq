---
description: Run an autonomous PR/FAQ review meeting where four personas debate and reach consensus without user intervention
argument-hint: "[path/to/prfaq.tex]"
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

This command requires claude-flow for hive-mind consensus orchestration. If `mcp__claude-flow__hive-mind_init` is not available, tell the user to install claude-flow (`npm install -g claude-flow`) and re-run the installer (`bash install.sh`) to register it as an MCP server, then restart Claude Code. Do not proceed without it — use `/prfaq:meeting` for manual moderation instead.

## Steps

1. **Find the document.** If `$ARGUMENTS` specifies a path, use it. Otherwise, search for `prfaq.tex` in the project root using Glob. If no document exists, tell the user to run `/prfaq` first.

2. **Read the meeting guide.** Load `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/meeting-guide.md` for persona details and stage calibration. The hive meeting uses the same cast, reference guides, and hot spot ranking as the regular meeting.

3. **Run the pre-meeting scan.** Read the full `.tex` document. Extract `\prfaqstage{value}` to calibrate expectations. Identify 5-8 hot spots using the same criteria as the regular meeting (unsupported claims, vague language, thin evidence, risk rating mismatches, confidence/hedging gaps). Rank each as Critical, Warning, or Suggestion — calibrated to the document's stage.

4. **Classify each hot spot as a one-way or two-way door.** For each hot spot, determine whether the decision it implies is reversible (two-way door: positioning, scope, framing) or irreversible (one-way door: architecture, data model, public commitments). Mark each in the agenda.

5. **Show the agenda.** Present the hot spots ranked by severity with door classification. All items will be debated — the user does not select scope. Tell the user: "The hive will debate these autonomously. I'll present the consensus when they're done."

6. **Initialize the hive-mind.**
   ```
   mcp__claude-flow__hive-mind_init(queenId: "prfaq-meeting", topology: "mesh")
   mcp__claude-flow__hive-mind_memory(action: "set", key: "document-stage", value: "<stage>")
   mcp__claude-flow__hive-mind_memory(action: "set", key: "hot-spots", value: "<JSON array of hot spots with door classification>")
   ```

7. **Run the debate loop.** For each hot spot, run up to two rounds:

   **Round 1 — Independent evaluation:**
   Launch all four persona agents in parallel using the Task tool (same agents as `/prfaq:meeting`):
   - `subagent_type: "prfaq:meeting-engineer"` (Wei)
   - `subagent_type: "prfaq:meeting-customer"` (Priya)
   - `subagent_type: "prfaq:meeting-executive"` (Alex)
   - `subagent_type: "prfaq:meeting-builder"` (Dana)

   Each receives the hot spot description, the relevant document section, the door classification, and meeting state so far.

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
   Re-launch all four persona agents with ALL Round 1 positions included. Prompt: "Here are all four positions from Round 1. [positions] The question is a [one-way/two-way] door. Respond to the strongest argument against your position. You may change your verdict if genuinely persuaded, but do not compromise — either your concern stands or it doesn't."

   Resolve after Round 2:
   - Clear majority → that side wins. The minority disagrees and commits.
   - Persistent split on a one-way door → **escalate to user**. Present both sides' strongest single argument.
   - Persistent split on a two-way door → **bias for action**. The action side wins. Note the dissent in the summary so the user can revisit after learning more.

   **Hive-mind integration:**
   After Round 1, store positions in shared memory:
   ```
   mcp__claude-flow__hive-mind_memory(action: "set", key: "hotspot-N-wei", value: "<position>")
   mcp__claude-flow__hive-mind_memory(action: "set", key: "hotspot-N-priya", value: "<position>")
   mcp__claude-flow__hive-mind_memory(action: "set", key: "hotspot-N-alex", value: "<position>")
   mcp__claude-flow__hive-mind_memory(action: "set", key: "hotspot-N-dana", value: "<position>")
   ```
   Use consensus for formal voting:
   ```
   mcp__claude-flow__hive-mind_consensus(action: "propose", type: "meeting-decision", value: "<proposed resolution based on door-weighted rules>")
   ```

8. **Synthesize the debate.** For each hot spot, write a brief narrative (3-5 sentences) that shows which argument won and why. Name the winner and the loser. Do not soften — "Wei's scalability concern overruled Dana's push to ship" is better than "the group balanced speed and caution." Follow the synthesis voice guidelines from the meeting guide.

9. **Shutdown the hive-mind.**
   ```
   mcp__claude-flow__hive-mind_shutdown(queenId: "prfaq-meeting")
   ```

10. **Present the consensus summary.** Show:
    - **Consensus decisions:** Items where the hive reached resolution. Show the decision (REVISE/KEEP), the door type, the winning argument, and the noted dissent (if any).
    - **Escalated decisions:** One-way door splits that require user input. Show both sides' strongest argument. Ask the user to decide via AskUserQuestion: REVISE / KEEP / DEFER.
    - **Revision queue:** Specific feedback directives for each REVISE decision, written to work as `/prfaq:feedback` input.

11. **Persist the summary.** Write to `meeting-hive-summary-YYYY-MM-DD.md` in the same directory as the `.tex` file. If that filename exists, append a counter (`-2`, `-3`, etc.). Use the same format as regular meeting summaries (see Phase 3b in the meeting guide), with `**Mode:** Hive (autonomous consensus)` in the header and this decisions table schema:

    | # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
    |---|----------|------|----------|------------|------------------|---------|
    | 1 | Example  | Two-way | REVISE | CONSENSUS | Wei: scalability concern | Dana: disagreed, committed |

    - **Door**: `one-way` or `two-way`
    - **Resolution**: `CONSENSUS`, `BIAS-FOR-ACTION`, or `ESCALATED`
    - Escalated decisions get a `User Action Required` section at the top of the summary listing each escalated item, the competing arguments, and a prompt for the user to choose REVISE / KEEP / DEFER

12. **Offer to apply revisions.** If the revision queue is non-empty, tell the user to run `/prfaq:feedback` (no arguments) to automatically discover this meeting summary and apply all directives.
