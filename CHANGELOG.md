# Changelog

All notable changes to the prfaq plugin are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.7.0] - 2026-02-15

### Added
- Stage awareness via `\prfaqstage{}` command (hypothesis | validated | growth)
  - LaTeX template defines `\prfaqstage{}` with `fancyhdr` header badge showing current stage
  - Phase 1 discovery asks stage as the first question, sets it in the `.tex` preamble
  - Peer reviewer, meeting personas, and all reference guides calibrate evidence expectations by stage
  - Stage Calibration sections added to all 9 reference guides
  - Defaults to `hypothesis` for backwards compatibility — existing documents work unchanged
- Document version tracking via `\prfaqversion{major}{minor}` command
  - LaTeX template renders version alongside stage in the page header (`Stage: hypothesis | v1.0`)
  - `/prfaq` generation sets initial version to v1.0
  - `/prfaq:feedback` auto-increments version after each application using judgment: minor for editorial changes, major for structural shifts (persona change, problem reframe, business model)
  - Revise mode detects and preserves existing version; adds v1.0 if absent
- `/prfaq:feedback` batch mode — auto-discovers `meeting-summary-*.md` files and applies all revision queue directives sequentially
  - Empty arguments: auto-discovers most recent meeting summary, offers to apply all directives
  - `.md` file path argument: reads that specific file's revision queue
  - Text argument: existing single-feedback behavior (unchanged)
  - One PDF compile and one peer review at the end, not per-directive
- `/prfaq:rate` command — anonymous satisfaction feedback (1-5 rating)
  - Reads document version and stage from `.tex` file for correlation
  - Posts to Supabase endpoint with insert-only RLS policy
  - Per-project anonymous ID persisted in `.claude/prfaq.local.md` (no cross-project tracking)
  - Optional free-text comment

## [0.6.0] - 2026-02-15

### Added
- `/prfaq:meeting` command — simulated Amazon-style PR/FAQ review meeting with four agentic personas
  - **Wei** (Principal Engineer) — feasibility risk, technical honesty, "What's the denominator?"
  - **Priya** (Target Customer) — value risk, customer reality, "Which of those developers am I?"
  - **Alex** (Skeptical Executive) — strategic fit, devil's advocate, "Compared to what?"
  - **Dana** (Builder-Visionary) — ambition risk, cost of inaction, "You're thinking too small."
- Persona distinctness via three techniques: structural response constraints, information asymmetry (different reference guides per persona), and voice direction (verbal tics, emotional register)
- Meeting flow: pre-meeting scan → agenda selection → parallel persona debate → user decision → cascade consequences → decisions log
- Decisions log output feeds directly into `/prfaq:feedback` for automated revision
- `meeting-guide.md` reference guide for meeting orchestration
- Amazon Leadership Principle weighting across all personas (caution vs. ambition tension)

### Changed
- SKILL.md documents the review → meeting → feedback pipeline as related commands

## [0.5.0] - 2026-02-15

### Added
- `/prfaq:feedback` command and agent for directed iteration from user feedback
  - Interprets directional feedback (e.g., "wrong persona", "TAM too large")
  - Traces cascading effects across all affected sections via dependency graph
  - Surgically redrafts affected content, recompiles PDF, auto-runs peer review
- Numbered FAQ questions (Q1, Q2, etc.) with `\faqref{faq:slug}` cross-reference command
- Numbered Feature Appendix entries (F1, F2, etc.) with `\featureitem{Name}{Rationale}` and `\featureref{feat:slug}` cross-reference command
- Press-release-style headline block (headline + sub-headlines) replacing cover-page title format
- `\newpage` before major sections: External FAQs, Internal FAQs, Risk Assessment, Feature Appendix, References
- Widow/orphan prevention: `nowidow` package and `needspace` package for FAQ pairs and section headings
- Three new reference guides for peer review:
  - `unit-economics.md` — viability risk lens (CAC, LTV, payback period, margins)
  - `principal-engineer.md` — feasibility risk lens (architecture trade-offs, irreversible decisions)
  - `ux-bar-raiser.md` — usability risk lens (customer journey, cognitive load, error recovery)
- LaTeX environment documentation in `faq-structure.md` reference guide

### Changed
- Risk assessment uses `tabularx` table format instead of `mdframed` + `\riskitem` blocks
- FAQ cross-references now use `\faqref{faq:slug}` (renders as clickable "FAQ 7") instead of `\pageref` (page numbers)
- Headline block follows wire format (headline announcing the news, sub-headlines with supporting detail) instead of centered product-name/subtitle/date
- Press release described as "short document (typically one to two pages)" instead of "one-page document"
- Peer reviewer agent loads all 8 reference guides (was 5)
- Installer checks for `needspace` and `nowidow` LaTeX packages

### Removed
- `\riskitem` command (replaced by `tabularx` table rows)
- `\prsection{Summary}` (lede paragraph now follows the headline block directly)
- `\pageref`-based cross-references (replaced by `\faqref`)
- Horizontal rules below headline block and section titles

### Fixed
- Peer review findings in dogfood PR/FAQ: corrected Stack Overflow stat, Anthropic revenue figure, HFS citation, customer quote specificity, spokesperson attribution, pre-mortem scenario
- Viability risk upgraded from Low to Medium (maintainer time is the binding constraint)
- FAQ question titles no longer strand at page bottom (needspace + nopagebreak)
- Paragraph indentation within faqpair answers suppressed

## [0.4.0] - 2026-02-15

First tagged release.

### Added
- Complete PR/FAQ generation workflow (Phases 0-5)
  - Phase 0: Research discovery (local `./research/` scan + researcher agent)
  - Phase 1: Interactive discovery questions
  - Phase 2: Press release drafting with LaTeX template
  - Phase 3: FAQ generation, risk assessment, feature appendix
  - Phase 3c: Automatic peer review
  - Phase 4: PDF compilation (pdflatex + biber)
  - Phase 5: Final review against four-risks criteria
- Revise mode for iterating on existing documents
- `/prfaq:review` command with peer-reviewer agent (Kahneman decision quality framework)
- `/prfaq:research` command with researcher agent (local files, web, quarry-mcp)
- LaTeX template with custom environments: `faqpair`, `customerquote`, `spokespersonquote`
- Biblatex citation system with `\cite{}` and `.bib` file generation
- Judgment-to-FAQ cross-referencing system
- One-line installer script with LaTeX dependency checking
- Five reference guides: `pr-structure.md`, `faq-structure.md`, `four-risks.md`, `common-mistakes.md`, `decision-quality.md`
- Quarry-MCP integration for semantic search across indexed documents
- Dogfood PR/FAQ document (`prfaq.tex`) demonstrating the plugin on itself

### Fixed
- Plugin cache not clearing on reinstall (stale cache hid new agents)
- FAQ paragraph indentation inconsistency in `faqpair` environment

[Unreleased]: https://github.com/punt-labs/prfaq/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/punt-labs/prfaq/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/punt-labs/prfaq/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/punt-labs/prfaq/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/punt-labs/prfaq/releases/tag/v0.4.0
