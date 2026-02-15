# Changelog

All notable changes to the prfaq plugin are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `/prfaq:feedback` command and agent for directed iteration from user feedback
  - Interprets directional feedback (e.g., "wrong persona", "TAM too large")
  - Traces cascading effects across all affected sections via dependency graph
  - Surgically redrafts affected content, recompiles PDF, auto-runs peer review
- Numbered FAQ questions (Q1, Q2, etc.) with `\faqref{faq:slug}` cross-reference command
- Press-release-style headline block (headline + sub-headlines) replacing cover-page title format
- Three new reference guides for peer review:
  - `unit-economics.md` — viability risk lens (CAC, LTV, payback period, margins)
  - `principal-engineer.md` — feasibility risk lens (architecture trade-offs, irreversible decisions)
  - `ux-bar-raiser.md` — usability risk lens (customer journey, cognitive load, error recovery)

### Changed
- Risk assessment uses `tabularx` table format instead of `mdframed` + `\riskitem` blocks
- FAQ cross-references now use `\faqref{faq:slug}` (renders as clickable "FAQ 7") instead of `\pageref` (page numbers)
- Headline block follows wire format (headline announcing the news, sub-headlines with supporting detail) instead of centered product-name/subtitle/date
- Peer reviewer agent loads all 8 reference guides (was 5)

### Removed
- `\riskitem` command (replaced by `tabularx` table rows)
- `\prsection{Summary}` (lede paragraph now follows the headline block directly)
- `\pageref`-based cross-references (replaced by `\faqref`)

### Fixed
- Peer review findings in dogfood PR/FAQ: corrected Stack Overflow stat, Anthropic revenue figure, HFS citation, customer quote specificity, spokesperson attribution, pre-mortem scenario
- Viability risk upgraded from Low to Medium (maintainer time is the binding constraint)

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

[Unreleased]: https://github.com/punt-labs/prfaq/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/punt-labs/prfaq/releases/tag/v0.4.0
