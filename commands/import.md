---
description: Import an existing document into the PR/FAQ template with research, review, and formatting
argument-hint: "[path/to/document.md or paste text directly]"
---

# Import Document into PR/FAQ

Convert an existing document — any format, any structure — into a complete PR/FAQ in the prfaq LaTeX template. The import preserves the user's ideas but rewrites prose to Working Backwards format. Every template section is populated; gaps get `[TODO: description]` placeholders.

## Reference Guides

Before starting, read these reference guides to calibrate your content extraction and restructuring:

- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/pr-structure.md` — Press release section requirements
- `${CLAUDE_PLUGIN_ROOT}/skills/prfaq/references/faq-structure.md` — FAQ structure and required questions

## Steps

1. **Determine the input.** Three branches based on `$ARGUMENTS`:

   **a) File path** — `$ARGUMENTS` ends in `.md`, `.txt`, or `.pdf` and the file exists: read the file using the Read tool. For PDFs, the Read tool handles them natively.

   **b) Text** — `$ARGUMENTS` is non-empty but not a file path: treat it as the document content directly.

   **c) Empty** — `$ARGUMENTS` is empty: ask the user via AskUserQuestion:
   - **Paste content** — user will paste the document as their next message
   - **Provide a file path** — user will give a path to read
   - **Cancel**

   If the user chooses to paste, wait for their next message and use that as the document content.

2. **Check for existing PR/FAQ.** Use Glob to search for `prfaq.tex` in the project root. If found, ask via AskUserQuestion:
   - **Overwrite** — replace the existing document with the import
   - **Save as new file** — ask the user for a filename (default: `prfaq-imported.tex`)
   - **Cancel**

3. **Extract and map content.** Read the input document and identify content that maps to PR/FAQ sections. You are restructuring, not copying — extract the *ideas* and note where they belong:

   | PR/FAQ Section | Look for in source document |
   |---|---|
   | **Headline** | Title, main announcement, product name + value proposition |
   | **Lede** | Executive summary, overview paragraph, elevator pitch |
   | **Problem** | Pain points, challenges, current state, workarounds |
   | **Solution** | Product description, approach, how it works, key features |
   | **Customer Quote** | Customer persona, user stories, testimonials, use cases |
   | **Getting Started** | Onboarding, setup steps, quick start, first experience |
   | **Spokesperson Quote** | Vision, design philosophy, why we built this |
   | **Call to Action** | Availability, pricing, URL, launch date |
   | **External FAQs** | Customer-facing Q&A, objections, clarifications |
   | **Internal FAQs** | Market size, evidence, risks, timeline, revenue, metrics |
   | **Risk Assessment** | Risks, assumptions, unknowns, dependencies |
   | **Feature Appendix** | Feature lists, roadmap, scope, priorities, non-goals |

   For each section, note one of:
   - **Found** — source has relevant content (include a snippet)
   - **Inferred** — content can be derived from surrounding context
   - **Missing** — no relevant content; will use `[TODO]` placeholder

   Also extract all **factual claims** — numbers, statistics, market sizes, competitor comparisons, timelines — for research in step 6.

   **Handling non-PR/FAQ documents:** Accept any product-related document (pitch decks, product briefs, feature specs, strategy memos, even meeting notes). Extract what maps to the PR/FAQ structure and flag what's missing. The document does not need to resemble a PR/FAQ — you are translating it into one.

4. **Select stage and confirm mapping.** Present the extracted mapping to the user as a summary table showing each section's status (Found / Inferred / Missing) with a content snippet for Found items. Then ask via AskUserQuestion:

   **Stage:** What stage is this product at?
   - **Hypothesis** — early idea, pre-validation
   - **Validated** — post-customer-interviews, evidence gathered
   - **Growth** — product in market, usage data available

   After the user selects stage, ask: "Does this content mapping look correct? Reply with any corrections, or say 'looks good' to proceed."

5. **Populate the template.** Read `${CLAUDE_PLUGIN_ROOT}/assets/prfaq-template.tex`. For each section in the template, replace the placeholder text with:

   - **Found content**: Rewrite the user's content in Working Backwards format. Preserve their ideas, facts, and specifics. Restructure the prose to match the reference guide requirements for that section. Use the customer's language, not engineering jargon.
   - **Inferred content**: Generate the section from context in the source document. Mark inferred claims with `[CITATION NEEDED]`.
   - **Missing content**: Insert a `[TODO]` placeholder that describes what's needed:
     ```latex
     [TODO: Customer quote — name a specific person with a role, describe
     the before/after experience. See pr-structure.md for guidance.]
     ```

   **Template modifications:**
   - Set `\prfaqstage{<user-choice>}` in the preamble
   - Set `\prfaqversion{1}{0}` — import always produces v1.0
   - Uncomment `\addbibresource{<basename>.bib}` and set the filename
   - Set `pdfauthor` and `pdftitle` in `\hypersetup` if the document provides author/title
   - Add `\label{faq:slug}` to key FAQs for cross-referencing
   - Add `\label{feat:slug}` to feature items
   - Add `\cite{key}` for factual claims (use descriptive placeholder keys like `\cite{placeholder-tam}` until research runs)
   - Add `\faqref{faq:slug}` in the press release where judgment calls reference FAQ explanations

   **LaTeX safety:** Escape special characters in user content: `&` → `\&`, `%` → `\%`, `_` → `\_`, `#` → `\#`, `$` → `\$`, `{` → `\{`, `}` → `\}`. Do not escape characters inside LaTeX commands.

