# PR/FAQ Review Meeting Summary
**Date:** 2026-08-29
**Document:** prfaq.tex
**Mode:** Hive (autonomous consensus, Agent Teams)
**Scope:** Full meeting (6 hot spots)

## Decisions

| # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
|---|----------|------|----------|------------|-------------------|---------|
| 1 | TAM paragraph stacks incommensurable metrics (Lovable/Replit user counts, Bolt ARR, Codex WAU) as if directly comparable | Two-way | REVISE | CONSENSUS | Unanimous: stacking implies false comparability; split into distinct, honestly-labeled signals without dropping any citation | None |
| 2 | Press-release customer quote (invented persona) carries no signal distinguishing it from the real, anonymized PM evidence two pages later | Two-way | REVISE | CONSENSUS | Unanimous: a reader unfamiliar with Working Backwards convention can't tell invented from real; add one contrast line opening the customer-evidence FAQ, leave the press-release quote itself untouched | None |
| 3 | Value risk mitigation rests entirely on two not-yet-executed dated actions, structurally identical to the mitigation that already failed and caused this risk's re-rating | Two-way | REVISE | CONSENSUS | Unanimous, Wei/Alex sharpest: a future-dated plan with no interim checkpoint reproduces the exact silent-slippage failure mode that got Value risk re-rated High; add an early tripwire before 2026-09-30, name an owner, make escalation trigger on silence not just a negative result | None |
| 4 | Viability risk row omits the real ~5-month release gap (2026-03-20 to 2026-08-13), describing only a hypothetical future maintenance cadence | Two-way | REVISE | CONSENSUS | Unanimous: the row whose job is to assess maintainer sustainability is the one place the most relevant data point is missing; acknowledge the gap in the row itself, state confidence about recurrence or flag it as unresolved | None |
| 5 | Competitive-landscape differentiation claim ("no one else combines the framework + multi-agent debate") rests on a single, unverified research pass | Two-way | REVISE | CONSENSUS | Unanimous: negative claims need more coverage than positive ones; hedge the wording to match the evidence ("no plugin surfaced in this search...") rather than requiring new hands-on evaluation | None |
| 6 | "Next step" FAQ's dated actions have no named owner and (for action 2) no built-in negative-result clause | Two-way | REVISE | CONSENSUS | Unanimous, explicit non-duplicate ruling: hot spot 3's fix patches the Value risk row's *citation*; this fixes the *source* FAQ the plan is actually executed from — name an owner, extend action 1's existing "silence is itself the finding" framing to action 2, and have the risk row reference the FAQ rather than re-deriving its own copy | None |

## Revision Queue (for /prfaq:feedback)

### Directive 1: Fix the TAM trajectory-upside metric stacking
Split the "A wave of non-programmers is building software..." sentence (TAM FAQ) into signals labeled by what they actually measure — e.g., a scale sentence (Lovable/Replit user counts) and a separate commercial-pull/behavior sentence (Bolt ARR, Codex WAU, YC cohort composition) — rather than one additive list implying equivalent units. Keep every existing citation; this is a framing fix, not a sourcing change.

### Directive 2: Distinguish illustrative from real customer evidence
Add one contrast sentence at the top of the customer-evidence FAQ (fifth paragraph, the first-hand adoption signal) establishing that this evidence is real and first-hand, in contrast to the illustrative press-release quote. Do not add any qualifier to the press-release quote itself or its attribution — leave that section exactly as-is; the fix lives entirely in the FAQ.

### Directive 3: Add an interim tripwire to the Value risk mitigation
In the Value risk row's mitigation clause, add: a named owner for the diagnostic actions, an interim checkpoint before 2026-09-30 (e.g., "if no diagnostic conversation has started by 2026-09-08, escalate immediately"), and make the escalation clause trigger on silence/non-execution, not only on a completed-but-inconclusive result.

### Directive 4: Acknowledge the release gap in the Viability risk row
Add one sentence to the Viability risk row naming the actual ~5-month gap (2026-03-20 to 2026-08-13) before stating the forward-looking 4-8 hrs/week estimate at 500+ stars. State the document's actual confidence about recurrence, or flag it plainly as unresolved if unknown.

### Directive 5: Hedge the competitive differentiation claim
In the competitors FAQ's "Market update, Q3 2026" paragraph, soften "It does not implement... nor a multi-agent debate feature comparable to..." to name the claim's actual evidentiary basis — e.g., "no plugin surfaced in this single research pass implements..." — without weakening the underlying differentiation argument.

### Directive 6: Name an owner and extend the negative-result clause in the "next step" FAQ
In the "next step to validate your vision" FAQ, name the owner for both dated actions (author, for a solo-maintainer project). Extend action (1)'s existing "if this doesn't happen, that itself is the finding" framing to action (2) as well. Update the Value risk row's mitigation clause (Directive 3) to reference this FAQ's checkpoint/owner rather than re-deriving its own separate copy, so the two don't drift out of sync.

## Deferred Items
None — all six hot spots reached full consensus with no persistent splits.

## Research Completed
None — no researcher agent was invoked during this meeting. Hot spot 5's own finding (that the competitive claim needs more research or a hedge) is itself queued as Directive 5, not resolved via a research pass during the meeting.

## Notes

**A structural pattern, not six isolated findings.** Every hot spot converged on the same root cause, independently observed and named by multiple personas across the session: a confident or forward-looking statement (a plan, a projection, a differentiation claim) presented without being reconciled against a contradicting or weaker fact sitting elsewhere in the same document. Alex named this explicitly after hot spot 4 (hot spots 2-4 sharing the shape) and again after hot spot 6 (identifying it as the fourth instance, alongside the original failed "ship publicly, recruit 10 users" commitment this document already diagnosed in its own "What have we learned since launch?" FAQ). This is worth treating as a standing authoring check for future revisions of this document, not just six one-off fixes: **when adding a plan, a projection, or a confident claim, check whether a contradicting or weaker fact already exists elsewhere in the document, and reconcile them in the same edit.**

No hot spot reached a one-way door or required a Round 2 rebuttal — all six resolved on unanimous or majority Round 1 positions. This is consistent with the document having already been through two rounds of peer review and substantial revision earlier this session; the remaining issues were evidence-framing and internal-consistency gaps, not open architectural or scope questions.

Directives 3 and 6 are related but distinct — apply them together in the same `/prfaq:feedback` pass so the risk-row summary and the source FAQ stay consistent with each other.
