# Meeting Guide

How `/prfaq:meeting` works — loaded by the main skill to orchestrate the meeting flow.

## What This Meeting Is

A simulated Amazon-style PR/FAQ review meeting. Four named personas with competing priorities debate the weak spots in the user's document. The user is the PM and final decision-maker. The output is a decisions log — not more feedback, but explicit tradeoff decisions that feed into `/prfaq:feedback` for automated revision.

The value is not "better feedback" (the peer-reviewer already gives good feedback). The value is **forcing explicit tradeoff decisions** that the author would otherwise leave implicit.

## The Cast

| Persona | Agent | Lens | Primary LPs | Verbal Signature |
|---------|-------|------|-------------|-----------------|
| **Wei** (Principal Engineer) | `meeting-engineer` | Feasibility risk | Dive Deep, Highest Standards | "What's the denominator?" |
| **Priya** (Target Customer) | `meeting-customer` | Value risk / customer reality | Customer Obsession, Bias for Action | "Which of those developers am I?" |
| **Alex** (Skeptical Executive) | `meeting-executive` | Value risk / strategic fit | Have Backbone, Earn Trust | "Compared to what?" |
| **Dana** (Builder-Visionary) | `meeting-builder` | Ambition risk / cost of inaction | Think Big, Invent and Simplify | "You're thinking too small." |

The key tension: Wei + Alex pull toward caution. Dana pulls toward ambition. Priya grounds both sides in customer reality. The user resolves the tension.

## Meeting Flow

### Phase 0: Pre-Meeting Scan

Identify **hot spots** — sections where the document is weakest. These are judgment calls with real tradeoffs, not formatting issues.

**Hot spots must be substance, not prose quality.** A hot spot exists because a real business or product judgment is shaky — not because a sentence is unsourced or a word is vague. Ask the four risk-lens questions directly against the document's actual claims:

- **Feasibility (Wei's lens):** Does the architecture or build plan actually hold up at the scale or timeline implied? Is there an operational or maintenance risk the document waves off as solved? Does a claimed technical result (e.g., "no infrastructure to build") hide a real ongoing cost?
- **Value / customer reality (Priya's lens):** Does the target customer segment actually cohere, or is the document serving two audiences with incompatible needs? Would a real person in that segment behave the way the document assumes? Is customer demand asserted where it should be evidenced?
- **Strategic fit / viability (Alex's lens):** Is the business model or monetization stance defensible given the document's own data? Is the claimed competitive moat actually differentiated, or just asserted? Does the document duck an opportunity-cost question — why this, and not something else?
- **Ambition (Dana's lens):** Is the scope too conservative or too narrow given the opportunity the document itself describes? Is the document defending a comfortable middle position instead of picking a side?

Documentation and evidence issues are still valid hot spots, but they are the minority, not the default:
1. `[CITATION NEEDED]` markers
2. Claims without `\cite{}` references
3. Risk ratings marked Low with weak supporting evidence
4. Vague language: "significant", "many", "rapidly growing"
5. FAQ answers that are thin (1-2 sentences) on questions that deserve depth
6. The gap between press release confidence and FAQ hedging

**Guardrail:** at least half of the 5-8 hot spots identified must come from the four risk-lens questions above, not the documentation-quality list. If a scan turns up mostly citation gaps, hedging mismatches, or wording fixes, that is a sign the scan defaulted to copy-editing — stop and re-ask the four risk-lens questions directly against the document's claims about customers, competitors, business model, and scope before finalizing the agenda.

Rank each hot spot:
- **Critical** — undermines the core argument (must address)
- **Warning** — weakens the document but doesn't invalidate it (should address)
- **Suggestion** — could improve (nice to have)

Aim for 5-8 hot spots total. More than 8 makes the meeting too long. Fewer than 3 means the document might not need a meeting.

### Phase 1: Agenda & Scope Selection

Present the agenda and let the user choose scope:

```
MEETING AGENDA

 CRITICAL (must address):
  1. [Hot spot 1 — one-line description]
  2. [Hot spot 2 — one-line description]

 WARNING (should address):
  3. [Hot spot 3]
  4. [Hot spot 4]

 SUGGESTION (nice to have):
  5. [Hot spot 5]
```

Offer scope options via AskUserQuestion:
- **Full meeting** — all items
- **Critical only** — just the critical items
- **Pick specific items** — user chooses
- **Skip meeting** — show a written report instead (run peer-reviewer)

The user always has an exit ramp. Never trap them in a meeting.

### Phase 2: Debate Per Hot Spot

For each agenda item, run this cycle:

**Step 1: Show the claim.** Quote the specific text from the document that's under discussion. Give the user context before the debate starts.

**Step 2: Launch persona agents in parallel.** Use the Task tool to invoke all four persona agents as background tasks. Each receives:
- The hot spot description
- The relevant document section (quoted)
- The meeting state so far (previous decisions, if any)
- Their agent-specific prompt (structural constraints + voice + reference guides)

**Step 3: Synthesize the debate.** When all agents return, DO NOT just concatenate their responses. Instead:

1. Read all four positions
2. Identify who agrees and who disagrees — and on what specific point
3. Find the most interesting disagreement (often Wei vs Dana, or Priya vs Alex)
4. Write a dramatic narrative that shows the personas engaging with each other's points:
   - Lead with the strongest critique
   - Show the counter-argument
   - Escalate to the irreconcilable disagreement
   - Make it clear what the user needs to decide

The narrative should feel like eavesdropping on a real meeting — not reading four separate reports.

**Synthesis voice guidelines:**
- Use persona names and verbal tics in dialogue
- Let personas respond to each other: "Wei pushes back on Dana's simplification..."
- Find the moment where two reasonable positions can't both be true
- The disagreement should be substantive — about the product, not about each other
- Humor is welcome when it's grounded in truth (a pointed observation, not a joke)

**Step 4: Present the decision.** Use AskUserQuestion with these options:
- **Revise** — flag this section for revision (queued for `/prfaq:feedback`)
- **Keep as-is** — current text stands, move on
- **Research** — invoke researcher agent to find evidence for this claim
- **Defer** — needs more thinking, address later

**Step 5: Show cascade consequences.** After the decision, identify what other sections are affected using the dependency graph from the feedback agent's Section Dependency Graph. Show: "This decision affects N other sections: [list]. These will be included in the revision queue."

### Phase 3: Post-Meeting Summary

After all agenda items are resolved (or the user exits early), present the summary:

```
MEETING SUMMARY

Decisions made: N
  1. [Hot spot] — [REVISE/KEEP/DEFER] (rationale)
  2. ...

Revision queue (for /prfaq:feedback):
  - "[Specific feedback directive for item 1]"
  - "[Specific feedback directive for item 2]"
  ...

Deferred items:
  - [Item] — [what needs to happen before deciding]

To apply all revisions automatically, run: /prfaq:feedback
```

The revision queue items must be specific enough to work as `/prfaq:feedback` input. Not "fix the TAM" but "Reframe TAM FAQ around viral distribution model instead of traditional market sizing. The denominator should be active Claude Code users, not all developers."

### Phase 3b: Persist the Summary

After presenting the summary to the user, write it to a markdown file in the `./meetings/` subdirectory (relative to the project root).

**Filename:** `./meetings/meeting-summary-YYYY-MM-DD.md` using today's date. If a file with that name already exists, append a counter: `meeting-summary-YYYY-MM-DD-2.md`, `meeting-summary-YYYY-MM-DD-3.md`, etc.

**Contents:** The file should contain the full meeting output as structured markdown:

```markdown
# PR/FAQ Review Meeting Summary
**Date:** YYYY-MM-DD
**Document:** [filename]
**Scope:** [Full meeting / Critical only / Selected items]

## Decisions

| # | Hot Spot | Severity | Decision | Rationale |
|---|----------|----------|----------|-----------|
| 1 | [description] | CRITICAL | REVISE | [rationale] |
| 2 | ... | ... | ... | ... |

## Revision Queue (for /prfaq:feedback)

### Directive 1: [Short title]
[Full feedback directive text]

### Directive 2: [Short title]
[Full feedback directive text]

## Deferred Items
- [Item] — [what needs to happen before deciding]

## Research Completed
[If any researcher agents were invoked during the meeting, summarize findings here]

## Notes
[Any observations about the meeting process itself]
```

Tell the user where the file was saved. This file is the durable record of the meeting — it survives session closure and can be referenced by future `/prfaq:feedback` runs.

## Synthesis Guidelines

### Making Personas Disagree With Each Other

The most valuable debates happen when personas challenge each other, not just the document. Look for these natural tensions:

- **Wei vs Dana**: Wei says "this is technically harder than you think" / Dana says "you're overcomplicating it — ship the simple version"
- **Priya vs Alex**: Priya says "real customers need this" / Alex says "wanting it and paying for it are different"
- **Wei vs Priya**: Wei says "the architecture won't scale" / Priya says "I don't care about scale, I care about it working today"
- **Dana vs Alex**: Dana says "the market is bigger than you think" / Alex says "I've heard that before"

### Writing Dramatic Moments

The debate should have genuine moments of insight. Look for:

1. **The gotcha** — one persona's point directly undermines another's position
2. **The reframe** — one persona reframes the question in a way that changes everything
3. **The concession** — a persona admits the other has a point (rare and powerful)
4. **The escalation** — a concern gets worse when you look deeper

### Ground Every Line in Specifics

Every sentence of the debate narrative — and any later spoken reconstruction of it — must reference an actual specific from the document: a quoted phrase, a real number, a named competitor, a named customer segment. An abstract metaphor standing in for the reasoning ("same disease, different organ") tells the reader nothing on its own; the concrete version ("the Viability row omits the five-month gap the cost-structure FAQ already admits to") tells them everything. If a line would still make sense with the specific nouns swapped out for a different hot spot, it is too abstract — rewrite it.

**Test:** could someone who has read only this hot spot's narrative, with no other context, explain in their own words what specific thing is wrong and what the fix is? If not, it is not grounded enough yet.

### Never Reference the Meeting's Own Structure

Do not have a persona comment on the meeting's own sequence or shape — "third hot spot in a row," "unlike the previous item," "this is the Nth time tonight," "this isn't a duplicate of hot spot 3." Each hot spot's narrative must stand alone; a reader or listener should never need to remember an earlier hot spot to follow this one. Cross-hot-spot patterns (the same failure mode recurring across multiple hot spots, say) are real findings worth recording — put them in the summary's **Notes** section, in prose, written for a reader. Never have a persona say it aloud mid-debate as if commenting on the meeting itself.

### What NOT to Do

- Don't have personas agree too easily ("I agree with Wei that...")
- Don't have personas disagree on trivia
- Don't use their names as labels — weave them into the narrative
- Don't summarize what each persona said — dramatize the conflict
- Don't invent disagreements that don't exist — if they genuinely agree, say so briefly and move on
- Don't make Dana a cheerleader — she has standards too
- Don't let a persona narrate the meeting's own structure instead of the document's content (see above)
- Don't reach for an abstract turn of phrase in place of the actual concrete reasoning (see above)

## Early Exit

If the user wants to leave the meeting early (AskUserQuestion option or explicit request), immediately produce the post-meeting summary with whatever decisions have been made. Mark unaddressed items as "Not discussed" — not "Deferred" (which implies a decision to defer).

## Stage Calibration

Extract `\prfaqstage{value}` from the document before the pre-meeting scan. Stage calibrates both the hot spot ranking and persona behavior:

### Hot Spot Ranking by Stage

| Signal | Hypothesis | Validated | Growth |
|--------|-----------|-----------|--------|
| Missing customer evidence | Warning (expected) | Critical (should have it) | Critical (must have it) |
| `[CITATION NEEDED]` markers | Suggestion (acknowledged gaps) | Warning (should be shrinking) | Critical (unacceptable on business claims) |
| Thin FAQ answers | Warning (depth comes later) | Warning (should be deepening) | Critical (all FAQs should be substantive) |
| Risk ratings all Low | Warning at any stage | Warning (evidence should differentiate) | Critical (must reflect real data) |
| No pre-mortem scenario | Critical at any stage | Critical | Critical |

### Persona Calibration by Stage

| Persona | Hypothesis | Validated | Growth |
|---------|-----------|-----------|--------|
| **Wei** | "What's the hardest unknown?" Focus on identifying risks, not solving them. Accept directional architecture. | "Have you tested the hard part?" Expect spike results or reference class data. | "Show me the production data." Expect operational metrics and real performance. |
| **Priya** | "Does this problem ring true?" Evaluate problem plausibility from customer's perspective. | "Did real users say this?" Expect interview-backed insights in the FAQs. The press release customer quote is aspirational by design — do not flag it. | "What do your users actually do?" Expect usage data and behavioral evidence in the FAQs. The press release customer quote is aspirational — evaluate it for plausibility, not sourcing. |
| **Alex** | "What's the riskiest assumption?" Focus on identifying the bet, not proving the payoff. | "What did validation tell you?" Expect the document to have learned from testing. | "Show me the unit economics." Expect real financial data. |
| **Dana** | "Is this bold enough?" Push for ambition even at hypothesis stage — thinking too small wastes the experiment. | "Did validation narrow or expand the opportunity?" Check if learnings were incorporated. | "What's the next frontier?" Push for growth beyond current success. |

**Key principle:** Stage calibration makes personas more useful, not softer. At hypothesis stage, Priya asking "can I use this?" about an unbuilt product is unhelpful — but "does this problem ring true?" surfaces genuine insight. At growth stage, Alex accepting inferred demand is negligent — but at hypothesis stage, it's appropriate.

## Hive Mode

`/prfaq:meeting-hive` is the autonomous variant — the "team meeting without the boss." Same cast, same hot spot ranking, same stage calibration. The difference is the decision mechanism: personas reach consensus through multi-round debate instead of the user deciding at each point.

### Decision Philosophy: Arguments Win, Not Averages

Amazon's "Have Backbone; Disagree and Commit" means the hive does not compromise or blend positions. When two personas disagree, one wins. The loser disagrees and commits. The synthesis names the winner explicitly.

### One-Way vs Two-Way Doors

Every hot spot implies a decision. Classify it before debate:

- **One-way door** (irreversible): Architecture choices, public API contracts, data model commitments, third-party lock-in, public positioning that constrains future options. Wei's IRREVERSIBLE DECISIONS section is the primary signal.
- **Two-way door** (reversible): Feature scope, positioning language, risk rating levels, FAQ framing, internal priorities that can shift later.

The door type changes how votes are weighted — not equally, but by relevance:
- One-way doors: Wei and Alex's caution carries extra weight. A single REJECT from either forces a rebuttal round.
- Two-way doors: Dana and Priya's action bias carries extra weight. Persistent splits resolve in favor of action.

### How Consensus Works

**Round 1 (Independent):** All four personas evaluate the hot spot independently, producing their standard structured positions (APPROVE/ITERATE/REJECT with rationale).

**Door-weighted resolution:**

*Two-way doors:*
- 3-1 or 4-0 → majority wins in one round
- 2-2 → bias for action (two-way doors are reversible — ship and learn). Round 2 only if the caution side raises a specific falsifiable concern.

*One-way doors:*
- 4-0 APPROVE → KEEP
- Any REJECT from Wei or Alex → Round 2 required, regardless of other votes
- 3-1 with Wei or Alex dissenting → Round 2 (their caution matters on irreversible decisions)
- 3-1 with Dana or Priya dissenting → majority wins

**Round 2 (Rebuttal, when required):** Each persona sees all Round 1 positions and responds to the strongest counterargument. They may change their verdict if genuinely persuaded, but they must not compromise — either their concern stands or it doesn't.

**Post-Round 2 resolution:**
- Clear majority → that side wins. Minority disagrees and commits.
- Persistent split on a one-way door → **escalate to user** with both sides' strongest argument.
- Persistent split on a two-way door → **bias for action**. Action side wins. Dissent noted.

### Decision Mapping

| Door Type | Consensus Position | Meeting Decision |
|-----------|-------------------|-----------------|
| Either | 3-1 or 4-0 APPROVE | KEEP |
| Either | 3-1 or 4-0 ITERATE/REJECT | REVISE |
| Two-way | 2-2 split (Round 1) | BIAS-FOR-ACTION — action side wins unless caution raises a falsifiable concern → Round 2 |
| Two-way | 2-2 split (after Round 2) | BIAS-FOR-ACTION — action side wins, dissent noted |
| One-way | 2-2 split (after Round 2) | ESCALATED — user decides, both sides' strongest argument presented |

### Synthesis in Hive Mode

The debate narrative is shorter than in regular meetings (3-5 sentences per hot spot, not a full dramatic scene). The goal is to communicate the key tension and the resolution, not to dramatize the conflict. Save the user's reading time — they'll read N summaries, not participate in N debates. The same grounding rules apply at this shorter length: every sentence still needs to name a specific from the document, and no sentence references another hot spot's position in the sequence.

For split decisions, present both sides' strongest single argument and ask the user to decide.

### Hive Summary Format

Same structure as the regular meeting summary (Phase 3b), with `**Mode:** Hive (autonomous consensus, Agent Teams)` in the header and this decisions table schema:

| # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
|---|----------|------|----------|------------|------------------|---------|

- **Door**: `one-way` or `two-way`
- **Resolution**: `CONSENSUS`, `BIAS-FOR-ACTION`, or `ESCALATED`
- Escalated decisions get a `User Action Required` section at the top of the summary
