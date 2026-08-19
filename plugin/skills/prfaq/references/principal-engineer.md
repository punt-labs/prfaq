# Principal Engineer Lens

The principal engineer reviews a PR/FAQ for technical honesty. Not whether the product can be built — most things can — but whether the document acknowledges the hard problems, the irreversible decisions, and the operational burden that will outlive the initial build. This guide owns the Feasibility risk dimension.

## The Core Question

**What is the hardest unsolved technical problem, and does the PR/FAQ acknowledge it?**

Every product has one. If the PR/FAQ presents a clean, risk-free technical story, either the author hasn't found it yet or they're hiding it. The principal engineer's job is to surface it.

## Architecture Trade-offs

Every architecture decision is a trade-off. The PR/FAQ should not present the technical approach as inevitable. It should explain what was chosen, what was rejected, and why.

### What to Look For

| Trade-off | Question for the PR/FAQ |
|-----------|------------------------|
| **Monolith vs. services** | Does the scale justify the operational complexity of distributed systems? |
| **Build vs. buy** | For each build decision, why is an off-the-shelf solution inadequate? For each buy decision, what lock-in risk does it create? |
| **Consistency vs. availability** | When the system partitions (and it will), which does the product sacrifice? Does the customer experience reflect that choice? |
| **Real-time vs. batch** | Does the product actually need real-time processing, or is "fast enough" batch simpler and cheaper? |
| **Generality vs. performance** | Is the system optimized for the common case, or does it try to handle every edge case at the cost of complexity? |

### Signals of Weak Architecture Thinking

- The technical FAQ describes only the happy path
- No mention of failure modes or degraded operation
- Architecture driven by technology trends ("we'll use Kubernetes") rather than product requirements
- No discussion of what happens at 10x or 100x the initial scale

## Operational Complexity at Scale

The hardest part of most products is not building them — it is running them. A principal engineer evaluates whether the PR/FAQ accounts for the operational burden.

### Questions the Technical FAQ Should Answer

1. **What breaks first at scale?** — Database writes, API latency, message queue backpressure, storage costs. Name the specific bottleneck.
2. **What is the on-call burden?** — Does this product require 24/7 monitoring? What alerts fire, and what do operators do when they fire?
3. **What is the data retention and growth story?** — How much data does the system accumulate per customer per year? What is the storage cost trajectory?
4. **What is the deployment model?** — Can updates ship without downtime? What is the rollback plan when a deployment fails?
5. **What third-party dependencies exist?** — For each: what happens when it goes down, what is the SLA, is there a fallback?

### Signals of Underestimated Operational Cost

- The timeline includes "build" but not "operate" — no mention of monitoring, alerting, runbooks, or on-call
- Infrastructure costs appear only in the P&L as a flat line, not as a function of usage growth
- "Serverless" or "managed service" used as a synonym for "zero operational burden"
- No discussion of data migrations, schema evolution, or backward compatibility

## Build vs. Buy Decisions

Every component in the system is either built, bought, or borrowed (open source). The principal engineer checks that each choice is deliberate.

### When to Build

- The component is core to the product's differentiation
- No existing solution meets the specific requirements
- The team has deep domain expertise in this area
- The maintenance burden is understood and accepted

### When to Buy or Borrow

- The component is table stakes, not a differentiator (auth, payments, email delivery)
- Proven solutions exist that are cheaper to integrate than to replicate
- The team lacks domain expertise (cryptography, video encoding, search indexing)
- Time-to-market matters more than customization

### Signals of Poor Build/Buy Decisions

- Building commodity infrastructure (custom auth, custom deployment pipelines) while the core product is under-resourced
- "We'll build our own X" without explaining why existing solutions are inadequate
- Buying/integrating a critical-path component with no fallback if the vendor changes terms, raises prices, or shuts down
- No mention of vendor lock-in risk for buy decisions

## Data Model Decisions

Data model choices are the most expensive decisions to reverse. A schema deployed to production with customer data in it is concrete that has set. The principal engineer pays special attention to these.

### What Makes a Data Model Decision Irreversible

- **Normalization choices** — denormalized for performance today may prevent queries needed tomorrow
- **ID schemes** — sequential IDs leak information; UUIDs are large; composite keys complicate joins. Each choice has consequences that last the life of the product
- **Multi-tenancy model** — shared database, shared schema, or isolated databases. Changing this after launch requires a data migration that touches every row
- **Event schema** — if the product stores events (audit logs, analytics, activity streams), the schema must be extensible from day one. You cannot rewrite history
- **Encryption boundaries** — what is encrypted at rest, in transit, and at the application layer. Adding encryption after the fact requires a full data migration

### What to Check in the PR/FAQ

- Does the technical FAQ identify the core data entities and their relationships?
- Are there data model decisions that constrain future features? Are they acknowledged?
- If the product handles customer data, is the data isolation model described?
- Is there a migration strategy for schema changes after launch?

## Dependency Risk

A product is only as reliable as its least reliable dependency.

### Categories of Dependencies

| Type | Examples | Risk |
|------|----------|------|
| **Team dependencies** | Other teams must ship an API, a shared service, or a platform feature | Schedule risk — their priorities may not align with yours |
| **Third-party services** | Cloud providers, SaaS APIs, payment processors | Availability, pricing, and terms-of-service risk |
| **Open-source libraries** | Frameworks, language runtimes, database engines | Maintenance risk — unmaintained dependencies become liabilities |
| **Data dependencies** | External data feeds, partner integrations, regulatory databases | Freshness, accuracy, and access risk |

### What to Check in the PR/FAQ

- Every dependency should be named in the Dependencies FAQ
- Each dependency should have a stated fallback or mitigation
- The timeline should not assume zero delay from dependent teams
- Third-party SLAs should be compared against the product's own SLA commitments

## Using This Framework in Review

The principal engineer should focus on three questions, in order:

1. **What is the hardest technical problem, and is it acknowledged?** If the PR/FAQ glosses over it, the feasibility rating is too low.
2. **Which decisions are irreversible, and are they deliberate?** Data models, multi-tenancy, encryption, ID schemes — these must be chosen consciously, not defaulted into.
3. **What is the operational cost of running this for five years?** Build cost is a one-time expense. Operational cost compounds. If the PR/FAQ only estimates build cost, the viability analysis is incomplete.

## Stage Calibration

Feasibility expectations shift with document stage (`\prfaqstage{}`):

| Area | Hypothesis | Validated | Growth |
|------|-----------|-----------|--------|
| **Architecture** | Directional. Identify the approach and key trade-offs. Detailed design not expected. | Should reflect prototype learnings. Trade-offs grounded in experience. | Must reflect actual architecture with observed performance characteristics. |
| **Hard problems** | Name the unknowns. Propose spike plans. Acceptable to say "we don't know yet." | Hard problems should have mitigation plans informed by prototyping. | Hard problems should be solved or have proven workarounds. |
| **Dependencies** | Identify major dependencies. Fallbacks are aspirational. | Dependencies should be tested or have confirmed availability. | Dependencies should have observed reliability data and SLAs. |
| **Timeline** | Estimate with acknowledged uncertainty. No reference class expected but absence noted. | Should have reference class data from similar builds or from own prototyping velocity. | Must be based on measured team velocity and actual complexity. |
| **Operational cost** | Order-of-magnitude estimate acceptable. "Infrastructure will cost roughly X/month at launch." | Should be informed by prototype infrastructure costs. | Must reflect actual operational costs with growth trajectory. |

**At hypothesis stage**, the principal engineer's primary concern is whether the author has **identified** the hard problems — not whether they've solved them. Glossing over feasibility to focus on value is the anti-pattern to catch.