6. **Research factual claims.** Collect all factual assertions extracted in step 3 (numbers, market sizes, competitor claims, statistics, timelines). Invoke the researcher agent using the Task tool with `subagent_type: "prfaq:researcher"`. Pass:
   - The list of factual claims to verify
   - The path to the `.tex` file (so the researcher can check for existing `.bib` entries)

   From the researcher's response:
   - Write the `.bib` file with all bibliography entries (same directory, same basename as `.tex`)
   - Replace placeholder `\cite{placeholder-*}` keys in the `.tex` with actual citation keys from the `.bib`
   - For claims the researcher could not verify, keep `[CITATION NEEDED]` markers
   - For claims the researcher contradicted, add a LaTeX comment noting the contradiction:
     ```latex
     % NOTE: Researcher found contradicting evidence for this claim — see research cache
     ```

7. **Write files.** Use the Write tool to save:
   - The `.tex` file (default: `prfaq.tex` in project root, or the path chosen in step 2)
   - The `.bib` file (same directory, same basename)

8. **Compile the PDF.** Run:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/compile_prfaq.sh <path-to-tex-file>
   ```
   If compilation fails, read the LaTeX log, fix the issue (usually special character escaping or malformed environments), and recompile. If overfull hbox warnings are reported, fix them — long `\texttt{}` strings should use `{\small\texttt{...}}` on display lines, and long paragraphs should be restructured. Recompile until zero warnings.

9. **Peer review.** Invoke the peer-reviewer agent using the Task tool with `subagent_type: "prfaq:peer-reviewer"`. Pass the `.tex` file path. Present the review results to the user.

10. **Gap analysis and next steps.** Summarize what was imported and what needs work:

    **Import summary:**
    - Sections populated from source: N/M
    - Sections with `[TODO]` placeholders: list them
    - Factual claims researched: N (supported: X, unsupported: Y, contradicted: Z)
    - `[CITATION NEEDED]` markers remaining: N
    - Peer review verdict: PASS / ITERATE / REJECT

    **Suggested next steps:**
    - Fill `[TODO]` sections — run `/prfaq` in revise mode to interactively fill gaps
    - Address peer review issues — run `/prfaq:feedback` with specific directives
    - Find more evidence — run `/prfaq:research` for remaining `[CITATION NEEDED]` items
    - Stress-test — run `/prfaq:meeting` to debate the weak spots
    - Tighten prose — run `/prfaq:streamline` when the content is solid
