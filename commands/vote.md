---
description: Assess whether a PR/FAQ should move forward with a structured go/no-go decision
argument-hint: "[path/to/prfaq.tex ...or multiple paths for portfolio comparison]"
---

# Go/No-Go Decision: PR/FAQ Vote

Synthesize the PR/FAQ into a structured go/no-go recommendation across three decision gates. The vote reads the document's own evidence — risk ratings, FAQs, citations, feature scope — and renders a binary verdict. This is the *decision*; `/prfaq:meeting` is the *deliberation*.

## Decision Gates

The three gates map to Cagan's four risks, reframed as actionable questions:

| Gate | Question | Risks | Key Sections |
|------|----------|-------|-------------|
| **Gate 1** | Is this a customer problem worth solving? | Value + Viability | Problem, Customer Evidence FAQ, TAM FAQ, Revenue Model FAQ, P&L FAQ, Risk Assessment (value + viability ratings) |
| **Gate 2** | Do we have a differentiated solution? | Usability + Feasibility | Solution, Getting Started, Competitive Landscape FAQ, Technical FAQs, Dependencies FAQ, Risk Assessment (usability + feasibility ratings) |
| **Gate 3** | Should we do this now? | Opportunity cost | "Best alternatives" FAQ, Feature Appendix scope, "Why now?" FAQ, meeting decisions (if available) |

**Gate 1 is a hard prerequisite.** A NO-GO on Gate 1 makes the overall verdict NO-GO regardless of Gates 2 and 3. Gates 2 and 3 are still assessed for informational purposes — even a NO-GO project has lessons worth recording.

## Steps

1. **Find the document(s).** Two modes:

   **Single-document mode** — `$ARGUMENTS` is empty or specifies one path. If empty, search for `prfaq.tex` in the project root using Glob. If not found, tell the user to run `/prfaq` first.

   **Multi-document mode** — `$ARGUMENTS` contains two or more `.tex` file paths. Verify each exists. If any is missing, report which ones and stop.

2. **Read reference guides.** Load the evaluation criteria from:
   - `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/four-risks.md` — risk signals (low/high) for each of the four risks
   - `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/unit-economics.md` — viability metrics and what to look for
   - `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/decision-quality.md` — cognitive biases that distort decision-making

3. **Extract structured data from each document.** Read the full `.tex` file and use Grep to extract:

   - `\prfaqstage{value}` — stage (hypothesis / validated / growth). If absent, assume hypothesis.
   - `\prfaqversion{M}{m}` — document version.
   - **Risk ratings** — from the Risk Assessment section. Each of the four risks (Value, Usability, Feasibility, Viability) should have a rating (Low / Medium / High) and a rationale paragraph.
   - **Key FAQ content** — read the answer text (not just the question) for: customer evidence, TAM, competitive landscape, revenue model, P&L, technical risks, dependencies, timeline, "why now?", and "what are we not building?". Also look for a FAQ about best alternatives or opportunity cost.
   - **Feature Appendix** — count items in Must Do, Should Do, and Won't Do. Note if Won't Do has fewer than 3 items.
   - **Citations** — count `\cite{}` references. Count `[CITATION NEEDED]` markers. Note any critical claims (TAM numbers, customer statistics, competitive assertions) without citations.
   - **Getting Started** — count the steps. Note if any step involves account creation, configuration, or "explore" language.
   - **Customer quote** — read it for specificity (concrete before/after) vs. generic platitudes.

