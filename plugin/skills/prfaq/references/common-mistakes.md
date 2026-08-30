# Common Mistakes

These anti-patterns consistently undermine PR/FAQ quality. Check every draft against this list.

## Skills-Forward Thinking

**The mistake:** Starting from what the team can build rather than what the customer needs. "We have a great ML pipeline, so let's find a product for it" is skills-forward. Working Backwards means starting from the customer's problem and reasoning back to the technology.

**How it shows up in a PR/FAQ:**
- The solution section describes architecture before customer experience
- The problem section feels reverse-engineered from the solution
- The product name references technology ("AI-Powered X", "Blockchain-Based Y")

**The fix:** Rewrite the problem section without referencing the solution. If the problem doesn't stand on its own, the product is skills-forward.

## Confusing Speed with Velocity

**The mistake:** Rushing the PR/FAQ to "get to building." The entire point of Working Backwards is to slow down the decision, not the execution. A PR/FAQ that took two hours to write will produce a product that takes two years to fix.

**How it shows up in a PR/FAQ:**
- FAQs have one-sentence answers
- Risk assessments say "low" without evidence
- No customer evidence section, or evidence is invented

**The fix:** If the FAQ section is shorter than the press release, the PR/FAQ is not done.

## Selling Instead of Truth-Seeking

**The mistake:** Writing the PR/FAQ to persuade rather than to evaluate. The document is a decision-making tool, not a pitch deck. Its purpose is to surface reasons NOT to build as much as reasons to build.

**How it shows up in a PR/FAQ:**
- No risks are rated "high"
- Competitive analysis dismisses every competitor
- Customer quote is generic or implausible — could come from anyone in any industry
- Internal FAQs have only optimistic answers

**The fix:** Add a "devil's advocate" pass. For every section, ask: "What would a skeptic say?" If you can't articulate the counter-argument, you don't understand the space well enough.

## Discounting Competition

**The mistake:** Describing competitors as if they're standing still. "Competitor X doesn't offer Y" is true today and possibly false next quarter. Sustainable differentiation comes from structural advantages, not feature gaps.

**How it shows up in a PR/FAQ:**
- "No competitors in this space" (there are always competitors, even if indirect)
- Competitive analysis based on current features, not trajectory
- No mention of how competitors would respond to this product

**The fix:** For each competitor, answer: "If they saw our press release tomorrow, what would they do in 90 days?" If the answer is "copy it easily," the differentiation is insufficient.

## Vague Customer Definition

**The mistake:** Defining the customer so broadly that the product tries to serve everyone and delights no one. "Small businesses" is not a customer definition. "Independent restaurant owners with 1-3 locations in metro areas" is.

**How it shows up in a PR/FAQ:**
- The customer quote could come from anyone in any industry
- The problem section describes a universal frustration rather than a specific pain
- The Getting Started section requires different paths for different customer types

**The fix:** Name one real person (or realistic persona) who represents the target customer. Write the entire PR/FAQ for that one person. If the product cannot delight one specific person, it cannot delight a market.

## Great Product, Wrong Problem

**The mistake:** Building an elegant solution to a problem customers don't prioritize. The problem may be real but not important enough to change behavior. Customers tolerate many problems; they only pay to solve the ones that cost them the most.

**How it shows up in a PR/FAQ:**
- The problem section describes a genuine issue but can't quantify its cost
- Customer evidence shows acknowledgment ("yes, that's annoying") but not urgency ("I would pay to fix that today")
- The product competes for budget against problems the customer cares about more

**The fix:** Ask the customer evidence question: "Is this a top-3 problem for the target customer?" If it's problem #7 on their list, they'll never prioritize adopting the solution, no matter how good it is.

## False Precision in Timeline Estimates

**The mistake:** Presenting detailed hour estimates, month-by-month schedules, or phase-specific targets at hypothesis stage. The planning fallacy (Kahneman, 2011) shows that insiders systematically underestimate time and cost when using an inside view. Adding specific numbers without a reference class creates anchoring --- stakeholders remember "300--500 hours" long after the assumptions behind it have changed. AI-augmented development makes this worse: historical velocity data from human-only teams is no longer a reliable baseline.

**How it shows up in a PR/FAQ:**
- Per-phase hour estimates ("Phase 1: 80--120 hours, Phase 2: 80--140 hours")
- Calendar targets tied to phases ("Months 1--2", "Month 6")
- Total development hour ranges presented as reliable ("Total: 300--500 hours")
- P\&L sections that treat unvalidated hour estimates as cost inputs

