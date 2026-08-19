---
description: Generate an external press release from the PR/FAQ and CHANGELOG for a specific release
argument-hint: "[version, e.g. v2.0]"
allowed-tools: Bash(bash */compile_prfaq.sh *), Read, Write, Glob, Grep
---

# Externalize: PR/FAQ → Press Release

Convert the internal PR/FAQ decision document into a customer-facing press release for a specific release. The PR/FAQ is what the team debates; the press release is what the world reads.

## Steps

1. **Find the inputs.** Read `prfaq.tex` (or the path the user specifies) and `CHANGELOG.md` from the project directory. Both are required — the PR/FAQ provides the narrative and the CHANGELOG provides what actually shipped. If either is missing, tell the user what's needed and stop.

2. **Determine the target version.** Three branches based on `$ARGUMENTS`:

   **a) Version specified** — `$ARGUMENTS` contains a version string (e.g., `v2.0`, `2.0`, `0.9.1`): target that version's CHANGELOG entry. If the version doesn't exist in the CHANGELOG, tell the user and list available versions.

   **b) Empty** — default to the latest version in the CHANGELOG (the topmost `## [X.Y.Z]` entry that is not `[Unreleased]`). If the CHANGELOG has no versioned releases (only `[Unreleased]`), tell the user that externalize requires at least one versioned release and stop.

3. **Detect the release type.** Read the full CHANGELOG to understand the product's release history. The release type determines the tone, structure, and length of the press release:

   | Release type | Condition | Structure |
   |---|---|---|
   | **First release** | Target is the first (or only) version in the CHANGELOG | Full press release: headline, lede, problem, solution, customer quote, getting started, spokesperson quote, CTA, boilerplate |
   | **Major update** | Target has a major version bump from the prior release (e.g., v1.x → v2.0) and prior versions exist | Update announcement: headline focuses on "what's new", lede highlights why this upgrade matters, "What's New" section replaces "Problem", solution focused on new capabilities, CTA includes upgrade path |
   | **Minor/patch** | Target is a minor or patch bump (e.g., v1.0 → v1.1 or v1.0.1) | Short release note: headline, lede summarizing improvements, key changes list, availability, boilerplate |

4. **Extract content.** Read the PR/FAQ and map it to press release sections:

   - **Headline, sub-headlines** — rewrite to announce the specific release, not the aspirational product vision. For updates, lead with what's new.
   - **Lede** — dateline + announcement sentence. **Use today's date** (not the PR/FAQ's future dateline — this is a ship-day press release about a real, shipped product). First release: introduce the product. Update: announce the new version and its headline capability.
   - **Problem** (first release only) — extract from the PR/FAQ's Problem section. Remove internal hedging and risk language.
   - **What's New** (updates only) — synthesize from the target version's CHANGELOG entries. Prioritize Added and Changed sections, but include Fixed entries if substantive. Omit Removed entries unless removal is the headline (e.g., a major simplification). If the CHANGELOG version has no content sections, ask the user to describe what's new. Group by user impact, not by implementation detail.
   - **Solution** — extract from the PR/FAQ's Solution section. Scope to what actually shipped: cross-reference the Feature Appendix's "Must Do" items with the CHANGELOG entries for the target version. Do not include planned or aspirational features.
   - **Customer quote** — extract from the PR/FAQ. Add a LaTeX comment `% TODO: Replace with a real customer testimonial` above the quote. Do not rewrite it — flag it for the user.
   - **Getting started** (first release) / **Availability** (updates) — extract from the PR/FAQ's Getting Started section. For updates, mention the upgrade path.
   - **Spokesperson quote** — extract from the PR/FAQ. Keep it authentic to the spokesperson's voice.
   - **Call to action** — URL, pricing, availability date.
   - **Boilerplate** — one-paragraph company description. Extract from the PR/FAQ's lede or ask the user if not present.

   **Writing rules for external press releases:**
   - No internal jargon, risk hedging, or "we plan to"
   - Every claim must be true today (shipped, not planned)
   - Customer benefits, not technical implementation details
   - Concrete numbers over vague claims ("50% faster" not "significantly faster")
   - Third person throughout (the company announced, not we announced)

5. **Present the plan.** Show the user:
   - Release type detected and why
   - Target version and its key CHANGELOG entries
   - Which PR/FAQ sections will be used
   - Any gaps (e.g., no boilerplate found, customer quote is fictional)

   Ask: "Does this plan look right? Reply with any corrections, or say 'looks good' to proceed."

6. **Generate the press release.** Write `press-release-vX.Y.Z.tex` using the template at `${CLAUDE_PLUGIN_ROOT}/assets/press-release-template.tex` as the structural skeleton. Fill every placeholder with real content extracted and rewritten from the PR/FAQ and CHANGELOG.

   For **major updates**, adapt the template: replace `\prsection{Problem}` with `\prsection{What's New}`, replace `\prsection{Getting Started}` with `\prsection{Availability}`, and focus the solution on new capabilities rather than the full product.

   For **minor/patch releases**, simplify the template: headline, lede, a bulleted list of key improvements under `\prsection{Key Improvements}`, `\prsection{Availability}`, and boilerplate. Omit the customer quote, spokesperson quote, and problem/solution sections.

7. **Compile to PDF.** Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/compile_prfaq.sh press-release-vX.Y.Z.tex` to produce the PDF. Fix any compilation errors or overfull hbox warnings before presenting.

8. **Present and refine.** Show the user the compiled PDF. Remind them to replace the customer quote with a real testimonial if it was flagged. Offer refinement — they can adjust tone, add details, or request a different release type.