4. **Check for prior deliberation.** Use Glob to search for:
   - `./meetings/meeting-summary-*.md` and `./meetings/meeting-hive-summary-*.md` — meeting decisions
   - If found, read the most recent one. Note: which hot spots were REVISE vs KEEP vs DEFER, and whether the revision queue has been applied (check if the `.tex` file's version is higher than at meeting time).

5. **Assess Gate 1: Is this a customer problem worth solving?**

   Evaluate value risk and viability risk together. The question is: *even if we build this perfectly, will customers buy it and will the business model sustain it?*

   **GO signals** (stage-calibrated):
   - Problem section describes a specific, quantifiable pain for a named customer segment
   - Customer evidence FAQ cites primary data (interviews, surveys, usage patterns) — at hypothesis stage, a concrete validation plan is acceptable
   - TAM uses bottoms-up methodology with cited sources — at hypothesis stage, range estimates with stated methodology are acceptable
   - Unit economics are positive at modest scale (or viability lens is appropriate for the product type — see unit-economics.md "When Unit Economics Are Secondary")
   - Value risk and viability risk ratings are consistent with the evidence in the FAQs

   **NO-GO signals:**
   - Problem is generic or reverse-engineered from the solution (skills-forward thinking)
   - No customer evidence and no validation plan
   - TAM is top-down only ("the global market is $X billion") with no bottoms-up grounding
   - Unit economics require implausible scale, or pricing is entirely TBD with no model
   - Value or viability risk rated Low but evidence in the FAQs contradicts the rating

   Render: `Gate 1: GO` or `Gate 1: NO-GO` with 3-5 bullet points of evidence.

6. **Assess Gate 2: Do we have a differentiated solution?**

   Evaluate usability risk and feasibility risk together. The question is: *can we build something customers will actually use, and is it meaningfully different from what already exists?*

   **GO signals:**
   - Competitive landscape FAQ names specific alternatives and articulates a structural (not just feature-gap) differentiation
   - Getting Started section has three clear steps ending in customer value
   - Technical risks are identified with mitigation plans — at hypothesis stage, naming unknowns and proposing spikes is sufficient
   - Dependencies are listed with fallbacks
   - Usability and feasibility risk ratings are consistent with the evidence

   **NO-GO signals:**
   - No competitor named or all competitors dismissed without engagement
   - Differentiation is a feature gap that competitors could close in a quarter
   - Getting Started requires configuration, training, or behavior change with no mitigation
   - Technical FAQs gloss over hard problems or assume zero unknowns
   - The solution is technically elegant but doesn't map to how customers think about the problem

   Render: `Gate 2: GO` or `Gate 2: NO-GO` with 3-5 bullet points of evidence.

7. **Assess Gate 3: Should we do this now?**

   Evaluate opportunity cost. The question is: *given everything else we could do with these resources, is this the best bet?*

   **Single-document mode:** Look for a FAQ that addresses alternatives or opportunity cost. Common forms: "What are the best alternatives for us to pursue if we do not build this?", "Why now?", or "What are we not building?" If none exists, flag the gap:

   > "Gate 3 cannot be fully assessed. The document has no FAQ addressing opportunity cost or alternatives. Add an internal FAQ: 'What are the best alternatives for us to pursue if we do not build this?' This forces the team to confront what they are saying no to by saying yes to this project."

   Even without the alternatives FAQ, assess what's available:
   - "Why now?" FAQ — is there a time-sensitive trigger (market shift, technology inflection, competitive vacuum)?
   - Feature Appendix discipline — does the Won't Do list show deliberate scoping, or is Must Do bloated?
   - Stage appropriateness — is the investment ask calibrated to the evidence stage? (A growth-stage investment with hypothesis-stage evidence is a misallocation.)

   **Multi-document mode:** Compare documents on the same criteria. For each document, extract the core value proposition, the stage, the risk profile, and the resource ask. Then rank by strength of evidence relative to investment required. The ranking should surface:
   - Which projects have the strongest evidence for customer demand?
   - Which have the best risk-adjusted return?
   - Which are at a stage where further investment is premature (need validation first)?

   Render: `Gate 3: GO` or `Gate 3: NO-GO` with reasoning. If no alternatives FAQ exists, flag the gap in the reasoning but assess based on available signals ("Why now?", feature discipline, stage appropriateness). A missing alternatives FAQ weakens the case but is not an automatic NO-GO — the other signals may be sufficient.

8. **Render the overall verdict.**

   **Single-document format:**

   ```
   VOTE: [GO / NO-GO]
   Document: [filename] (v[version], [stage] stage)

   Gate 1: Customer Problem Worth Solving — [GO / NO-GO]
     [bullet points of evidence]

   Gate 2: Differentiated Solution — [GO / NO-GO]
     [bullet points of evidence]

   Gate 3: Should We Do This Now — [GO / NO-GO]
     [bullet points of evidence]

   Prior Deliberation:
     [summary of meeting decisions if available, or "No meeting summaries found."]

   Decision Rationale:
     [2-3 sentences explaining the overall verdict — what's the strongest reason for or against?]

   Recommended Next Steps:
     [ordered list — what should the team do next regardless of the verdict?]
   ```

   Overall verdict logic:
   - Any gate NO-GO → overall **NO-GO**
   - All three gates GO → overall **GO**

   **Multi-document format:** Show a condensed verdict for each document, then a portfolio comparison table:

   ```
   DOCUMENT: [filename] (v[version], [stage] stage)
   - Gate 1: [GO/NO-GO] — [1-sentence summary]
   - Gate 2: [GO/NO-GO] — [1-sentence summary]
   - Gate 3: [GO/NO-GO] — [1-sentence summary]
   - Overall: [GO/NO-GO]

   [repeat for each document]

   PORTFOLIO RANKING

   | Rank | Document | Stage | Gate 1 | Gate 2 | Gate 3 | Verdict |
   |------|----------|-------|--------|--------|--------|---------|
   | 1    | ...      | ...   | GO     | GO     | GO     | GO      |
   | 2    | ...      | ...   | GO     | NO-GO  | GO     | NO-GO   |

   Portfolio Recommendation:
     [which projects to fund, which to defer, which to kill, and why]
   ```

9. **Offer next steps.** Based on the verdict:

   - **GO** — "This project clears all three gates. Consider running `/prfaq:externalize` to generate a ship-day press release when ready."
   - **NO-GO on Gate 1** — "The core value proposition needs work. Consider running `/prfaq:meeting` to stress-test the problem statement and customer evidence, then `/prfaq:feedback` to revise."
   - **NO-GO on Gate 2** — "The solution needs sharpening. The problem is worth solving, but the current approach has gaps in [differentiation/feasibility/usability]. Revise the Solution section and technical FAQs."
   - **NO-GO on Gate 3** — "The project may be worth doing, but the case for doing it *now* is weak. Add the alternatives FAQ and articulate the time-sensitive trigger."
