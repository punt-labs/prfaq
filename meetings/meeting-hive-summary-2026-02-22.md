# PR/FAQ Review Meeting Summary
**Date:** 2026-02-22
**Document:** prfaq.tex
**Stage:** hypothesis | v3.0
**Mode:** Hive (autonomous consensus, Agent Teams)
**Scope:** Full meeting (all 7 hot spots)

## Decisions

| # | Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent |
|---|----------|------|----------|------------|------------------|---------|
| 1 | TAM built on unvalidated inference chain | Two-way | REVISE | CONSENSUS (3-1) | Priya: the 2-5M range is the algebraic consequence of a chosen ARPU range, not a validated estimate — unknowable inputs presented as merely imprecise is a different kind of dishonesty | Wei: wanted numbers dropped entirely in favor of trajectory argument; disagreed, committed |
| 2 | Positioning gap not elevated as kill-shot risk | Two-way | REVISE | CONSENSUS (4-0) | Wei: scenario 7 is a falsifier of the hypothesis, not an execution risk — the document's structure neutralizes this insight by listing it seventh of seven | None |
| 3 | Zero primary customer data with no pivot plan | Two-way | REVISE | CONSENSUS (4-0) | Wei: the document has a tripwire but no wire on the other side — "reconsider the product strategy" is a deferral, not a pivot plan | None |
| 4 | Feasibility vs strategic risk conflation | Two-way | REVISE | CONSENSUS (4-0) | Wei: the text says "strategic risk is platform dependency" and then files it under Feasibility — the author named it correctly and categorized it wrong | None |
| 5 | Usability rated Low without user testing | Two-way | REVISE | CONSENSUS (4-0) | Wei: "installer mitigates" the TeX dependency the way a seatbelt mitigates a crash — it's still a crash | None |
| 6 | Single customer quote as representative | Two-way | KEEP | CONSENSUS (4-0) | Priya: acknowledging sample size in a press release quote is a hypothesis-stage category error — the format asks for one vivid quote, not statistical evidence | None |
| 7 | Revenue model contradiction (Q12 vs Q13) | Two-way | REVISE | BIAS-FOR-ACTION (2-2) | Wei: "None" in Q12 is an absolute claim that Q13 immediately walks back — avoidable reader whiplash | Alex & Dana: the two-question structure is intentional and clear; disagree, committed |

## Revision Queue (for /prfaq:feedback)

### Directive 1: Reframe TAM as explicit assumptions, not derived estimates
Revise the TAM FAQ to acknowledge that the $2.5B figure is Anthropic total ARR (not Claude Code ARR), that the ARPU assumptions ($40-100/month blended) are themselves unvalidated estimates, and that the resulting 2-5M user range is a rough order-of-magnitude placeholder, not a derived estimate. Make each step's unknowability explicit. Preserve the "reach argument, not revenue argument" framing — it is the document's strongest logical move.

### Directive 2: Structurally elevate the positioning gap as a kill-shot risk
Separate pre-mortem scenario 7 from the flat list. Either move it to scenario 1 or add a structural break that signals this scenario is categorically different from scenarios 1-6: it cannot be resolved by iterating on the product — it can only be resolved by repositioning or narrowing to a single segment. Connect it explicitly to the Amazon alumni hypothesis as the test of whether a "right-rigor" segment exists between vibe coders and skeptical PMs. Add the kill-shot sentence: "Unlike the other scenarios, this failure mode cannot be fixed by trying harder."

### Directive 3: Add a pivot decision tree to the validation plan
In the validation FAQ, after Signal 7, add a pre-committed response branch for each outcome: (1) if casual builders reject but alumni/PMs engage, narrow to the expert segment; (2) if PMs distrust but casual builders engage, the problem is trust calibration — pivot to explainability and framework fidelity; (3) if both segments reject simultaneously, treat dual rejection as a kill signal and discontinue or pivot to a fundamentally different delivery mechanism. The choice depends on which signal fires first and how strongly.

### Directive 4: Reclassify feasibility and viability risks
Change Feasibility from Medium to Low — the full feature set is shipped, remaining work is straightforward, risks are limited to prompt tuning. Move the platform dependency concern (Anthropic controls plugin system, distribution, competitive response) into the Viability row where it reinforces the existing Medium rating. Reconcile the Viability row's "no servers, no API keys" framing with the platform dependency reality: the LaTeX output is survivable; the plugin distribution channel is not.

### Directive 5: Upgrade usability to Medium pending validation
Change Usability from Low to Medium. Replace "installer mitigates" with an honest characterization: the installer detects TeX absence and provides instructions but does not auto-install the ~4GB dependency. Add: "Rating will be revised to Low when the validation trial confirms median time-to-first-PDF under one hour across environment types." Non-technical users (a claimed growth segment) have not been tested on the full onboarding path.

### Directive 6: Bridge the revenue model contradiction
Revise Q12's opening from "None" to "None today, by design" and add a forward pointer to Q13 for the conditional commercial path. Q13 requires no changes — its "path, not a plan" framing is honest and precise. The goal is to eliminate the whiplash between "no monetization" and a detailed premium tier description.

## Deferred Items
None — all hot spots were resolved in Round 1.

## Research Completed
No researcher agents were invoked during this meeting.

## Notes
- All 7 hot spots were two-way doors — no irreversible decisions were under debate
- 5 of 7 hot spots reached unanimous consensus (4-0); 1 reached supermajority (3-1); 1 required bias-for-action resolution (2-2)
- The document's self-awareness is consistently strong — it identifies its own weaknesses accurately. The recurring pattern across hot spots 1-5 is the same: correct diagnosis, incomplete follow-through. The document names its risks honestly but does not follow them to their logical conclusions.
- Hot Spot 6 (customer quote) was the only KEEP — the hive correctly identified the concern as a category error at hypothesis stage
- This was the first test of the Agent Teams migration (PR #18). The four-persona parallel spawn and message-based coordination worked as designed.
