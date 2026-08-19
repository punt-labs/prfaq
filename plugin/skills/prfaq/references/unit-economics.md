# Unit Economics

Unit economics determine whether a product creates or destroys value with each customer it acquires. A PR/FAQ with strong unit economics can justify aggressive investment; one with weak or unexamined unit economics is a bet disguised as a plan. This guide owns the Viability risk dimension.

## Core Metrics

| Metric | Definition | What It Tells You |
|--------|-----------|-------------------|
| **CAC** (Customer Acquisition Cost) | Total sales + marketing spend / new customers acquired | How much it costs to get one customer |
| **LTV** (Lifetime Value) | Average revenue per customer x gross margin x average lifespan | How much value one customer creates over their lifetime |
| **LTV:CAC Ratio** | LTV / CAC | Whether the business model works. Below 1:1 means you lose money on every customer. 3:1 is a common benchmark for healthy SaaS |
| **Payback Period** | CAC / (monthly revenue per customer x gross margin) | How long until a customer pays back the cost of acquiring them |
| **Gross Margin** | (Revenue - COGS) / Revenue | How much of each dollar is available after direct costs |
| **Contribution Margin** | Revenue - variable costs (COGS + variable sales/support) | How much each customer contributes toward fixed costs and profit |

## When Unit Economics Matter

Unit economics are central to viability for any product where the business model depends on per-customer revenue:

- **SaaS / subscription products** — CAC payback period determines cash flow needs. A 24-month payback with monthly churn of 3% means most customers churn before they pay back acquisition cost.
- **Marketplace / platform products** — both supply-side and demand-side acquisition costs matter. A marketplace that subsidizes one side must have clear unit economics on the other.
- **Usage-based products** — revenue per customer varies widely. LTV estimates must account for the distribution, not just the average.
- **E-commerce / transactional** — gross margin per transaction determines how much can be spent on acquisition and fulfillment.

## When Unit Economics Are Secondary

Some products have viable models where per-customer unit economics are not the primary lens:

- **Internal tools** — value is measured in engineering time saved or operational risk reduced, not per-customer revenue
- **Open-source / developer tools** — monetization may come from enterprise tiers, support contracts, or hosting; the free tier has no direct unit economics
- **Platform plays** — early-stage platforms may deliberately run negative unit economics to build network effects, with a credible path to positive economics at scale
- **Strategic moats** — some products exist to protect or extend an existing revenue stream (e.g., a free feature that reduces churn on a paid product)

A PR/FAQ for these products should still address viability, but through the appropriate lens (cost savings, strategic value, network effects) rather than forcing a CAC/LTV framework that does not fit.

## Evaluating Unit Economics in a PR/FAQ

### Revenue Model FAQ

The revenue model FAQ should answer:

1. **What is the pricing structure?** — subscription, usage-based, freemium, transactional, or hybrid
2. **What is the expected revenue per customer per year?** — with a basis for the estimate (comparable products, willingness-to-pay research, pricing experiments)
3. **What are the direct costs per customer?** — infrastructure, support, onboarding, third-party API costs
4. **What is the gross margin?** — and how does it change with scale

### P&L Projection FAQ

The P&L should show:

1. **Year 1 and Year 3 projections** — revenue, COGS, gross profit, operating expenses, net income
2. **Key assumptions clearly labeled** — customer count, ARPU, churn rate, CAC, headcount
3. **Sensitivity analysis** — what happens if churn doubles, if CAC is 2x higher, if ARPU is 30% lower
4. **Break-even point** — when does the product become self-sustaining

### Signals of Strong Unit Economics

- LTV:CAC ratio above 3:1 with a credible basis for both numbers
- Payback period under 12 months
- Gross margin above 60% (for software products)
- Revenue per customer grows over time (expansion revenue, upsell)
- Churn rate below 2% monthly (for B2B SaaS)
- COGS scale sublinearly with customers (marginal cost decreases)

### Signals of Weak or Missing Unit Economics

- No pricing in the PR/FAQ ("we'll figure out pricing later")
- LTV calculated without accounting for churn
- CAC that assumes organic/viral growth with no paid acquisition budget
- P&L that reaches profitability only at implausible scale
- Variable costs that scale linearly or superlinearly with customers (e.g., human-in-the-loop per transaction)
- "Freemium" model with no analysis of free-to-paid conversion rate
- Revenue projections based on TAM capture percentage rather than bottoms-up customer math

## Common Mistakes

**Confusing revenue with margin.** A product with $100/month revenue and $90/month infrastructure cost has worse unit economics than a product with $20/month revenue and $2/month cost.

**Ignoring support costs.** Enterprise products often have significant per-customer support, onboarding, and account management costs that destroy the apparent margin.

**Assuming zero CAC.** "Developers will find us through word of mouth" is a hope, not a customer acquisition strategy. Even organic channels have costs (content creation, developer relations, conference sponsorship).

**Using average LTV without segmentation.** If 10% of customers generate 80% of revenue, the average LTV is misleading. The PR/FAQ should identify which customer segment drives unit economics.

**Projecting current unit economics at future scale.** CAC typically increases as you exhaust early-adopter channels. Support costs increase as you move beyond self-serve customers. Gross margin may decrease if infrastructure costs have step functions.

## Stage Calibration

Unit economics expectations shift significantly with document stage (`\prfaqstage{}`):

| Metric | Hypothesis | Validated | Growth |
|--------|-----------|-----------|--------|
| **Pricing** | Proposed pricing model with rationale. Willingness-to-pay is inferred from comparables. | Should have pricing test results or early customer feedback on pricing. | Must reflect actual pricing with observed conversion rates. |
| **CAC** | Estimated from comparable products or channels. Labeled as assumption. | Should have early channel data (cost per signup, conversion from trials). | Must be calculated from actual spend and acquisition data. |
| **LTV** | Projected from assumptions about retention and ARPU. Sensitivity analysis required. | Should incorporate early retention data and actual revenue observations. | Must use measured churn, expansion revenue, and actual ARPU. |
| **P&L** | Framework with labeled assumptions. Acceptable to say "Year 1 P&L is speculative." | Key line items should have real data points. Sensitivity analysis grounded. | Must reflect actual financial performance. |
| **Break-even** | Range estimate acceptable. "Between X and Y customers." | Should be narrowing based on real cost data. | Should be known or achieved. |

**At hypothesis stage**, the viability section's purpose is to verify that a plausible business model exists — not to prove it works. The quality signal is intellectual honesty about what's assumed vs. known.

**At growth stage**, projections without actuals are a critical issue. If the product has users, the numbers should come from the product, not from spreadsheets.
