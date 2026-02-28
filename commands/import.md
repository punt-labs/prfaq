---
description: Import an existing document and launch the full /prfaq workflow with extracted content
argument-hint: "[path/to/document.md or paste text directly]"
allowed-tools: Bash(bash */compile_prfaq.sh *), Read, Write, Edit, Glob, Grep, WebSearch, WebFetch
---

# Import Document into PR/FAQ

Convert an existing document — any format, any structure — into a complete PR/FAQ. The import parses the source document, extracts ideas, maps them to PR/FAQ sections, and then launches the full `/prfaq` generation workflow with that content as a head start. Every section gets generated — nothing is left as a placeholder.

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

   Remember the chosen output path for step 5.

3. **Extract and map content.** Read the input document and identify content that maps to the `/prfaq` discovery questions:

   | Discovery Input | Look for in source document |
   |---|---|
   | **Stage** | Product maturity indicators — whether users exist, launch status, evidence level (hypothesis / validated / growth) |
   | **Customer** | Target user, persona, role, audience, market segment |
   | **Problem** | Pain points, challenges, current state, workarounds |
   | **Solution** | Product description, approach, how it works, key features |
   | **Differentiation** | Competitive advantage, unique insight, why this is better |
   | **Market** | TAM, market size, demand signals, growth trends |
   | **Risks** | Assumptions, unknowns, dependencies, what could go wrong |

   Also extract any content that maps to specific PR/FAQ sections beyond the discovery questions:
   - Headlines, elevator pitches, value propositions → press release framing
   - Customer quotes, testimonials, user stories → customer quote section
   - Onboarding flows, getting started steps → getting started section
   - Vision statements, design philosophy → spokesperson quote
   - Feature lists, roadmaps, scope → feature appendix
   - Q&A, objections, clarifications → FAQ pairs
   - Risk assessments, assumptions → risk assessment table
   - Factual claims with numbers → research targets

   **Handling non-PR/FAQ documents:** Accept any product-related document — pitch decks, product briefs, feature specs, strategy memos, meeting notes. Extract what's there; the generation workflow will fill what's missing.

4. **Present the extraction and confirm.** Show the user a summary of what was extracted, organized by discovery input. For each input, show:
   - **Found** — extracted content with a key snippet
   - **Gap** — not covered in source; the generation workflow will ask about this

   Ask: "Does this extraction look correct? Reply with any corrections, or say 'looks good' to proceed."

5. **Launch the `/prfaq` generation workflow.** Proceed to execute the skill workflow defined in `skills/prfaq/SKILL.md`, starting from Phase 0. Skip revise-mode detection — this is a fresh generation from imported content, not a revision of any existing document. If step 2 chose a non-default output path, use that path for the `.tex` file instead of `prfaq.tex`. Carry the extracted content forward as pre-populated context:

   - **Phase 0 (Research Discovery)** — runs normally; the source document's factual claims become additional research targets
   - **Phase 1 (Discovery)** — for inputs marked **Found**, present the extracted content as the proposed answer and ask the user to confirm or refine. For inputs marked **Gap**, ask the discovery question normally. This replaces the blank-slate conversation with a guided confirmation.
   - **Phases 2–5** — run exactly as defined in `SKILL.md`. The extracted content (headlines, quotes, features, FAQs, risk assessments) feeds into the appropriate phases as starting material to be rewritten in Working Backwards format.

   The source document accelerates the conversation — it does not bypass it. The user still confirms every major section and the generation produces a complete PR/FAQ with no gaps.
