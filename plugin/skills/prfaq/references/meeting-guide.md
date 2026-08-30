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

### Phase 0b: Opening Assessment

Real review meetings open with someone framing the stakes before diving into an itemized list — not a cold jump into agenda item one. Give this meeting the same opening.

Launch a single `prfaq:meeting-executive` (Alex) agent — not all four personas, just Alex, since this is the person calling the meeting to order. Tell Alex explicitly: **this is a meeting-opening assessment, not a section evaluation — reply in 3-5 sentences of continuous prose, not the structured BIGGEST ASSUMPTION/OPPORTUNITY COST/POSITION/EVIDENCE format** (see the Exception in `meeting-executive.md`). Give Alex: the document's stage, the full Risk Assessment table, and the list of hot spots about to be debated (titles and severities, not the full debate). Ask for a holistic opening read, 3-5 sentences, organized around the three questions product development lives or dies on:

1. **Is this a problem worth solving?** — does the document's own evidence support that the problem is real and significant, walking in?
2. **Do we have a strong, differentiated solution?** — does the competitive-landscape evidence suggest this actually beats the alternatives, or does it just exist alongside them?
3. **Should we build this now?** — given the stage and the hot spots about to be debated, is the timing and opportunity cost defensible, or is this competing against something more urgent?

Alex doesn't need a final answer to all three before the debate — a live worry ("problem looks real, but I'm not sold on #2 yet") is a legitimate opening read. Ground it in real specifics — the actual risk ratings, the actual TAM figures, the actual stage — the same grounding rule as the rest of the meeting applies here too.

Present this opening assessment to the user before the agenda list. It sets context; it does not replace the agenda.

**If the agent call fails, times out, or returns content that isn't grounded in the specific risk ratings or hot spots provided:** tell the user the opening assessment could not be generated and proceed straight to the agenda. Never substitute a generic read ("the document looks broadly promising") to fill the gap — an ungrounded assessment is worse than no assessment.

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

### Phase 2b: Closing Assessment

Real review meetings don't just stop after the last agenda item — someone closes the meeting out. Give this meeting the same close, after every hot spot has a **final** decision (including any escalated items a hive meeting resolved — see Hive Mode below) and before the mechanical decisions summary.

A **Defer** decision is not final in either mode — it means "needs more thinking," not "decided." Exclude deferred items from Alex's decision list and tell Alex how many were deferred, so the closing read can acknowledge them honestly instead of assuming every hot spot is settled. This applies the same way in `/prfaq:meeting` (where the user can choose Defer per item) and `/prfaq:meeting-hive` (where an escalated item can resolve to Defer — see Hive Mode below).

**On early exit** (see Early Exit below): still run the closing assessment, but tell Alex explicitly the meeting was cut short and pass only the decisions actually made — never pass "Not discussed" items to Alex as if they were decided.

Launch a single `prfaq:meeting-executive` (Alex) agent again — standalone, not the full cast. Tell Alex explicitly: **this is a meeting-closing assessment, not a section evaluation — reply in 3-5 sentences of continuous prose, not the structured format** (see the Exception in `meeting-executive.md`). Give Alex: the opening assessment (for continuity), and the full list of final decisions made across every hot spot (title, decision, one-line rationale each) — or, on early exit, the decisions made before exiting plus a note that the meeting ended early. Ask for a closing read, 3-5 sentences, that revisits the opening's three questions in light of what the meeting decided:

1. **Is this a problem worth solving?** — did any hot spot change the read on the problem's reality or significance?
2. **Do we have a strong, differentiated solution?** — did the decisions strengthen or weaken the competitive case?
3. **Should we build this now?** — once these revisions land, is the timing call still the same as the opening, or did the meeting surface a reason to reconsider?

Alex doesn't need all three to have moved — naming which ones didn't change is as useful as naming which did. This is a narrative judgment call in Alex's voice, not a repeat of `/prfaq:vote`'s structured three-gate go/no-go — point the user at `/prfaq:vote` separately if they want that level of rigor.

End the closing assessment with a concrete proposal for what happens next and when to reconvene — grounded in the actual revision queue ("let's revisit once the TAM and Viability revisions land"), never a generic "let's touch base soon."

**If the agent call fails, times out, or returns content that isn't grounded in the specific decisions provided:** tell the user the closing assessment could not be generated and proceed straight to the mechanical summary. Never substitute a generic read to fill the gap.

### Phase 3: Post-Meeting Summary

After all agenda items are resolved (or the user exits early), present the summary:

```
MEETING SUMMARY

Decisions made: N
  1. [Hot spot] — [REVISE/KEEP/RESEARCH/DEFER] (rationale)
  2. ...

Revision queue (for /prfaq:feedback):
  - "[Specific feedback directive for item 1]"
  - "[Specific feedback directive for item 2]"
  ...

Deferred items:
  - [Item] — [both sides' strongest argument, if this was an escalated hive decision] — [what needs to happen before deciding]

Not discussed (early exit only):
  - [Item] — identified as a hot spot, never reached before the meeting ended

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

## Overall Assessment

**Opening (Alex):** [The 3-5 sentence opening read from Phase 0b]

**Closing (Alex):** [The 3-5 sentence closing read from Phase 2b, ending with the concrete next-step/reconvene proposal]

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
- [Item] — [both sides' strongest argument, if this was an escalated hive decision] — [what needs to happen before deciding]

## Not Discussed
[Only present on early exit — see Early Exit below]
- [Item] — identified as a hot spot, never reached before the meeting ended

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

The closing assessment (Phase 2b) still runs on early exit — a real meeting that ends early still gets a closing remark. Pass Alex only the decisions actually made; list "Not discussed" items separately and tell Alex the meeting was cut short, so the closing read can note that explicitly rather than assume full coverage.

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

`/prfaq:meeting-hive` is the autonomous variant — the "team meeting without the boss." Same cast, same hot spot ranking, same stage calibration, same opening and closing assessment. The difference is the decision mechanism: personas reach consensus through multi-round debate instead of the user deciding at each point.

The opening assessment (Phase 0b) applies unchanged in hive mode: a single standalone Alex spawn before the agenda, not part of the `prfaq-hive` team.

The closing assessment (Phase 2b) needs one hive-specific ordering rule: the debate loop's own decision mapping leaves `ESCALATED` items unresolved by design (see Decision Mapping below) — those are user calls, not hive consensus. Resolve every escalated item with the user (`AskUserQuestion`: REVISE / KEEP / DEFER) *before* launching the closing assessment. A REVISE or KEEP resolution becomes that hot spot's final decision and is included in what Alex sees; a DEFER resolution stays unresolved and is excluded from Alex's decision list — tell Alex how many items were deferred instead, so the closing read can acknowledge them honestly rather than assume every hot spot is settled. Like the opening spawn, the closing spawn is a single standalone Alex agent, not part of the team.

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
- Persistent split on a one-way door → mark `ESCALATED` and record both sides' strongest argument. Do not ask the user yet — the hive keeps running; escalations resolve in one batch once the full debate loop finishes (see Hive Mode above).
- Persistent split on a two-way door → **bias for action**. Action side wins. Dissent noted.

### Decision Mapping

| Door Type | Consensus Position | Meeting Decision |
|-----------|-------------------|-----------------|
| Either | 3-1 or 4-0 APPROVE | KEEP |
| Either | 3-1 or 4-0 ITERATE/REJECT | REVISE |
| Two-way | 2-2 split (Round 1) | BIAS-FOR-ACTION — action side wins unless caution raises a falsifiable concern → Round 2 |
| Two-way | 2-2 split (after Round 2) | BIAS-FOR-ACTION — action side wins, dissent noted |
| One-way | 2-2 split (after Round 2) | ESCALATED — recorded, not asked yet; resolved after the debate loop via REVISE / KEEP / DEFER (both sides' strongest argument presented then) |

### Synthesis in Hive Mode

The debate narrative is shorter than in regular meetings (3-5 sentences per hot spot, not a full dramatic scene). The goal is to communicate the key tension and the resolution, not to dramatize the conflict. Save the user's reading time — they'll read N summaries, not participate in N debates. The same grounding rules apply at this shorter length: every sentence still needs to name a specific from the document, and no sentence references another hot spot's position in the sequence. For a hot spot marked `ESCALATED` at synthesis time, there is no winner yet — write both sides' strongest argument and note the call is the user's; do not fabricate a winner.

After the debate loop finishes (not during it — see Hive Mode above), present each escalated item's both sides' strongest single argument and ask the user to decide: REVISE / KEEP / DEFER.

### Hive Summary Format

Same structure as the regular meeting summary (Phase 3b) — including the `## Overall Assessment` and `## Deferred Items` sections — with `**Mode:** Hive (autonomous consensus, Agent Teams)` in the header and this decisions table schema:

| # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
|---|----------|------|----------|------------|------------------|---------|

- **Door**: `one-way` or `two-way`
- **Decision**: `REVISE`, `KEEP`, or `DEFER` — a `DEFER` row was never given to the closing assessment (see the ordering rule in Hive Mode above)
- **Resolution**: `CONSENSUS`, `BIAS-FOR-ACTION`, or `ESCALATED` (an escalated row resolved REVISE or KEEP is recorded in `Escalated Decisions (Resolved)`; an escalated row resolved DEFER is recorded in `## Deferred Items` instead — see Phase 3b)
- An `ESCALATED` row resolved **REVISE or KEEP**: **Winning Argument** is `User decision (escalated) — see Escalated Decisions (Resolved)`, **Dissent** is `—`. This is the user's tie-break, not a hive consensus — never reuse the DEFER row's placeholder here, since this row *is* decided and `/prfaq:meeting-listen` reads the Winning Argument text to tell the two cases apart.
- An `ESCALATED` row resolved **DEFER**: **Winning Argument** and **Dissent** are both `— (escalated, no winner)` — this hot spot produced no winner and remains unresolved (see Synthesis in Hive Mode above), so neither column has anything to name
- Items that were escalated and resolved REVISE/KEEP get an `Escalated Decisions (Resolved)` section near the top of the summary, recording each item's competing arguments and the user's resolution — a historical record, not a live prompt, since the resolution already happened before the closing assessment ran
- Items that were escalated and resolved DEFER go in `## Deferred Items` (same field format as the Phase 3b template), not in `Escalated Decisions (Resolved)`
