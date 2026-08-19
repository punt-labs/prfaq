# Four Risks Framework

Marty Cagan's four risks framework provides the analytical backbone for evaluating a PR/FAQ. Every product must address all four risks. A PR/FAQ that ignores any one of them is incomplete.

## The Four Risks

| Risk | Question | Where It Lives in the PR/FAQ |
|------|----------|------------------------------|
| **Value** | Will customers buy or choose to use this? | Summary, Problem, Customer Quote, External FAQs, TAM analysis |
| **Usability** | Can customers figure out how to use it? | Getting Started, Solution paragraphs, Onboarding FAQ |
| **Feasibility** | Can we build it with available technology, time, and skills? | Technical FAQs, Timeline, Dependencies |
| **Viability** | Does it work for the business (revenue, cost, legal, brand)? | Business FAQs, P&L projection, Revenue model |

## Assessing Each Risk

### Value Risk

The most important risk. If customers don't want it, nothing else matters.

**Low risk signals:**
- Customer interviews where subjects describe the problem unprompted
- Existing workarounds that customers actively maintain (spreadsheets, scripts, manual processes)
- Competitor success in an adjacent space proving demand exists
- Waitlist or letter-of-intent commitments

**High risk signals:**
- The problem was identified by the team, not by customers
- No concrete evidence of demand beyond intuition
- The "customer" is actually the company itself
- The product solves a problem customers don't know they have (requires education before adoption)

### Usability Risk

Can a customer go from zero to value without help?

**Low risk signals:**
- Getting Started section has three clear steps
- Time-to-value is minutes, not days
- The product fits into existing workflows rather than replacing them
- Similar interaction patterns exist in products customers already use

**High risk signals:**
- Getting Started requires configuration, integration, or training
- The product requires behavior change from the customer
- No analogous product exists (customers have no mental model)
- The product serves experts and novices with the same interface

### Feasibility Risk

Can we actually build this?

**Low risk signals:**
- Core technology is proven (we've built similar systems before)
- No dependencies on unproven technology
- Team has domain expertise
- Prototype or spike has validated the hardest technical question

**High risk signals:**
- Requires breakthrough in ML, distributed systems, or other frontier technology
- Depends on third-party APIs or data sources outside our control
- Team has no experience in this domain
- Timeline assumes zero unknowns

### Viability Risk

Does it work as a business?

**Low risk signals:**
- Unit economics are positive at modest scale
- Revenue model is proven in the market (subscription, usage-based, etc.)
- No regulatory barriers
- Compatible with existing brand and strategy

**High risk signals:**
- Requires massive scale before unit economics work
- Novel pricing model that customers may resist
- Legal or regulatory uncertainty
- Cannibalizes existing revenue without clear net gain

## Review Meeting Criteria

When a PR/FAQ is presented for review, evaluators should ask these seven questions:

1. **Is the target customer clearly defined and specific?**
   "Small business owners" is too broad. "Independent restaurant owners with 1-3 locations and no dedicated IT staff" is specific.

2. **Is the problem significant and well-evidenced?**
   Can you quantify the cost of the problem? Is there evidence beyond anecdote?

3. **Is the solution meaningfully differentiated?**
   If a competitor could copy this in a quarter, the differentiation is insufficient.

4. **Can a customer understand and start using it easily?**
   The Getting Started section is the litmus test. Three steps, value in minutes.

5. **Can it be built with available technology and resources?**
   Is the timeline realistic? Are dependencies identified? Is there a spike plan for unknowns?

6. **Do the unit economics and business model work?**
   At what scale does this become profitable? What are the cost drivers?

7. **Is this the highest-priority use of the team's time?**
   Opportunity cost is real. A good product that displaces a great product is a net loss.

## Decision Outcomes

After review, the PR/FAQ leads to one of these outcomes:

| Decision | Meaning | Next Step |
|----------|---------|-----------|
| **Go** | All four risks are adequately addressed | Proceed to detailed planning and resourcing |
| **Not differentiated** | Value risk too high — customers won't switch | Rethink the unique value proposition or kill the idea |
| **TAM too small** | Value risk — the market isn't large enough | Consider adjacent markets, pivot the customer definition, or kill |
| **Investment too risky** | Feasibility risk — the technical bet is too large | Propose a spike or reduced-scope proof of concept |
| **Not feasible** | Feasibility risk — cannot be built with known technology | Kill or defer until technology matures |
| **Not viable** | Viability risk — economics, legal, or strategic conflict | Restructure the business model or kill |
| **Deprioritized** | Good idea, wrong time — higher-priority work exists | Shelve with a trigger condition for re-evaluation |
| **Iterate** | Promising but incomplete — specific sections need rework | Revise the PR/FAQ and re-present |

## Stage Calibration

The four risks framework applies at every stage, but which risks dominate shifts with product maturity (`\prfaqstage{}`):

| Risk | Hypothesis | Validated | Growth |
|------|-----------|-----------|--------|
| **Value** | Primary risk. Is the problem real? Inferred demand OK if testable. | Should have interview data. Inferred-only demand is a warning. | Must have usage data. Demand should be measured, not claimed. |
| **Usability** | Speculative. Getting Started describes intent, not tested flow. | Should reflect prototype testing. Three-step onboarding tested with users. | Must reflect real onboarding metrics (completion rate, time-to-value). |
| **Feasibility** | Focus on identifying unknowns and spike plans. Architecture is directional. | Should have reference class data. Hard problems named with mitigation. | Must reflect build experience. Timeline based on actuals, not estimates. |
| **Viability** | Projections with labeled assumptions. Unit economics framework OK without real numbers. | Should have some real data points (early pricing tests, cost observations). | Must reflect actual operations (real CAC, LTV, churn from live data). |

**At hypothesis stage**, the most important signal is whether the author has identified the riskiest assumption and proposed a test for it — not whether they have evidence.

**At growth stage**, the most important signal is whether the evidence actually supports the risk ratings — a "Low" rating with no supporting data is a critical issue.
