# Press Release Structure

A Working Backwards press release is a short document (typically one to two pages) written as if the product has already launched. It is written in the customer's language, not engineering jargon. Every sentence must earn its place.

**This is a future press release.** The product PR/FAQ press release describes the world 6–12 months from now. The dateline is a future date. The customer quote is fictional — an aspirational portrait of the customer experience, not a real testimonial. The external FAQs answer questions a hypothetical customer *would* ask about a product that does not exist yet. All of this is by design. The evidence for whether this future is plausible lives in the internal FAQs and risk assessment, not in the press release.

This is distinct from a **ship-day press release** (produced by `/prfaq:externalize`), which describes a product that has already shipped, uses today's date, and requires real customer testimonials before going to wire.

## Headline

The news in one sentence. Written as a press release headline, not a product name. The headline announces what happened and why it matters.

**Strong:** "Amazon Pharmacy Will Expand Same-Day Medication Delivery to Nearly 4,500 U.S. Cities and Towns by Year End"
**Strong:** "punt-labs Releases prfaq, a Free Claude Code Plugin That Brings Amazon's PR/FAQ Process to Engineers"
**Weak:** "Amazon Prime" — a product name, not a headline
**Weak:** "Project Velocity" — an internal codename that announces nothing

## Sub-headlines

One or two sentences providing supporting detail: key numbers, scope, or context. The sub-headline expands the headline without repeating it.

**Strong:** "Open-source plugin guides solo founders and engineers through product discovery inside the terminal, producing a professionally typeset decision document in under an hour"
**Strong:** "Free two-day shipping for frequent Amazon shoppers"
**Weak:** "A subscription-based logistics optimization program"

The test: if a reader sees only the headline and sub-headline(s), do they understand what this is, who it's for, and why they should care?

## Lede Paragraph

The entire PR/FAQ compressed into one paragraph, opening with a dateline (CITY --- Date). The press release is written as if the product has already launched — **use a future date** in the dateline (typically 6-12 months out) to make the aspirational nature explicit. This prevents readers from mistaking the document for a current announcement. Structure: COMPANY announced PRODUCT, which provides BENEFIT to TARGET CUSTOMER. Unlike ALTERNATIVES, PRODUCT offers DIFFERENTIATOR, enabling customers to OUTCOME.

This paragraph must:
- Name the specific customer (not "users" or "people")
- State the benefit in the customer's terms (not features)
- Differentiate from the status quo
- Promise a concrete outcome

**Common failure:** Writing a feature list instead of a benefit statement. "Product X offers real-time sync, offline mode, and collaborative editing" vs. "Product X lets distributed teams write together as naturally as sitting at the same desk."

## Problem Paragraph

Describe the customer's current reality in concrete, measurable terms. What do they do today? What is the cost (time, money, frustration)? Why do existing solutions fail them?

This paragraph must:
- Name a specific, observable behavior ("spends 3 hours per week manually reconciling spreadsheets")
- Quantify the pain where possible
- Explain why current workarounds are inadequate
- Avoid implying the solution — just describe the problem

**Common failure:** Describing the problem so broadly it applies to everyone and therefore motivates no one. "Businesses struggle with communication" vs. "Field service teams with 50+ technicians lose an average of 4 hours per day to scheduling conflicts because dispatchers rely on phone calls and whiteboards."

## Solution Paragraph(s)

Describe what the product does, from the customer's perspective. Focus on the experience, not the architecture. One or two paragraphs maximum.

This section must:
- Start with the customer's action, not the system's behavior
- Describe the experience in concrete steps
- Explain one or two key mechanisms (how it works) without technical depth
- Connect back to the problem: how each pain point is resolved

**Common failure:** Writing an architecture document. "Leveraging a microservices backend with event-driven processing" vs. "When a technician finishes a job, the app automatically finds the nearest next job and routes them there."

## Customer Quote

A fictional quote from the target customer. The press release is written as if the product has already launched — the customer quote lands the value proposition by showing what life is like after the product exists. This quote is aspirational at every stage. It is never required to be "real" or sourced from actual interviews, because the press release describes the future, not the present. At later stages, the quote should be *informed by* real evidence, but it remains a vision of the customer's experience.

The quote must:
- Come from a named person with a specific role ("Sarah Chen, Operations Manager at BuildCo")
- Reference the before state (the pain)
- Describe the after state (the relief)
- Include a concrete detail that makes it feel real

Do not flag the customer quote as "fabricated" or "fictional" — it is aspirational by design. The evidence for customer demand belongs in the FAQ section ("What evidence do we have that customers want this?"), not in the press release quote.

**Strong:** "Before Product, I spent every Friday afternoon manually reconciling our field reports. Last Friday I left at 3pm. That's not a small thing when you have two kids in soccer."

**Weak:** "Product is great. It really helps us be more efficient. I would recommend it to anyone."

## Getting Started

The three steps a customer takes to begin. This section tests whether the onboarding is actually simple. If you cannot describe getting started in three steps, the product is too complex.

This section must:
- Start with the very first action (sign up, download, connect)
- End with the customer receiving value
- Name a specific timeframe for reaching value ("within 10 minutes")
- Identify what friction was removed ("no credit card required", "no installation needed")

## Spokesperson Quote

A fictional quote from someone at the company (CEO, VP Product, team lead). This quote explains the vision and design philosophy — the "why we built it this way."

The quote must:
- Explain the design choice that makes this product different
- Reference the customer (not the technology)
- Include a quantifiable improvement if possible
- Sound like a real person, not a marketing brochure

## Call to Action

Where to go, when it's available, how much it costs. One paragraph. If you cannot write a clear call to action, you have not defined the product well enough.

## Stage Calibration

Press release evidence expectations shift with document stage (`\prfaqstage{}`):

| Section | Hypothesis | Validated | Growth |
|---------|-----------|-----------|--------|
| **Headline** | Announces the intended product. May be aspirational. | Should reflect validated value proposition. | Should reflect actual market positioning. |
| **Problem** | Can describe problem from inference and market signals. Must be specific and testable. | Must include evidence from customer interviews. Quantified pain preferred. | Must include measured impact data from existing users. |
| **Solution** | Describes intended experience. Speculative on mechanism is OK. | Should reflect prototype or tested experience. | Must describe actual product experience. |
| **Customer Quote** | Fictional. Must feel plausible. Named person with specific role. | Fictional. Should be *informed by* interview insights, but the quote itself is aspirational — the press release describes the future. Named person with specific role. | Fictional. Should be *informed by* real usage patterns and feedback themes. Named person with specific role. The quote lands the value proposition; the FAQ section provides the evidence. |
| **Getting Started** | Describes intended onboarding. Three-step structure is a design commitment. | Should reflect tested onboarding flow. | Must reflect actual onboarding with real metrics. |
| **Spokesperson Quote** | Explains design philosophy and vision. Forward-looking is OK. | Should reflect learnings from validation. | Should reflect proven strategy and demonstrated results. |
