---
name: prfaq
description: >
  This skill should be used when the user asks to "write a PR/FAQ",
  "prfaq", "working backwards", "product discovery", "evaluate a product idea",
  "press release FAQ", "test product value", "revise prfaq", "update prfaq",
  "add research to prfaq", "add FAQs", "run a meeting", "review meeting",
  "hive meeting", "autonomous meeting", "consensus meeting",
  "stress test my prfaq", or wants to use the Amazon Working Backwards
  process to evaluate whether a product or feature is worth building.
---

# Working Backwards: PR/FAQ

## Purpose

Guide the user through the Amazon Working Backwards process to produce a professional PR/FAQ document. The output is a LaTeX file that compiles to a polished PDF suitable for executive review and product decision-making. The process forces clarity about customer value, surfaces risks early, and creates a shared artifact for go/no-go decisions.

## When to Use

- Evaluating whether a new product or feature is worth building
- Forcing specificity on a vague product idea
- Preparing a product pitch for leadership review
- Testing whether a team truly understands the customer problem
- Structuring a go/no-go decision with an auditable artifact

## Revise Mode

Before starting the full workflow, check if a `prfaq.tex` file already exists in the project root (or the path the user specifies). If it does, enter **revise mode** instead of starting from scratch.

1. **Read the existing document.** Parse the `.tex` file to understand what's already written — the press release, FAQs, and risk assessment.

2. **Ask what to revise.** Present the user with the sections found and ask what they want to improve. Common revision goals:
   - **Refine the product** — sharpen the problem statement, solution, or differentiation based on new thinking
   - **Incorporate research** — thread new primary data (customer interviews, market analysis, survey results) into existing sections. Run Phase 0 research discovery to find new materials.
   - **Add FAQs** — add new external or internal FAQ pairs to cover questions that came up in review
   - **Strengthen evidence** — replace inferred claims with primary data, add citations, improve specificity
   - **Update risk assessment** — revise risk ratings based on new information or changed assumptions
   - **Revise feature appendix** — move features between must/should/won't categories as scope evolves

3. **Edit surgically.** Only modify the sections the user wants changed. Read the existing `.tex` file, make targeted edits, and preserve everything else. Do not regenerate the entire document.

4. **Recompile and review.** After edits, run the compile script and present the changes for review. If the compile script reports overfull hbox warnings, fix them before presenting (see Phase 4 for common fixes). Offer to re-run the peer reviewer (Phase 3c) on the revised document. Offer further iteration.

If the user explicitly asks to start a new PR/FAQ (not revise), proceed to the full workflow below even if a document exists.

## Workflow

### Stage and Version Detection

When working with an existing document (revise mode), read the `.tex` file and extract:
- **Stage** via `\prfaqstage{value}`. Valid stages: **hypothesis**, **validated**, **growth**. If absent, assume hypothesis.
- **Version** via `\prfaqversion{major}{minor}`. If absent, add `\prfaqversion{1}{0}` to the preamble.

Stage affects evidence expectations throughout the workflow:
- **Hypothesis** — Pre-validation. No primary customer data required. Logical consistency and testable assumptions matter most. Fictional customer quotes expected. `[CITATION NEEDED]` markers are acknowledged gaps, not failures.
- **Validated** — Post-interviews or post-testing. Customer interviews and usability data expected. TAM should have real data sources. Risk ratings should reflect actual evidence, not assumptions.
- **Growth** — Existing product with users. All claims should be data-backed. Usage analytics, churn rates, and unit economics should come from real operations, not projections.

### Phase 0: Research Discovery

Before asking the user any questions, look for primary research that should ground the entire document.

1. **Scan for research materials.** Use Glob to check for `./research/**/*` in the project root. If the directory exists, list the files found (PDFs, markdown, text, etc.).

