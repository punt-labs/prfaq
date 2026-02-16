# FAQ Structure

The FAQ section is where the PR/FAQ earns its credibility. The press release sells the vision; the FAQ stress-tests it. A PR/FAQ with a strong press release and weak FAQs is a pitch deck, not a decision-making tool.

## External FAQs (Customer-Facing)

External FAQs answer questions a real customer would ask. They are written in plain language, no jargon, no acronyms. If a customer would need a glossary, rewrite.

### Required Questions

Every PR/FAQ must answer at minimum:

1. **What is it and who is it for?**
   One paragraph. Name the product, name the customer, state the core job-to-be-done. A customer reading only this answer should know whether to keep reading.

2. **How is this different from [leading alternative]?**
   Name the specific competitor or workaround. Do not say "unlike existing solutions." State the concrete difference and why it matters to the customer. If you cannot name a specific alternative, you do not understand the competitive landscape.

3. **How do I get started?**
   Repeat the Getting Started section from the PR in FAQ form. This repetition is intentional — it reinforces simplicity and tests consistency.

4. **How much does it cost?**
   Even if pricing is TBD, state the model (subscription, usage-based, freemium). "We haven't decided" is a valid internal FAQ answer but not a valid external one.

5. **What happens to my data?**
   Privacy, security, portability. Customers increasingly ask this first. If the product touches customer data, this FAQ is mandatory.

### Product-Specific Questions

Add 3-5 questions specific to this product. Think about:
- The objection a skeptical customer would raise
- The clarification a confused customer would need
- The edge case a power user would ask about
- The concern a buyer (not user) would have

## Internal FAQs (Business-Facing)

Internal FAQs answer questions leadership, finance, and engineering would ask. They are organized into three categories matching the four risks framework.

### Value & Market

1. **What is the total addressable market (TAM)?**
   Provide a bottoms-up estimate. Name the customer segment, estimate the count, estimate willingness to pay. Top-down TAM ("the global SaaS market is $200B") is not useful.

2. **What evidence do we have that customers want this?**
   List concrete evidence: customer interviews (how many, what they said), survey data, usage patterns in existing products, support ticket analysis, competitive win/loss data. "We think customers want this" is not evidence.

3. **Who are the competitors and why will we win?**
   Name each competitor. State their strengths honestly. Explain the specific gap or shift that creates an opening. "We'll execute better" is not a strategy.

4. **What is the customer acquisition strategy?**
   How will customers discover and adopt this product? Be specific about channels, costs, and conversion assumptions.

5. **What is your next step to validate your vision?** *(Required at hypothesis stage.)*
   Name the single most important thing you will do next to test whether the vision is right. Not a plan — a next step. "Interview 10 target users" or "ship a beta to 20 early adopters and measure completion rate." This FAQ forces a commitment to action. At validated stage, this FAQ should be replaced or updated with results from that step. At growth stage, it should describe the next growth experiment.

### Technical

5. **What are the major technical risks?**
   List each risk, its probability, its impact, and the mitigation plan. Include unknowns — "we don't know if X is feasible and plan to spike it in week 2" is a strong answer.

6. **What dependencies exist on other teams or systems?**
   Name each dependency, its current status, and the fallback if it is not available.

7. **What is the estimated development timeline?**
   Break into phases with milestones. Include what is cut if the timeline compresses. Be explicit about what "done" means for each phase.

8. **What is the scaling story?**
   If the product succeeds, what breaks first? At 10x users, 100x data, global distribution — where are the bottlenecks?

### Business

9. **What is the revenue model?**
   How does this make money? State the pricing, the unit economics at scale, and the path to profitability. If it's a free product, explain the strategic value.

10. **What does the P&L look like at steady state?**
    Project costs (infrastructure, support, development) and revenue at 1-year, 3-year horizons. Include sensitivity analysis for key assumptions.

11. **What are the key metrics and how will we measure success?**
    Name 3-5 metrics. For each, state the target, the measurement method, and the decision threshold ("if metric X is below Y after Z months, we will reconsider").