**The fix:** At hypothesis stage, describe phased delivery order and cut discipline --- what comes first, what comes last, what gets cut if scope compresses --- without dates or hours. The timeline FAQ should answer "what order and what gets cut," not "how long." Reserve detailed estimates for validated stage, when prototype velocity data provides a reference class.

## Explaining the Document to the Reader

**The mistake:** Writing a sentence that explains the document's own conventions, structure, or process to the reader instead of stating product content. A PR/FAQ reader already knows how a PR/FAQ works — a future dateline means an aspirational future state, an FAQ answers a question, a risk table rates risk. Explaining these mechanics is metacommentary about the artifact, not information about the product, and it reads as if the author doesn't trust the reader to know the genre. This includes any sentence that narrates how the document was written, reviewed, or revised (naming an internal review process, a meeting, a review-cycle count, or "this section was added because...") — the document is written as if drafted fresh in one pass, never as a record of its own editing history.

**How it shows up in a PR/FAQ:**
- A sentence explaining why a dateline is in the future ("this date is aspirational, marking the state at which...")
- "This document is written from the perspective of..." or "the reader should note that this FAQ..."
- References to "a prior review," "a review cycle," "eight rounds of feedback," or any other narration of the document's own drafting or revision history
- A parenthetical justifying why a section exists or is formatted a certain way, rather than just writing the section

**The fix:** Delete the sentence and trust the genre convention. If a fact genuinely needs stating (e.g., a specific date matters), state it as a plain fact without explaining the convention around it — "prfaq will ship v2.0 in March 2027" needs no clause explaining that this is aspirational; the press-release format already signals that.

**There is no exception for a case that seems locally confusing.** The most common way this mistake survives a review is an agent (or author) reasoning "the convention is usually self-evident, but *this particular document* is a genuinely ambiguous edge case, so a clarifying note is warranted here." That reasoning is the mistake, not a valid exception to it — every author who adds this kind of sentence believes their case is the ambiguous one. If a document is structured in a way that makes a genre convention read as confusing (for example, a future-dated press release sitting above present-tense retrospective FAQs), the fix is to restructure or caption the *section*, never to insert an explanatory sentence into the copy. Do not write the sentence and then justify it as an exception. If you catch yourself explaining why this instance is different, that is the signal to delete the sentence, not to keep it.

## Stage Calibration

Anti-patterns apply at every stage, but some are more dangerous at specific stages (`\prfaqstage{}`):

| Anti-Pattern | Hypothesis | Validated | Growth |
|--------------|-----------|-----------|--------|
| **Skills-forward thinking** | Most dangerous here. Early-stage documents are most susceptible to "we can build it, so let's find a use." Flag aggressively. | Still important but less common — validation usually forces customer focus. | Rare but appears as "we have this infrastructure, so let's add a feature for it." |
| **Confusing speed with velocity** | Common. Authors rush to code without validating the problem. Thin FAQs and unrated risks are the signal. | Should be decreasing — if FAQs are still thin after validation, the validation wasn't rigorous. | Appears as shipping features without checking if they move key metrics. |
| **Selling instead of truth-seeking** | Acceptable to be enthusiastic at idea stage, but the document must still surface risks honestly. | No longer acceptable. Validation data should drive honest assessment. | Critical failure — growth-stage documents should be the most honest. |
| **Discounting competition** | Some tolerance for incomplete competitive analysis if the space is genuinely new. | Must engage seriously with competitors and their likely response. | Must include observed competitive behavior and market share changes. |
| **Vague customer definition** | Warning. Some vagueness is OK if the document proposes how to narrow it. | Must be specific. Validation should have identified the exact customer. | Must match actual user base, not aspirational target. |
| **Great product, wrong problem** | Hard to detect without customer data. Flag if no validation plan exists. | Should be detectable from interview data. Flag if problem priority isn't established. | Detectable from usage patterns. Flag if engagement is low despite adoption. |
| **False precision in timeline estimates** | Most dangerous here. No reference class exists. Specific hours and dates create anchoring and planning fallacy. Flag any per-phase hour estimates or calendar targets. Describe delivery order and cut discipline only. | Becoming acceptable if prototype velocity data provides a reference class. Still flag calendar targets without uncertainty ranges. | Expected. Team velocity data from actual development justifies specific estimates. |
| **Explaining the document to the reader** | Equally dangerous at every stage — this is a genre violation, not a stage-calibration issue. Flag any sentence that explains a PR/FAQ convention or narrates the document's own drafting/review history. | Same. | Same. |