2. **If research files are found:**
   - Read and summarize each file (prioritize `.md`, `.txt`, `.pdf`; skip binary files that aren't PDFs).
   - Present a summary to the user: "I found these research sources in `./research/`. Here's what they contain..." Ask which are relevant to this PR/FAQ.
   - Extract key data points: customer quotes, pain points, market sizing, competitive intel, usage metrics, survey results.

3. **If no research directory exists:**
   - Ask the user: "Do you have primary research — customer interviews, survey data, market analysis, competitive intelligence, or usage analytics — that should inform this PR/FAQ? If so, you can place files in `./research/` or paste key findings directly."
   - If the user provides data inline, capture and organize it the same way.

4. **Invoke the researcher agent.** Use the Task tool with `subagent_type: "prfaq:researcher"`. Pass the user's product description and any specific claims or topics to investigate. The researcher autonomously discovers `./research/` files (including its own prior results), searches the web for claims not already cached, and queries any available MCP data providers (quarry-mcp, financial data servers, etc.). Results are persisted to `./research/` for future runs.

   The researcher returns three sections:
   - **Evidence Found** — per-claim verdicts (supported/contradicted/unsupported) with sources and recommendations
   - **Bibliography Entries** — ready-to-append biblatex entries
   - **Research Gaps** — claims where no evidence was found, with suggested actions

   After receiving the results:
   - Create the `.bib` file (same directory and basename as the `.tex` file — e.g., `prfaq.tex` → `prfaq.bib`) with the bibliography entries the researcher returned.
   - Present the findings to the user: what was supported, what was contradicted, what gaps remain.
   - The user can also invoke the researcher standalone later via `/prfaq research` to verify specific claims or find additional evidence.

5. **Carry forward.** Compile all discovered research into a working context that you reference throughout Phases 1–5. Specifically thread research evidence into:
   - **Problem section** — evidence of customer pain
   - **Customer evidence FAQ** — primary data over inferred claims
   - **TAM/market FAQ** — real market sizing where available
   - **Competitive landscape FAQ** — named competitors and positioning
   - **Risk assessment** — note which risk assessments are grounded in primary data vs. inferred
   - Flag any claims in the final document that are unsupported by available evidence.

### Phase 1: Discovery

Before writing anything, gather the inputs that make a PR/FAQ credible. If Phase 0 found research, use it to sharpen these questions — ask about specific customer segments, pain points, or competitors surfaced in the research rather than asking generic questions.

Ask the user these questions (adapt based on what they've already shared and what research revealed):

1. **Stage** — What stage is this product at? Ask via AskUserQuestion with three options:
   - **Hypothesis** — Pre-validation. No users yet, testing whether the idea is worth building.
   - **Validated** — Post-interviews or post-testing. Some real evidence, iterating on a proven concept.
   - **Growth** — Existing product with users and data. Adding features or repositioning.

   Set `\prfaqstage{value}` in the `.tex` preamble based on the answer (always lowercase: `hypothesis`, `validated`, or `growth`). This calibrates evidence expectations for peer review and meetings.

2. **Customer** — Who is the specific target customer? What is their role, context, and daily reality?
3. **Problem** — What problem does this customer have today? How do they currently cope? What makes existing solutions inadequate?
4. **Solution** — What is the product or feature? How does it work at a high level?
5. **Differentiation** — Why is this better than what exists? What is the unique insight or approach?
6. **Market** — How large is the opportunity? What evidence exists for demand?
7. **Risks** — What could go wrong? What assumptions are untested?

Do not proceed until you have clear answers for at least stage, customer, problem, and solution. The other inputs can be developed during drafting.

### Phase 2: Draft the Press Release

Read the LaTeX template from `${CLAUDE_PLUGIN_ROOT}/assets/prfaq-template.tex`. Read the PR section guide from `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/pr-structure.md`.

Write each section of the press release using the user's discovery answers:

1. **Headline block** — A press-release-style headline (the news in one sentence) followed by one or two sub-headlines (supporting detail, key numbers, scope). Modeled on wire format, not a document cover page. Lead with the news, not the organization name. If the org name is lowercase-stylized, move it to the sub-headline to avoid awkward capitalization (e.g., "Free Plugin Brings X to Y" not "acme-corp Releases Plugin").
2. **Lede paragraph** — Dateline (CITY --- Date), then the entire value proposition in one paragraph: who, what, why, how it differs. The press release is written as if the product has already launched — use a **future date** in the dateline to make this explicit (e.g., 6-12 months out). This signals the document is aspirational, not a current announcement.
3. **Problem paragraph** — The customer's pain in concrete, measurable terms
4. **Solution paragraph(s)** — How the product solves the problem, focusing on customer experience
5. **Customer quote** — A fictional quote from the target customer expressing relief and outcome
6. **Getting started** — The first 3 steps a customer takes, emphasizing low friction
7. **Spokesperson quote** — A fictional internal quote explaining vision and design philosophy. Use the author's real name from the plugin marketplace config (`marketplace.json` owner name), not a made-up name. The spokesperson is a real person at the company speaking about their vision.
8. **Call to action** — Where to go, when available, pricing model

Write the LaTeX content into a `.tex` file in the user's project directory (default: `prfaq.tex` in the project root, or a path the user specifies). Replace all placeholder text in the template with generated content. Uncomment the `\addbibresource` line in the preamble and set it to the `.bib` filename. Set `\prfaqversion{1}{0}` — initial generation is always v1.0.

When writing any factual claim — market sizes, statistics, customer behaviors, competitor capabilities, framework attributions — use `\cite{key}` referencing the corresponding `.bib` entry. If a claim has no source, write `[CITATION NEEDED]` as a visible marker and flag it for the user during review.

When the press release makes a judgment call — a claim about the market, a design choice, a positioning decision — cross-reference the FAQ that explains the reasoning: `(see \faqref{faq:slug})`. This renders as a clickable "FAQ 7" link — the number tells the reader exactly which question to find. The corresponding FAQ should unpack the judgment: why we believe this, what evidence supports it, and what the risk is if we're wrong.

After writing, share each section with the user for review. Ask for corrections before proceeding.

Read `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/common-mistakes.md` and check the draft against known anti-patterns. Flag any issues.

### Phase 3: Draft the FAQ

Read the FAQ section guide from `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/faq-structure.md`. Read the four risks framework from `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/four-risks.md`.

Generate two categories of FAQs:

**External FAQs** (customer-facing):
- What is the product and who is it for?
- How does it differ from alternatives?
- How do I get started?
- Additional questions specific to this product

**Internal FAQs** (business-facing), organized by:
- **Value & Market** — TAM, customer evidence, competitive landscape
- **Technical** — Architecture risks, timeline, dependencies
- **Business** — Revenue model, unit economics, success metrics

Internal FAQs are the evidence-heavy part of the document. Every factual assertion should use `\cite{key}`:
- **TAM FAQ** — cite market research, surveys, financial disclosures for every number
- **Customer evidence FAQ** — cite each source of evidence (interviews, surveys, usage data)
- **Competitive FAQ** — cite competitor documentation or third-party analysis
- **Timeline FAQ** — cite reference class examples for similar projects

If a `.bib` entry doesn't exist for a claim, create one. If no source exists at all, mark `[CITATION NEEDED]`.

Label each FAQ pair that explains a judgment call or provides supporting evidence for a press release claim: `\label{faq:slug}` immediately after `\begin{faqpair}{Question}`. Use descriptive slugs: `faq:customer-evidence`, `faq:tam`, `faq:competitors`, `faq:why-latex`. The press release should already reference these labels via `\faqref{faq:slug}`.

After the FAQs, fill in the four risks assessment (Value, Usability, Feasibility, Viability) based on everything gathered so far.

### Phase 3b: Feature Appendix

After the risk assessment, write the **Feature Appendix** — a scope boundary that categorizes every feature into:

- **Must Do** — Essential for launch. Without these, the product does not solve the core problem. Ask the user: "What are the minimum features needed for this to work?"
- **Should Do** — Meaningfully improve the product but not launch-blocking. Fast follow-up candidates. Ask: "What would make it notably better but isn't strictly required?"
- **Won't Do** — Explicitly excluded. Naming what you won't build prevents scope creep and clarifies the product's identity. Ask: "What are people likely to expect or request that you deliberately won't build, and why?"

Each feature entry uses the `\featureitem{Name}{Rationale}` command inside an `enumerate` environment. Features are numbered continuously (F1, F2, F3...) across all three categories. Add `\label{feat:slug}` after each `\featureitem` to make it referenceable. Use `\featureref{feat:slug}` from other sections (press release, FAQs) to create clickable "Feature 3" links — the same pattern as `\faqref` for FAQ pairs. The Won't Do rationale should explain *why not* — is it out of scope, a distraction, technically infeasible, or a deliberate positioning choice?

Example:
```latex
\begin{enumerate}[nosep,leftmargin=2.5em]
  \featureitem{Discovery workflow}{structured questions that guide the user}\label{feat:discovery}
  \featureitem{PDF compilation}{shareable artifact, not a disposable brainstorm}\label{feat:latex}
\end{enumerate}
```

Append the FAQ, risk assessment, and feature appendix sections to the `.tex` file. Share with the user for review.

### Phase 3c: Peer Review

Invoke the `peer-reviewer` agent to critically evaluate the completed draft. Use the Task tool with `subagent_type: "prfaq:peer-reviewer"`, passing the path to the `.tex` file.

The peer reviewer reads the draft, loads all reference guides (including the Kahneman decision quality framework), checks available evidence in `./research/` and via web search, and returns structured feedback: critical issues, warnings, strengths, and recommendations. The reviewer reads `\prfaqstage{}` from the document and calibrates its evidence expectations accordingly — see the Stage Calibration sections in each reference guide.

**Resolution loop:**

1. Present the review results to the user.
2. For each flag, the user (or you on their behalf) decides: **accept** (revise the section), **reject** (explain why the flag doesn't apply), or **escalate** (it's a product decision the user must make).
3. For accepted issues, revise the `.tex` file and re-run the peer reviewer.
4. Proceed to Phase 4 when the assessment is PASS or when the user is satisfied with ITERATE status.

If the assessment is REJECT with critical issues, do not proceed to compilation until the critical issues are resolved or the user explicitly overrides.

### Phase 4: Compile

Run the compile script to produce the PDF:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/compile_prfaq.sh <path-to-tex-file>
```

If compilation fails, read the LaTeX log, fix the issue, and recompile.

The compile script reports overfull hbox warnings (content extending beyond page margins). If any are reported, fix them before proceeding — these produce visible layout defects in the PDF. Common fixes:
- Long URLs or `\texttt{}` strings: move to a display line with `{\small\texttt{...}}`
- Long paragraphs with unbreakable tokens: restructure the sentence to give LaTeX better line-break opportunities
- Multiple `\texttt{}` commands close together: add a natural-language phrase between them

Recompile until zero overfull hbox warnings remain. Report the output PDF path to the user.

### Phase 5: Review

Evaluate the completed PR/FAQ against these review criteria (from `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/four-risks.md`):

1. Is the target customer clearly defined and specific?
2. Is the problem significant and well-evidenced?
3. Is the solution meaningfully differentiated?
4. Can a customer understand and start using it easily?
5. Can it be built with available technology and resources?
6. Do the unit economics and business model work?
7. Is this the highest-priority use of the team's time?

Present the assessment honestly. Identify the weakest sections and suggest specific improvements. Offer to iterate on any section.

## Output

- **LaTeX file**: `prfaq.tex` (or user-specified path) in the project directory
- **PDF**: Compiled PDF in the same directory as the `.tex` file

## Related Commands

After completing a PR/FAQ, the user can stress-test it with these commands:

- **`/prfaq:review`** — Static peer review. Returns a structured report (PASS/ITERATE/REJECT) with critical issues, warnings, and recommendations. Good for identifying problems.
- **`/prfaq:meeting`** — Interactive review meeting. Four personas (principal engineer, target customer, skeptical executive, builder-visionary) debate the document's hot spots. The user makes explicit tradeoff decisions at each disagreement. Good for forcing decisions. Output is a decisions log with specific revision directives.
- **`/prfaq:meeting-hive`** — Autonomous consensus meeting. Same four personas, but they debate and reach consensus without user moderation. Uses one-way/two-way door framework to weight caution vs. action. Only escalates to the user on persistent splits over irreversible decisions. Requires claude-flow.
- **`/prfaq:feedback`** — Directed iteration. Takes a specific feedback directive (from the user or from a meeting's revision queue), traces cascading effects, and surgically redrafts affected sections.

- **`/prfaq:rate`** — Anonymous satisfaction feedback. Quick 1-5 rating with optional comment to help improve the plugin.

**Typical flow:** `/prfaq` → `/prfaq:review` → `/prfaq:meeting` (or `:meeting-hive`) → `/prfaq:feedback` (repeat until ready to build).

## Additional Resources

Detailed guidance for each phase is in the reference files:

- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/pr-structure.md` — Section-by-section press release guide
- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/faq-structure.md` — FAQ section guide (external + internal)
- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/four-risks.md` — Cagan four risks framework, review criteria, decision outcomes
- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/common-mistakes.md` — Anti-patterns and failure modes
- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/decision-quality.md` — Kahneman decision quality checklist for peer review
- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/meeting-guide.md` — Meeting orchestration: personas, debate synthesis, decision flow
