# Changelog

All notable changes to the prfaq plugin are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **A deterministic prose linter now blocks LLM-tell writing at write time, not just at review time.** A PostToolUse hook scans every `Write`/`Edit` to a prfaq-family document: a `.tex` file containing `\prfaqversion` or `\prfaqstage`, or a `meetings/meeting-summary-*.md` / `meetings/meeting-hive-summary-*.md` file. It blocks the write on a banned-tier hit, including em dashes, negative-parallelism constructions (both the pronoun-led and full-noun-phrase-subject forms), and a first-cut pattern for sentences that explain the document's own conventions to the reader instead of stating product content. The scanner (`plugin/scripts/prose_lint.py`, stdlib Python, no new dependency) is LaTeX-aware: it masks `%` comments, math mode, and identifier-only commands (`\cite{}`, `\label{}`, `\faqref{}`), and strips text-formatting command wrappers (`\texttt{}`, `\textit{}`) while keeping the inner text in scope, so quoted and emphasized text gets the same scrutiny as everything else. The hook stays narrow by design: it never touches an unrelated file in an unrelated project, even in a session where prfaq is active. `plugin/banlist.conf` is the single source of truth for every term and pattern.
- **Every writing agent and command now loads a generative writing guide before it drafts a single sentence.** `plugin/skills/prfaq/references/plain-style.md` covers the same rules the linter enforces, held to a stricter bar: zero occurrences at write time, not a density threshold. It is wired into all four meeting personas, the peer-reviewer, feedback, streamliner, and researcher agents, the initial drafting skill, and the three commands that produce live debate dialogue and spoken narration (`/prfaq:meeting`, `/prfaq:meeting-hive`, `/prfaq:meeting-listen`). Narration is never written to a file, so the hook cannot reach it there, and this guide is its only defense.
- `make check` gained a `test-prose` target (95 tests covering the scanner, the LaTeX masking, the hook's scope guard, and the banned patterns) and a `lint-prose` target, informational, that runs the scanner against `prfaq.tex` and the reference guides for repo-local dogfooding.

## [1.8.0] - 2026-08-29

### Added
- **`/prfaq:meeting` and `/prfaq:meeting-hive` open and close with an exec assessment.** A standalone Alex (Skeptical Executive) read frames the stakes before the agenda and delivers a closing verdict — plus a concrete next-step/reconvene proposal — after every hot spot is decided, matching typical review-meeting structure instead of jumping straight into itemized debate and stopping cold after the last item. Both reads are organized around the three questions product development lives or dies on: is this a problem worth solving, do we have a strong and differentiated solution, and should we build this now given competing priorities. Persisted in the summary's new `## Overall Assessment` section. `/prfaq:meeting-listen` voices both, and its closing now recaps concrete follow-up items from the revision queue and any deferred decisions, plus the agreement to reconvene when the closing read names one (grounded in the actual proposal — never a generic "let's touch base").

### Changed
- **`/prfaq:meeting` and `/prfaq:meeting-hive`'s hot-spot scan now defaults to product substance, not prose quality.** The pre-meeting scan's criteria were entirely a documentation-quality checklist (citation gaps, vague words, thin FAQs, hedging mismatches) — running a real meeting against them produced an agenda of copy-editing issues with no bearing on competition, customers, the business model, or scope. The four risk-lens questions (feasibility, value/customer reality, strategic fit/viability, ambition) now come first, with a guardrail requiring at least half the agenda to be substance rather than documentation issues.
- **Meeting debate narratives and `/prfaq:meeting-listen` dialogue must ground every line in a document specific** (a quoted phrase, a real number, a named competitor or customer segment) instead of abstract metaphor standing in for the reasoning, and must never have a persona reference the meeting's own sequence ("third hot spot in a row," "unlike the previous item"). Cross-hot-spot patterns belong in the summary's Notes section, not spoken in a persona's voice.

### Fixed
- **`/prfaq:meeting-listen` called a retired vox tool.** `mcp__plugin_vox_mic__who` no longer exists; voice-roster detection now uses the no-arg `mcp__plugin_vox_mic__voice` call, which returns the same shape (`all` renamed to `available`).

## [1.7.3] - 2026-08-20

### Changed

- **The shippable plugin surface moved to `plugin/`, so a marketplace install fetches only the plugin.** `.claude-plugin/`, `commands/`, `agents/`, `skills/`, `assets/`, and the five runtime scripts now live under a single `plugin/` directory, which lets the marketplace entry use Claude Code's `git-subdir` source (`"source": "git-subdir"`, `"path": "plugin"`) — a blobless partial clone plus `sparse-checkout set --cone plugin`. An install stops fetching whole directories it never reads: `docs/` and `research/` (3.0 MB each, mostly PDFs), `meetings/`, `tests/`, `.github/`, `.beads/`, this repo's release scripts, and its `.claude/`, `.punt-labs/`, `.lux/`, and `.vox/` tooling state. Measured against this branch on GitHub: 65 files / 1.3 MB of working tree (2.2 MB including `.git`) versus 93 files / 7.3 MB (11 MB including `.git`) for an equivalent shallow full clone — a 5.6x working-tree reduction. `assets/` and `scripts/` had to move with the four conventional directories: every one of the 19 distinct `${CLAUDE_PLUGIN_ROOT}/...` paths in the commands, agents, and skill resolves under the plugin root, and five of them name a template or a script, so a cone checkout of `plugin/` alone would have left every compile, export, and permission step pointing at a path a consumer does not have. The two release scripts stay at the repo root — they run `git commit` against this repo and have no business in a plugin cache. Note that cone mode always materializes the files sitting in the *repo root*, so roughly 550 KB of root-level documents still travel with an install — about 40% of the total, and none of it read by the plugin: `prfaq.pdf` (215 KB), `press-release-v1.0.0.pdf` (115 KB), `prfaq.tex` (76 KB), `prfaq.docx` (37 KB), plus README, CHANGELOG, and CLAUDE.md. `plugin/` itself is 644 KB, of which 206 KB is the two committed template PDFs. Shrinking that remainder means moving root documents into a subdirectory, which this change does not attempt. Nothing user-visible changes and existing installs are unaffected until the marketplace entry is repointed; `${CLAUDE_PLUGIN_ROOT}/...` spellings stay correct because the whole surface moved together, and the three scripts that resolve siblings do it from `$0`.

### Fixed

- **Two shipped LaTeX files were never compile-gated.** `make prfaq` compiled `prfaq.tex` and `assets/prfaq-template.tex` only, so `press-release-template.tex` — the skeleton `/prfaq:externalize` builds every press release from — could have broken without any gate noticing, as could `press-release-v1.0.0.tex` and `docs/prfaq-overview.tex`. All five now compile, and the artifact globs derive from one `TEX_DIRS` list rather than a hand-maintained copy per directory.
- **`scripts/restore-dev-plugin.sh` could abort with a bare git error.** Restoring from a ref that predates the `plugin/` move leaves both of its pathspecs matching nothing, which git reports as `did not match any file(s) known to git` with no hint at the cause. It now names the ref, says why it is too old, and points at the manual path.

## [1.7.2] - 2026-08-19

### Fixed

- Installing the plugin no longer requires a GitHub SSH key. The repo carried a `.punt-labs/ethos` git submodule pointing at `git@github.com:punt-labs/team.git`, and Claude Code clones plugins with submodules — so the install aborted with `Failed to clone '.punt-labs/ethos' a second time, aborting` for anyone without a key configured. The submodule is removed; agents resolve identities from the global `~/.punt-labs/ethos/` at runtime.
- The permission test suite passes on Linux. Its stub `claude` printed the marketplace-list bullet with `\xe2\x9d\xaf`, and POSIX `printf` defines `\NNN` rather than `\xNN`, so under `dash` the escape survived verbatim and its alphanumerics defeated the installer's name-field regex — two assertions failed on every Linux checkout.

### Removed

- 1.1 MB of internal org-identity data (245 files: identities, roles, personalities, writing styles) is no longer cloned onto a user's disk at install time. None of it was prfaq-specific.

## [1.7.1] - 2026-08-13

### Fixed

- Installer no longer aborts when the global `~/.claude/settings.json` has a key of the right name but the wrong type (`"allow": "WebSearch"` instead of a list). It died inside `jq` under `set -eu`, after the plugin had installed and before the toolchain checks — a raw stack trace instead of a message, and no closing output. It now warns, leaves the file untouched, and finishes.
- `/prfaq:permissions` names the offending key instead of leaking a `jq` stack trace when `permissions`, `permissions.allow`, or `env` has the wrong type. A typo is reported, never silently read as an empty list.
- `/prfaq:permissions` no longer reports "all rules already present" when `jq` produced no count. `set -e` does not see failures inside `$(...)` and `sh` has no `pipefail`, so an empty result read as zero — a silent no-op reported as success.
- Installer warns when it cannot refresh the marketplace instead of discarding the error, which let an install resolve against a stale cached ref and still report success.
- Installer reads the marketplace name field rather than grepping the whole listing, which also matched an unrelated marketplace whose source repo contained `punt-labs` — registration was then skipped and the install failed later with a resolver error. The listing format is not a stable contract, so a missed match is recoverable too: if registering fails because the marketplace is already there, the installer accepts it instead of giving up.

### Changed

- `/prfaq:permissions` no longer tells users to restart. Claude Code watches settings files and applies them without one.

## [1.7.0] - 2026-08-13

### Added

- `/prfaq:permissions` — grant prfaq's permission rules in the current project, check what is in place, or revoke them
  - Writes the project's own `.claude/settings.json` only; refuses to write the global settings file
  - Idempotent — a second run adds nothing and leaves the file byte-identical
  - Also sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, which `/prfaq:meeting-hive` requires
  - Backed by `scripts/prfaq_permissions.sh` (`--add`, `--check`, `--remove`), which requires `jq`

### Changed

- Installer no longer writes permission rules to the global `~/.claude/settings.json`. Permissions are project-scoped and opt-in via `/prfaq:permissions`. Global rules apply in every project the user opens, including projects unrelated to prfaq.

### Fixed

- Installer now removes the 24 permission rules that versions 1.5.0 through 1.6.1 wrote to `~/.claude/settings.json`, backing the file up first and printing every rule it removed. Eight of those rules used the `Write(path)` form, which Claude Code no longer matches — it prints a warning per unmatched rule at every session start, in every project. Path rules now use `Edit(path)`, which covers the Write, Edit, and NotebookEdit tools.
- README claimed `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` shipped with the plugin and was enabled on install. It was set only in the prfaq repo's own settings file, so `/prfaq:meeting-hive` did not work for anyone else. `/prfaq:permissions` now sets it.

## [1.6.1] - 2026-03-20

### Added

- `scripts/release-plugin.sh` and `scripts/restore-dev-plugin.sh` — automate the dev/prod name swap for releases, preventing the `-dev` name from leaking into tagged commits

### Fixed

- v1.3.0, v1.5.0, v1.5.2, and v1.6.0 release tags shipped with `prfaq-dev` in `plugin.json` instead of `prfaq` — the name swap step was manual and forgotten 4 of 10 times

## [1.6.0] - 2026-03-05

### Changed

- `/prfaq:meeting-listen` now batches all dialogue into a single `unmute` call per hot spot using the `segments` parameter — adapts for vox's non-blocking unmute (v1.1.1+)
  - Each segment carries its own `voice` and `vibe_tags` for per-persona emotional variation
  - Narrator segment opens each hot spot with a scene-setter: names the hot spot, document section, core tension, and decision outcome before the debate begins

## [1.5.2] - 2026-03-04

### Fixed

- `/prfaq:meeting-listen` glob patterns now search from the user's working directory instead of using `./` prefix, with recursive `**/meetings/` fallback — fixes meeting discovery when running from sibling project directories

## [1.5.1] - 2026-03-04

### Fixed

- Update `meeting-listen` tool references for vox mic API rename (`mcp__plugin_tts_vox__speak` → `mcp__plugin_vox_mic__unmute`, `list_voices` → `who`)
- Update README references from `punt-tts` to `punt-vox` with correct GitHub URLs

## [1.5.0] - 2026-03-04

### Added

- `/prfaq:export` command — export PR/FAQ as Word document (.docx) via pandoc, no TeX installation required
  - Pre-processes custom LaTeX environments (faqpair, featureitem, customerquote, spokespersonquote, prsection) into standard LaTeX that pandoc understands
  - Two-pass counter resolution: FAQ and feature numbering with cross-reference substitution (`\faqref`, `\featureref`)
  - Styled `reference.docx` template: Palatino serif, SectionBlue headings, ~80% of LaTeX visual quality
  - Inline cleanup: strips `\textcolor`, `\needspace`, `\discretionary`, and other layout-only commands
  - Risk table converted from `tabularx` to paragraph layout for readable Word output
  - Centered title and subtitle with styled fonts (18pt bold SectionBlue / 12pt AccentGray)
  - Header with document title, footer with stage and version
  - Code/verbatim style: 8pt SectionBlue bold (compact relative to 11pt body)
  - Page breaks before Risk Assessment and Feature Appendix sections
  - Portable bash implementation (no gawk, no associative arrays — works on macOS and Linux)
- Installer now checks for pandoc alongside TeX distribution and adds export script permission rules
- Peer reviewer now flags "False Precision in Timeline Estimates" — detailed hour breakdowns and calendar targets at hypothesis stage are flagged as the 7th anti-pattern
- Updated timeline FAQ guidance (question 7) to warn against false precision at early stages

## [1.4.0] - 2026-02-28

### Added
- `/prfaq:meeting-listen` command — post-production voiced playback of completed meeting summaries
  - Four personas (Wei, Priya, Alex, Dana) speak in distinct voices via the TTS plugin (`punt-tts`)
  - Multi-provider voice support: ElevenLabs (custom community voices + expressive tags), OpenAI, and fallback providers
  - ElevenLabs custom voice validation with built-in fallback voices when community voices are not in user's library
  - Graceful text-only degradation when TTS plugin is unavailable
  - Supports both hive and interactive meeting summary formats
  - Decision normalization for compound values (`RESEARCH + REVISE`, `**KEEP AS-IS**`)
  - Speaker labels always printed in transcript; spoken audio omits labels for natural dialogue
- Voice profiles added to all four meeting persona agents
  - Per-provider voice fields: `voice_elevenlabs`, `voice_openai`, `voice_fallback`, `voice_vibe`
  - Wei: yu/echo, Priya: nila/coral, Alex: bill/onyx, Dana: river/fable
- Installer injects plugin permission rules into `~/.claude/settings.json`
  - 20 rules covering Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, and Agent tool patterns
  - Order-preserving idempotent merge via `jq` — existing rules are never reordered or duplicated
  - Validates existing JSON before modification; backs up and recreates on invalid files
  - Falls back to printing rules manually when `jq` is unavailable
- `allowed-tools` frontmatter on all 12 command and skill files declaring the tools each command actually uses

## [1.3.0] - 2026-02-27

### Added
- `/prfaq:badge` command — generate a shields.io badge showing the document's Working Backwards stage
  - Stage-colored: hypothesis (grey), validated (blue), growth (green)
  - Links to compiled PDF in the repo
  - Optionally embeds in README.md alongside existing badges

## [1.2.0] - 2026-02-22

### Changed
- `/prfaq:meeting-hive` migrated from claude-flow hive-mind to Claude Code Agent Teams
  - Personas run as Agent Teams teammates with isolated context windows and inter-agent messaging
  - Shared task list tracks hot spot progress during autonomous runs
  - Debate logic unchanged — only the orchestration substrate changed
  - Prerequisite: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` shipped in `.claude/settings.json` (replaces `npm install -g claude-flow`)

### Removed
- `claude-flow` npm package dependency — no longer required
- claude-flow MCP server registration from `.mcp.json`

## [1.1.0] - 2026-02-17

### Changed
- `/prfaq:vote` Gate 1 now decomposes evidence into three layers: problem evidence, solution evidence, and willingness-to-pay evidence — prevents conflation of "the problem exists" with "our solution resonates"
- `/prfaq:vote` adds a free evidence pre-check (step 5): identifies near-zero-cost evidence the team could gather before committing investment
- `/prfaq:vote` Gate 3 adds a timing counterfactual: "what specifically changes if we wait 6 months?"
- `/prfaq:vote` Gate 3 adds investment proportionality test: compares stated investment ask to minimum viable test cost, flags ratios exceeding 5× with explicit justification requirement
- `/prfaq:vote` Gate 3 adds cost breakdown assessment: distinguishes validation costs from team operating costs when the document bundles them

## [1.0.0] - 2026-02-16

### Added
- `/prfaq:vote` command — go/no-go decision framework for PR/FAQ documents
  - Auto-saves verdict to `./meetings/vote-YYYY-MM-DD.md` alongside meeting summaries
  - Three decision gates: customer problem worth solving (value + viability), differentiated solution (usability + feasibility), should we do this now (opportunity cost)
  - Binary verdicts (GO / NO-GO) — no conditional escape hatch
  - Gate 1 is a hard prerequisite: NO-GO on customer problem = overall NO-GO
  - Multi-document portfolio comparison: rank projects by evidence strength relative to investment
  - Single-document mode flags missing opportunity cost FAQ and prompts team to add one
  - Reads prior meeting summaries for decision trail context
  - Stage-calibrated evidence expectations (hypothesis accepts inference, growth demands data)
- `/prfaq:externalize` command — generate a customer-facing press release from the PR/FAQ and CHANGELOG
  - Detects release type: first release (full press release), major update (what's new focus), minor/patch (short release note)
  - Scopes content to what actually shipped (CHANGELOG entries + Feature Appendix shipped items)
  - Customer quotes flagged for replacement with real testimonials
  - Version-stamped output: `press-release-vX.Y.Z.tex` / `.pdf` (full semver)
  - Standalone press release LaTeX template (`assets/press-release-template.tex`) with same visual styling as the PR/FAQ

### Changed
- `/prfaq:rate` renamed to `/prfaq:feedback-to-us` — eliminates ambiguity with `/prfaq:vote`
- Meeting summaries and vote output now live in `./meetings/` subdirectory

## [0.9.1] - 2026-02-16

### Added
- Quick Start section in README — install, add research, launch, generate
- Meeting outputs now write to `./meetings/` subdirectory instead of project root
  - Auto-migrates existing root-level `meeting-summary-*.md` and `meeting-hive-summary-*.md` files on first run
  - `/prfaq:feedback` auto-discover searches `./meetings/` first, falls back to project root

### Fixed
- Template version starts at v0.0 so initial generation correctly sets v1.0 (was v1.0 → v2.0 on first draft)
- Researcher agent appends `research/` to project `.gitignore` on first cache write

## [0.9.0] - 2026-02-15

### Added
- `/prfaq:streamline` command — scalpel editor for late-stage document tightening
  - Five-pass editing: redundancy across sections, weasel words, inflated phrases, throat-clearing, sentence length
  - Targets 10–20% word count reduction without touching evidence, citations, customer quotes, risk assessments, or structural elements
  - New `streamliner` agent with `precise-writing.md` reference guide (adapted from Vervago Precision Q+A and Amazon "Write Like an Amazonian")
- Researcher agent caches findings to `./research/research-YYYY-MM-DD-TOPIC.md`
  - Future runs reuse cached results instead of re-searching the web
  - Deduplication via topic/verdict matching in prior research files
  - Only persists when new web searches were performed

### Fixed
- Overfull hbox in template Problem section (`CURRENT WORKAROUND` placeholder too long for line — shortened to `WORKAROUND`)
- Compile script now detects and reports overfull/underfull hbox warnings
- Three factual claims in dogfood PR/FAQ corrected per researcher findings:
  - Replit "75% never write code" → CEO pivot statement (verifiable)
  - Opus "1.7× more than Sonnet" → 5× at list pricing (actual published ratio)
  - "2–5M Claude Code users" → labeled as rough revenue/ARPU inference with uncertainty caveat

## [0.8.1] - 2026-02-15

### Added
- Installer prompts for name, email, and organization on every run (not just first install)
  - Reads from `/dev/tty` so prompts work in `curl | bash` piped installs
  - Previous values from `marketplace.json` used as defaults on re-run
  - Organization stored in marketplace owner and plugin author objects

### Fixed
- Installer aborted before Registration when run inside Claude Code (`claude mcp add` failed unguarded under `set -e`)
- README Prerequisites understated TeX dependency ("you can install TeX later" → clarified PDF is the core output)

## [0.8.0] - 2026-02-15

### Added
- `/prfaq:meeting-hive` command — autonomous consensus meeting via claude-flow hive-mind
  - Same four personas (Wei, Priya, Alex, Dana) debate and reach consensus without user moderation
  - One-way/two-way door framework weights caution vs. action: irreversible decisions require stronger evidence, reversible decisions bias toward action
  - Two-round debate: independent evaluation → rebuttal (only for splits)
  - Only escalates to user on persistent splits over one-way door decisions
  - Arguments win or lose (Amazon LP: Disagree and Commit) — no compromise blending
  - Requires claude-flow (installed and registered as MCP server by the installer)
- claude-flow MCP server registration in `.mcp.json`
- Hive mode section in `meeting-guide.md` reference guide
- Comprehensive README documenting all seven commands, seven agents, nine reference guides, document features (stage awareness, version tracking, cross-references, four risks), and architecture

### Changed
- claude-flow is a hard requirement for `/prfaq:meeting-hive` (no fallback path)
- Installer guards `npm install -g claude-flow` against aborting the script on failure
- SKILL.md command syntax corrected to use colons (`/prfaq:review` not `/prfaq review`)

### Removed
- `docs/prd/` directory (Feature Dev artifact from development — the feature is shipped)

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

[Unreleased]: https://github.com/punt-labs/prfaq/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/punt-labs/prfaq/compare/v1.7.3...v1.8.0
[1.7.3]: https://github.com/punt-labs/prfaq/compare/v1.7.2...v1.7.3
[1.7.2]: https://github.com/punt-labs/prfaq/compare/v1.7.1...v1.7.2
[1.7.1]: https://github.com/punt-labs/prfaq/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/punt-labs/prfaq/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/punt-labs/prfaq/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/punt-labs/prfaq/compare/v1.5.2...v1.6.0
[1.5.2]: https://github.com/punt-labs/prfaq/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/punt-labs/prfaq/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/punt-labs/prfaq/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/punt-labs/prfaq/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/punt-labs/prfaq/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/punt-labs/prfaq/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/punt-labs/prfaq/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/punt-labs/prfaq/compare/v0.9.1...v1.0.0
[0.9.1]: https://github.com/punt-labs/prfaq/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/punt-labs/prfaq/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/punt-labs/prfaq/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/punt-labs/prfaq/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/punt-labs/prfaq/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/punt-labs/prfaq/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/punt-labs/prfaq/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/punt-labs/prfaq/releases/tag/v0.4.0