12. **Why now? What has changed?**
    Technology shift, market shift, regulatory change, competitive vacuum, or internal capability that makes this the right time. "We should have built this last year" means you're late, not timely.

13. **What are we not building?**
    Explicitly state what is out of scope for V1. This demonstrates prioritization discipline and prevents scope creep during development.

## LaTeX Environments

### FAQ Pairs

Each FAQ is written inside a `faqpair` environment that takes the question as its argument. FAQs are numbered automatically (Q1, Q2, Q3...) across all sections. Add `\label{faq:slug}` after `\begin{faqpair}` to make a FAQ referenceable. Use `\faqref{faq:slug}` from the press release or other FAQs to create clickable "FAQ 7" links.

```latex
\begin{faqpair}{What is the total addressable market?}\label{faq:tam}
  TAM analysis with supporting data and \cite{key} citations.
\end{faqpair}
```

When the press release makes a judgment call, cross-reference the FAQ that explains the reasoning: `(see \faqref{faq:tam})`.

### Feature Appendix

The Feature Appendix follows the FAQ and risk assessment sections. Each feature entry uses `\featureitem{Name}{Rationale}` inside an `enumerate` environment. Features are numbered continuously (F1, F2, F3...) across Must Do, Should Do, and Won't Do categories. Add `\label{feat:slug}` after each `\featureitem` to make it referenceable. Use `\featureref{feat:slug}` from other sections to create clickable "Feature 3" links.

```latex
\subsection*{Must Do}

\begin{enumerate}[nosep,leftmargin=2.5em]
  \featureitem{Discovery workflow}{structured questions that guide the user}\label{feat:discovery}
  \featureitem{PDF compilation}{shareable artifact, not a disposable brainstorm}\label{feat:latex}
\end{enumerate}
```

Three categories, no others:

- **Must Do** — Essential for launch. Without these, the product does not solve the core problem.
- **Should Do** — Meaningfully improve the product but not launch-blocking. Fast follow-up candidates.
- **Won't Do** — Explicitly excluded. Naming what you won't build prevents scope creep and clarifies the product's identity. The Won't Do rationale should explain *why not*.

## Stage Calibration

FAQ depth and evidence expectations scale with document stage (`\prfaqstage{}`):

| FAQ Area | Hypothesis | Validated | Growth |
|----------|-----------|-----------|--------|
| **Customer Evidence** | Acknowledge absence of primary data. State validation plan. | Cite real interviews or user tests. Primary data expected. | Cite usage data, retention, NPS. Quantitative evidence required. |

**Note:** "Customer Evidence" refers to the FAQ section where evidence for demand is presented. This is distinct from the **press release customer quote**, which is always aspirational (the press release describes the future). Do not flag the press release quote as needing "real" sources — that is the FAQ's job. See `pr-structure.md` for customer quote guidance.
| **TAM** | Range estimates with stated methodology. Analogies and proxies acceptable if labeled. | Bottoms-up estimate with cited sources. Proxies should be validated. | Actuals from existing market presence. Top-down and bottoms-up should converge. |
| **Competitive Landscape** | Named competitors with honest assessment. Trajectory analysis is inference. | Should include competitive response analysis based on real market signals. | Must reflect observed competitive behavior and market share data. |
| **Technical FAQs** | Identify unknowns. Architecture is directional. Spike plans for hard problems. | Reference class data for similar builds. Hard problems with mitigation plans. | Based on actual build experience. Timeline from measured velocity. |
| **Business FAQs** | Revenue model described. P&L uses labeled assumptions. | Should have early pricing signals or cost observations. | Must use actual financial data from operations. |
| **Feature Appendix** | Scope is aspirational. Won't Do reflects early positioning choices. | Must Do validated by user feedback. Should Do prioritized by evidence. | Must Do proven by usage. Scope changes justified by data. |

**Key principle:** Every stage requires intellectual honesty about what is known vs. assumed. At hypothesis stage, the quality signal is explicit labeling of assumptions. At growth stage, the quality signal is evidence replacing assumptions.
