---
name: working-backwards
description: >
  This skill should be used when the user asks to "write a PR/FAQ",
  "working backwards", "product discovery", "evaluate a product idea",
  "press release FAQ", "test product value", or wants to use the
  Amazon Working Backwards process to evaluate whether a product or
  feature is worth building.
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

## Workflow

### Phase 1: Discovery

Before writing anything, gather the inputs that make a PR/FAQ credible. Ask the user these questions (adapt based on what they've already shared):

1. **Customer** — Who is the specific target customer? What is their role, context, and daily reality?
2. **Problem** — What problem does this customer have today? How do they currently cope? What makes existing solutions inadequate?
3. **Solution** — What is the product or feature? How does it work at a high level?
4. **Differentiation** — Why is this better than what exists? What is the unique insight or approach?
5. **Market** — How large is the opportunity? What evidence exists for demand?
6. **Risks** — What could go wrong? What assumptions are untested?

Do not proceed until you have clear answers for at least customer, problem, and solution. The other inputs can be developed during drafting.

### Phase 2: Draft the Press Release

Read the LaTeX template from `${CLAUDE_PLUGIN_ROOT}/assets/prfaq-template.tex`. Read the PR section guide from `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/pr-structure.md`.

Write each section of the press release using the user's discovery answers:

1. **Title block** — Product name, subtitle (value proposition), date, author, team
2. **Summary paragraph** — The entire value proposition in one paragraph: who, what, why, how it differs
3. **Problem paragraph** — The customer's pain in concrete, measurable terms
4. **Solution paragraph(s)** — How the product solves the problem, focusing on customer experience
5. **Customer quote** — A fictional quote from the target customer expressing relief and outcome
6. **Getting started** — The first 3 steps a customer takes, emphasizing low friction
7. **Spokesperson quote** — A fictional internal quote explaining vision and design philosophy
8. **Call to action** — Where to go, when available, pricing model

Write the LaTeX content into a `.tex` file in the user's project directory (default: `prfaq.tex` in the project root, or a path the user specifies). Replace all placeholder text in the template with generated content.

After writing, share each section with the user for review. Ask for corrections before proceeding.

Read `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/common-mistakes.md` and check the draft against known anti-patterns. Flag any issues.

### Phase 3: Draft the FAQ

Read the FAQ section guide from `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/faq-structure.md`. Read the four risks framework from `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/four-risks.md`.

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

After the FAQs, fill in the four risks assessment (Value, Usability, Feasibility, Viability) based on everything gathered so far.

Append the FAQ and risk assessment sections to the `.tex` file. Share with the user for review.

### Phase 4: Compile

Run the compile script to produce the PDF:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/compile_prfaq.sh <path-to-tex-file>
```

If compilation fails, read the LaTeX log, fix the issue, and recompile. Report the output PDF path to the user.

### Phase 5: Review

Evaluate the completed PR/FAQ against these review criteria (from `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/four-risks.md`):

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

## Additional Resources

Detailed guidance for each phase is in the reference files:

- `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/pr-structure.md` — Section-by-section press release guide
- `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/faq-structure.md` — FAQ section guide (external + internal)
- `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/four-risks.md` — Cagan four risks framework, review criteria, decision outcomes
- `${CLAUDE_PLUGIN_ROOT}/skills/working-backwards/references/common-mistakes.md` — Anti-patterns and failure modes
