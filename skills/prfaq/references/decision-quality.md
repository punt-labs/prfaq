# Decision Quality Checklist

Adapted from Kahneman, Lovallo, and Sibony, "Before You Make That Big Decision" (HBR, June 2011). The original framework provides 12 questions a decision-maker should ask before approving a recommendation. Applied here to PR/FAQ review: the peer reviewer plays the role of the decision-maker evaluating the PR/FAQ author's recommendation to build a product.

## Self-Interest Biases

**Is there reason to suspect the author's motivations?**

Not malice — enthusiasm. The author wants to build this thing. That energy is valuable but it biases the document toward optimism. Look for: problem descriptions that feel reverse-engineered from the solution, competitive analysis that dismisses alternatives too quickly, risk assessments with no High ratings.

PR/FAQ signal: Every section reads as advocacy rather than analysis. The document sells rather than evaluates.

## Affect Heuristic

**Has the author fallen in love with the proposal?**

The affect heuristic means that liking the solution makes everything about it seem better — the market seems bigger, the risks seem smaller, the timeline seems shorter. The antidote is separating the evaluation of the problem from the evaluation of the solution.

PR/FAQ signal: The Problem section is thin or abstract ("engineers lack discipline") while the Solution section is rich and specific. The ratio should be reversed — a deep understanding of the problem should drive a focused solution.

## Groupthink

**Were dissenting opinions surfaced and explored?**

A PR/FAQ written by one person (or one person + an LLM) has no natural dissent. The Won't Do section and the Risk Assessment are the structural places where dissent lives. If the Won't Do list is short and the risks are all Low, dissent was suppressed.

PR/FAQ signal: No risk rated Medium or High. Won't Do section has fewer than 3 items. No FAQ addresses "why might this fail?"

## Saliency Bias

**Is the recommendation overly influenced by analogy to a memorable success?**

"Amazon does Working Backwards, and they're successful, so this process works" is saliency bias. The analogy must be examined: what are the relevant similarities and differences? A PR/FAQ that leans heavily on a single analogy without examining its limits is vulnerable.

PR/FAQ signal: Repeated reference to one successful example (company, product, framework) without analyzing why the analogy holds or where it breaks down.

## Confirmation Bias

**Were credible alternatives seriously considered?**

The competitive landscape FAQ should engage with alternatives respectfully. If every competitor is dismissed with a single sentence, the author hasn't genuinely evaluated them. A strong PR/FAQ explains why the alternative is reasonable but insufficient — not why it's bad.

PR/FAQ signal: Competitive FAQ uses words like "merely," "just," "only" to describe alternatives. No alternative is described as having any advantage. The differentiation feels like marketing rather than analysis.

## Availability Bias

**If you had to make this decision again in a year, what information would you want?**

This question identifies what's missing from the evidence base. The PR/FAQ should surface what is unknown, not just what is known. The Customer Evidence FAQ is the primary location for this: does it distinguish between primary evidence (interviews, data) and inference (market signals, analogies)?

PR/FAQ signal: Customer evidence FAQ presents only inferred demand ("the market is growing") with no primary customer data (interviews, surveys, usage data). No acknowledgment of what evidence is missing.

## Anchoring Bias

**Do you know where the numbers came from?**

TAM estimates, timeline projections, adoption rates, pricing assumptions — every number in a PR/FAQ should have a traceable source. Numbers without provenance are anchors that feel factual but aren't.

PR/FAQ signal: Market size quoted without citation. Timeline stated without reference class (how long did similar products take?). "Most customers see value within X" with no basis for X.

## Halo Effect

**Is the team assuming success in one area transfers to another?**

Technical feasibility does not imply market demand. An elegant architecture does not mean users will adopt it. A strong team does not guarantee the right product. The four risks framework (Value, Usability, Feasibility, Viability) exists precisely to prevent halo transfer across dimensions.

PR/FAQ signal: Feasibility risk rated Low and used to justify optimism about Value risk. "We can build it, therefore customers will want it." Risk ratings that all lean the same direction (all Low or all Medium) suggest halo contamination.

## Sunk-Cost Fallacy

**Is the recommendation shaped by past decisions rather than future value?**

For new products, sunk cost manifests as solution design driven by existing codebase, team skills, or technology investments rather than customer need. "We already have X, so we'll build on X" is sunk-cost reasoning if X doesn't serve the customer's problem.

PR/FAQ signal: Solution section describes technical approach in terms of existing infrastructure. Getting Started section requires the user to already be in a specific ecosystem. The product is optimized for the builder, not the customer.

## Overconfidence and Planning Fallacy

**Is the base case overly optimistic?**

The planning fallacy means that insiders systematically underestimate time, cost, and risk while overestimating benefits. The antidote is the outside view: what happened when others attempted similar products?

PR/FAQ signal: Timeline has no buffer. Feasibility section acknowledges no hard problems. No reference to comparable products/projects and their actual timelines. The Getting Started section promises value in an implausibly short timeframe.

## Disaster Neglect

**Is the worst case bad enough?**

Run a pre-mortem: "It's a year from now and this product failed. Why?" If the PR/FAQ cannot articulate a plausible failure scenario, the risk assessment is incomplete. The Value risk section is the natural home for this analysis.

PR/FAQ signal: No FAQ addresses "what happens if this doesn't work?" Risk assessment doesn't describe what failure looks like. No discussion of what the team would do differently if early signals are negative.

## Loss Aversion

**Is the recommendation overly cautious?**

Loss aversion in a PR/FAQ manifests as an artificially narrow scope driven by fear of failure rather than strategic focus. The Won't Do list should reflect deliberate positioning choices, not defensive pruning.

PR/FAQ signal: Must Do list is minimal (hedging the bet). Should Do list is large (deferring commitment). Won't Do rationales are "too risky" rather than "doesn't serve our customer." The product tries to be small enough that it can't fail, rather than focused enough that it can succeed.

## Using This Framework

The peer reviewer should not mechanically check all 12 biases. Instead:

1. Read the PR/FAQ once for overall impression
2. On second read, flag sections where a specific bias pattern appears
3. For each flag, cite the specific text that triggered it and which bias applies
4. Rate severity: **critical** (the bias undermines the core argument), **warning** (the bias weakens a section), **suggestion** (the bias is present but minor)
5. Distinguish between biases the author can fix (better evidence, clearer language) and biases that require the user's judgment (strategic choices, risk tolerance)
