# prfaq

> Amazon's Working Backwards PR/FAQ process, grounded in your data.

[![License](https://img.shields.io/github/license/punt-labs/prfaq)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/punt-labs/prfaq/docs.yml?label=CI)](https://github.com/punt-labs/prfaq/actions/workflows/docs.yml)
[![Working Backwards](https://img.shields.io/badge/Working_Backwards-hypothesis-lightgrey)](./prfaq.pdf)

A product discovery document without evidence is fiction. `prfaq` starts from your data — customer interviews, survey results, market reports, competitive analysis, usage metrics — and builds a PR/FAQ document grounded in that evidence, walking you through Amazon's [Working Backwards](#what-is-working-backwards) process inside the terminal.

**Platforms:** macOS, Linux

## Quick Start

1. **Install** the plugin:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/ba3a949/install.sh | sh
   ```

   <details>
   <summary>Manual install</summary>

   ```bash
   claude plugin marketplace add punt-labs/claude-plugins
   claude plugin install prfaq@punt-labs
   ```

   </details>

   <details>
   <summary>Verify before running</summary>

   ```bash
   curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/ba3a949/install.sh -o install.sh
   shasum -a 256 install.sh
   cat install.sh
   sh install.sh
   ```

   </details>

   The installer registers the Punt Labs marketplace, installs the plugin, and checks for pandoc and TeX (see [Setup](#setup) for what each is for). Restart Claude Code after installing. The installer does not grant the plugin any permissions — run `/prfaq:permissions` inside a project to do that (see [Permissions](#permissions)).

2. **Add your research** — drop customer interviews, survey data, market reports, and competitive analysis into a `./research/` directory in your project. The plugin reads `.md`, `.txt`, and `.pdf` files and treats them as primary sources. No research? It still works — it will search the web — but the document is only as good as the evidence behind it.

3. **Run `/prfaq`** in Claude Code.

The plugin reads your research, searches the web for additional evidence, walks you through a structured conversation, and produces a compiled PDF. From there: `/prfaq:review` for peer review, `/prfaq:meeting` to stress-test, `/prfaq:feedback` to iterate, `/prfaq:streamline` to tighten.

## Features

- **Evidence-first generation** — three sources in priority order: local `./research/` files, indexed documents via [punt-quarry](https://github.com/punt-labs/quarry) if installed (30+ supported formats — PDFs, spreadsheets, presentations, source code, images, HTML, DOCX, and more), then web search to fill gaps
- **Every factual claim includes a citation** — traced back to a source, not asserted
- **Stage-aware calibration** — hypothesis, validated, and growth stages set different evidence expectations across every agent
- **Four Risks assessment** — value, usability, feasibility, viability, each rated with evidence (Cagan's framework)
- **Cross-referenceable FAQs and feature appendix** — numbered entries (`Q1`, `Q2`, ...) linkable with `\faqref{}` and `\featureref{}`
- **Automatic version tracking** — `/prfaq:feedback` bumps minor or major versions based on the size of the change
- **Adversarial review and stress-testing** — a peer reviewer using the Kahneman decision quality framework, plus four agentic personas who debate weak spots in a simulated review meeting
- **PDF or Word output** — compiles via `pdflatex`, or exports to `.docx` via pandoc with no TeX installation required

Fifteen commands form a complete product-thinking workflow:

| Command | What it does |
|---------|-------------|
| `/prfaq` | Generate a new PR/FAQ from scratch (or revise an existing one) |
| `/prfaq:import` | Import an existing document and launch the full `/prfaq` workflow with extracted content |
| `/prfaq:externalize` | Generate an external press release from the PR/FAQ and CHANGELOG for a specific release |
| `/prfaq:badge` | Embed a stage-colored badge in your README linking to the PR/FAQ PDF |
| `/prfaq:feedback` | Apply pointed feedback — traces cascading effects and surgically redrafts |
| `/prfaq:meeting` | Amazon-style review meeting with you and four agentic personas |
| `/prfaq:meeting-hive` | Autonomous meeting — personas debate and decide without you moderating |
| `/prfaq:meeting-listen` | Voiced playback of a completed meeting — four personas speak in distinct voices |
| `/prfaq:review` | Peer review against Working Backwards principles and cognitive biases |
| `/prfaq:research` | Find evidence for claims using local files, web, and indexed documents |
| `/prfaq:export` | Export as Word document (.docx) via pandoc — no TeX installation required |
| `/prfaq:streamline` | Scalpel edit — remove redundancy, weasel words, and bloat (10–20% tighter) |
| `/prfaq:vote` | Go/no-go decision — three-gate assessment with binary verdict and evidence trail |
| `/prfaq:feedback-to-us` | Tell us how the plugin is working for you (anonymous 1-5 feedback) |
| `/prfaq:permissions` | Grant prfaq's permissions in the current project — or check and revoke them |

## Commands

### Generate: `/prfaq`

```
/prfaq
```

If a `prfaq.tex` already exists, the skill enters **revise mode** — you can refine the product, incorporate new research, add FAQs, or update risk assessments without starting over.

For a new document, the skill walks you through six phases:

0. **Research Discovery** — Scans `./research/` for primary data, offers web research
1. **Discovery** — Gathers customer, problem, and market context; sets document stage
2. **Draft PR** — Generates the press release sections
3. **Draft FAQ** — Generates external and internal FAQs, risk assessment, feature appendix, then runs an adversarial peer review using the Kahneman decision quality framework
4. **Compile** — Produces a PDF via `pdflatex`
5. **Review** — Evaluates against review criteria, identifies weaknesses, iterates

### Import: `/prfaq:import`

```
/prfaq:import path/to/existing-document.md
```

Already have a PR/FAQ draft, product brief, or pitch deck? Import parses your document, extracts the ideas, and launches the full `/prfaq` generation workflow with that content as a head start. You confirm and refine each section — the same interactive process, just faster because your existing thinking is pre-loaded.

Accepts `.md`, `.txt`, and `.pdf` files, or paste text directly as the argument.

### Export: `/prfaq:export`

```
/prfaq:export
```

Export the PR/FAQ as a Word document (`.docx`) via pandoc. This is the lightweight alternative to PDF — no TeX installation required, just pandoc (~50 MB vs ~4 GB).

The export pipeline pre-processes custom LaTeX environments into standard LaTeX that pandoc understands, converts to `.docx`, then post-processes the Word document for styled output: Palatino serif body, SectionBlue headings, centered title, and a footer with the document stage and version.

### Externalize: `/prfaq:externalize`

```
/prfaq:externalize [version]
```

Turn your internal PR/FAQ into a customer-facing press release for a specific release. Reads `prfaq.tex` and `CHANGELOG.md`, detects the release type (first release, major update, or minor/patch), extracts and rewrites the relevant sections for external audiences, and compiles a PDF.

The output is scoped to what actually shipped — CHANGELOG entries and Feature Appendix shipped items, not aspirational scope. Customer quotes are flagged for replacement with real testimonials. Defaults to the latest CHANGELOG version; pass a version argument to target a specific release.

### Badge: `/prfaq:badge`

```
/prfaq:badge [path/to/prfaq.tex]
```

Embed a stage-colored shields.io badge in your README that links to the compiled PDF. The badge is colored by document stage:

- **hypothesis** — grey
- **validated** — blue
- **growth** — green

The command reads `\prfaqstage{}` from your `.tex` file, generates the badge, and embeds it in `README.md` alongside existing badges. If a Working Backwards badge already exists, it updates it in place (useful when the stage changes). Example output:

```markdown
[![Working Backwards](https://img.shields.io/badge/Working_Backwards-hypothesis-lightgrey)](./prfaq.pdf)
```

### Iterate: `/prfaq:feedback`

```
/prfaq:feedback the TAM is too large — focus on solo builders, not enterprise teams
```

Takes a directional instruction, traces cascading effects across all affected sections (press release, FAQs, risk assessment, feature appendix), and surgically redrafts. Each cycle recompiles the PDF, auto-increments the document version, and runs peer review automatically.

**Batch mode:** Run `/prfaq:feedback` with no arguments after a meeting to auto-discover the most recent meeting summary and apply all revision directives sequentially — one compile and one review at the end, not per-directive.

### Stress-Test: `/prfaq:meeting`

```
/prfaq:meeting
```

Simulates an Amazon-style PR/FAQ review meeting with four agentic personas who debate the weak spots in your document:

- **Wei** (Principal Engineer) — feasibility risk, technical honesty, "What's the denominator?"
- **Priya** (Target Customer) — value risk, customer reality, "Which of those developers am I?"
- **Alex** (Skeptical Executive) — strategic fit, devil's advocate, "Compared to what?"
- **Dana** (Builder-Visionary) — ambition risk, cost of inaction, "You're thinking too small."

Alex opens the meeting with a framing read before the agenda, and closes it with a verdict plus a concrete next-step/reconvene proposal after every hot spot is decided — matching typical review-meeting structure. Both reads are organized around the three questions product development lives or dies on: is this a problem worth solving, do we have a strong and differentiated solution, and should we build this now given competing priorities. You are the PM and final decision-maker in between. At each hot spot, the personas debate and you make the call: KEEP, REVISE, RESEARCH, or DEFER. The output is a decisions log — including Alex's opening and closing assessment — with specific revision directives that feed into `/prfaq:feedback`.

### Autonomous Stress-Test: `/prfaq:meeting-hive`

```
/prfaq:meeting-hive
```

Same four personas, but they debate and reach consensus autonomously using Claude Code [Agent Teams](https://code.claude.com/docs/en/agent-teams) — you review the final decisions, not each individual debate. [Watch a live recording](https://www.punt-labs.com/demos).

**How it works:**

1. Alex gives a standalone opening read framing the stakes before the agenda
2. Pre-meeting scan identifies 5-8 hot spots in your document
3. Each hot spot is classified as a **one-way door** (irreversible: architecture, APIs, data models) or **two-way door** (reversible: scope, positioning, framing)
4. All four personas evaluate each hot spot independently in parallel (Round 1), each with an isolated context window
5. Door-weighted resolution: on two-way doors, ties bias toward action (ship and learn); on one-way doors, Wei and Alex's caution carries extra weight
6. Splits trigger a rebuttal round (Round 2) where personas see each other's Round 1 positions and respond to the strongest counterargument
7. Arguments win or lose — no compromise blending (Amazon LP: Disagree and Commit)
8. Persistent splits on one-way doors are recorded, not asked about mid-run — the hive keeps debating autonomously
9. Once every hot spot has a verdict, any recorded splits are presented to you in one batch (REVISE / KEEP / DEFER)
10. Alex gives a standalone closing read — a verdict plus a concrete next step, acknowledging anything you deferred

The output is a consensus summary — including Alex's opening and closing assessment — with a revision queue that feeds into `/prfaq:feedback`.

**Requires** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Run `/prfaq:permissions` to set it in the project's `.claude/settings.json`, then restart Claude Code.

### Listen: `/prfaq:meeting-listen`

```
/prfaq:meeting-listen [path/to/meeting-summary.md]
```

Post-production voiced playback of a completed meeting summary. The four personas speak in distinct voices, transforming the structured decisions table into a natural debate you can listen to. Alex's opening and closing assessment are voiced too, and the close recaps concrete follow-up items and — when the closing read names one — the agreement to reconvene. Works with both interactive and hive meeting summaries.

**Multi-provider voice support:** Each persona has voice profiles for ElevenLabs (custom community voices with expressive tags), OpenAI, and a fallback for other providers. The command auto-detects the active TTS provider and selects the appropriate voice.

**Requires** [punt-vox](https://github.com/punt-labs/vox) plugin for voiced playback. Without it, the command runs in text-only mode — printing the dialogue with speaker labels but no audio.

### Review: `/prfaq:review`

```
/prfaq:review [path/to/prfaq.tex]
```

Peer review against Working Backwards principles, Cagan's four risks framework, and a Kahneman-informed decision quality checklist. Flags unsupported claims, cognitive biases, vague language, and risk rating inconsistencies.

### Research: `/prfaq:research`

```
/prfaq:research find evidence that developers lack product training
```

Searches your local `./research/` files first, then indexed documents (via [punt-quarry](https://github.com/punt-labs/quarry) if installed), then the web. Returns structured biblatex citations ready to add to your `.bib` file. Results are cached in `./research/` so future runs reuse prior findings. Local files always take priority over web results.

### Streamline: `/prfaq:streamline`

```
/prfaq:streamline
```

Scalpel editor for the final document. Removes redundancy across sections, eliminates weasel words and hollow adjectives, compresses inflated phrases, and applies the "so what" test to every sentence. Targets 10–20% length reduction without touching evidence, citations, customer quotes, risk assessments, or structural elements. Best used after iteration is complete, before sharing the document.

### Decide: `/prfaq:vote`

```
/prfaq:vote [path/to/prfaq.tex ...or multiple paths for portfolio comparison]
```

Go/no-go decision. Reads the document's own evidence — risk ratings, FAQs, citations, feature scope — and assesses three gates:

1. **Is this a customer problem worth solving?** (value + viability)
2. **Do we have a differentiated solution?** (usability + feasibility)
3. **Should we do this now?** (opportunity cost)

Each gate renders a binary **GO** or **NO-GO** with 3-5 bullet points of evidence. Gate 1 is a hard prerequisite — NO-GO on the customer problem means overall NO-GO regardless of solution quality.

**Single-document mode:** assesses one PR/FAQ. If no FAQ addresses opportunity cost or alternatives, the command flags the gap and prompts the team to add one ("What are the best alternatives for us to pursue if we do not build this?").

**Multi-document mode:** pass multiple `.tex` paths for portfolio comparison. Each document gets an individual assessment, then a ranked portfolio view surfaces which projects have the strongest evidence relative to investment required.

The vote also checks for prior deliberation — meeting summaries in `./meetings/` — and notes whether decisions from those meetings have been applied.

### Permissions: `/prfaq:permissions`

```
/prfaq:permissions [check|remove]
```

Grant prfaq's permission rules in the current project, report which are in place, or revoke them. Writes only the project's own `.claude/settings.json` — see [Permissions](#permissions) below for what the rules cover and why they are never global.

## Setup

### Output Dependencies

You need **at least one** of TeX or pandoc to produce output. Without either, the plugin generates `.tex` source but cannot render it.

| Dependency | What it's for | Size |
|-----------|---------------|------|
| **TeX distribution** | `.pdf` output — the recommended, highest-fidelity output | ~4 GB |
| **[pandoc](https://pandoc.org/)** | `.docx` export via `/prfaq:export` — lightweight alternative when TeX isn't practical | ~50 MB |

We recommend **TeX** — the PDF is the artifact you circulate and debate. Use pandoc if TeX isn't practical for your setup.

### Other Optional Dependencies

| Dependency | What it's for | Size | Required? |
|-----------|---------------|------|-----------|
| **[Agent Teams](https://code.claude.com/docs/en/agent-teams)** | Parallel persona execution for `/prfaq:meeting-hive` — set in your project by `/prfaq:permissions` | None (env var) | Only for autonomous meetings (use `/prfaq:meeting` without it) |
| **[punt-vox](https://github.com/punt-labs/vox)** | Voiced playback for `/prfaq:meeting-listen` — four personas speak in distinct voices | ~5 MB | No — without it, meeting-listen runs in text-only mode |
| **[punt-quarry](https://github.com/punt-labs/quarry)** | Semantic search across your indexed documents during research | ~20 MB | No — enhances `/prfaq:research` but not required |

<details>
<summary>Setting up Quarry for research</summary>

If you have [punt-quarry](https://github.com/punt-labs/quarry) installed, you can give the researcher agent semantic search over your research files. This is more powerful than keyword matching — quarry finds conceptually related evidence even when the exact words differ.

```bash
# Register your research directory with a project-scoped database
quarry register ./research/ --db prfaq

# Ingest all registered files
quarry sync --db prfaq

# (Optional) Ingest a URL or additional directory
quarry ingest-url https://example.com/market-report --db prfaq
quarry register ~/Documents/customer-interviews/ --db prfaq
quarry sync --db prfaq
```

Once ingested, the `/prfaq:research` agent and Phase 0 research discovery will automatically use quarry's `search_documents` tool to find relevant evidence. Re-run `quarry sync --db prfaq` after adding new files — registered directories sync incrementally.

</details>

### Permissions

prfaq's commands compile documents, edit `.tex` files, and search the web. Left alone, Claude Code asks for approval each time. To stop the prompting, run this inside the project you're writing the PR/FAQ in:

```
/prfaq:permissions
```

That writes prfaq's rules into the project's `.claude/settings.json` and nothing else. Two consequences worth knowing:

- **The rules are scoped to that project.** prfaq never writes to your global `~/.claude/settings.json` — rules there would apply in every project you open, including projects that have nothing to do with prfaq. Versions 1.5.0 through 1.6.1 did write global rules; installing 1.7.0 or later removes them and leaves a backup next to the file.
- **`.claude/settings.json` is normally committed**, so the permissions are shared with everyone working in the repo. To keep them to yourself, move the block into `.claude/settings.local.json`, which is gitignored.

`/prfaq:permissions check` reports what's in place; `/prfaq:permissions remove` takes it back out. The rules cover the plugin's own compile and export scripts, edits to `*prfaq*.tex`, `*prfaq*.bib`, `press-release-*.tex`, `meetings/**`, `research/**`, `README.md`, and `.gitignore`, plus `WebSearch` and `WebFetch` for the researcher agent. `Bash(curl *)` and every `Bash(rm *)` form are deliberately left out — those keep prompting.

Requires `jq`. Without it, the command reads out the rule list so you can paste it in by hand.

<details>
<summary>Offline install (no marketplace access)</summary>

```bash
git clone https://github.com/punt-labs/prfaq.git ~/.claude/plugins/local-plugins/plugins/prfaq
```

Then register the plugin in `~/.claude/plugins/local-plugins/.claude-plugin/marketplace.json` by adding an entry to the `plugins` array:

```json
{
  "name": "prfaq",
  "description": "Amazon Working Backwards PR/FAQ process",
  "author": { "name": "Your Name", "email": "you@example.com", "organization": "Your Org" },
  "source": "./plugins/prfaq/plugin",
  "category": "development"
}
```

The `source` points one level below the clone: the plugin surface — manifest, commands, agents, skill, templates, and scripts — lives in the repo's `plugin/` directory, and a plugin root is the directory holding `.claude-plugin/`.

</details>

## Document Features

### Stage Awareness

Every document declares its stage via `\prfaqstage{hypothesis}`, `\prfaqstage{validated}`, or `\prfaqstage{growth}`. The stage appears in the page header and calibrates evidence expectations across the entire plugin:

- **hypothesis** — early-stage idea, soft evidence acceptable, focus on customer problem clarity
- **validated** — customer interviews done, expects quantitative evidence and specific metrics
- **growth** — post-launch, expects retention data, unit economics, scaling concerns

All eight agents, the peer reviewer, and the meeting personas adjust their standards based on the document's stage.

### Version Tracking

Documents track their version via `\prfaqversion{major}{minor}`. The version appears in the page header alongside the stage (`Stage: hypothesis | v1.5`). `/prfaq:feedback` auto-increments the version after each application: minor bumps for editorial changes, major bumps for structural shifts (persona change, problem reframe, business model pivot).

### Cross-References

FAQ questions are numbered (`Q1`, `Q2`, ...) and can be cross-referenced with `\faqref{faq:slug}` (renders as a clickable "FAQ 7"). Feature appendix entries use `\featureref{feat:slug}`. These enable precise references between sections.

### Four Risks Assessment

Every document includes a structured risk assessment using Cagan's four risks framework:

| Risk | Question |
|------|----------|
| **Value** | Will customers buy/use it? |
| **Usability** | Can customers figure it out? |
| **Feasibility** | Can we build it? |
| **Viability** | Does the business model work? |

Each risk is rated Low / Medium / High with specific evidence. The peer reviewer and meeting personas challenge these ratings.

## Architecture

### Eight Specialized Agents

Each agent has a distinct role, loads specific reference guides, and produces structured output:

| Agent | Role | Used by |
|-------|------|---------|
| **peer-reviewer** | Adversarial review using Kahneman decision quality framework | `/prfaq:review`, auto-review in `/prfaq`, `/prfaq:feedback`, `/prfaq:import` |
| **researcher** | Evidence search across local files, web, and quarry-mcp | `/prfaq:research`, Phase 0 of `/prfaq`, `/prfaq:import` |
| **feedback** | Cascading redraft engine — traces dependencies, surgically edits | `/prfaq:feedback` |
| **meeting-engineer** (Wei) | Feasibility risk, irreversible decisions, technical honesty | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-customer** (Priya) | Value risk, customer reality, concrete user scenarios | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-executive** (Alex) | Strategic fit, opportunity cost, devil's advocate | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-builder** (Dana) | Ambition risk, cost of inaction, simplest viable version | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **streamliner** | Scalpel editor — removes redundancy, weasel words, inflated phrases | `/prfaq:streamline` |

### Eleven Reference Guides

Domain knowledge is encoded in standalone reference guides that agents load as needed:

| Guide | What it encodes |
|-------|----------------|
| `pr-structure.md` | Section-by-section press release structure |
| `faq-structure.md` | FAQ organization, LaTeX environments |
| `four-risks.md` | Cagan four risks framework, review criteria, decision outcomes |
| `common-mistakes.md` | Anti-patterns and failure modes in PR/FAQ documents |
| `decision-quality.md` | Kahneman decision quality checklist for peer review |
| `meeting-guide.md` | Meeting orchestration: personas, debate synthesis, consensus rules |
| `principal-engineer.md` | Feasibility risk lens: architecture trade-offs, irreversible decisions |
| `unit-economics.md` | Viability risk lens: CAC, LTV, payback period, margins |
| `ux-bar-raiser.md` | Usability risk lens: customer journey, cognitive load, error recovery |
| `precise-writing.md` | Precise writing rules: redundancy, weasel words, "so what" test |
| `plain-style.md` | Generative writing rules every agent applies while drafting: no em dash, no negative parallelism, no corporate-register vocabulary, no value-claim filler, no explaining the document to the reader |

Each guide includes stage calibration — the same guide produces different expectations for a hypothesis-stage document vs. a growth-stage document.

### Prose Quality Enforcement

A deterministic scanner (`plugin/scripts/prose_lint.py`, stdlib Python) runs automatically on every `Write`/`Edit` to a generated PR/FAQ or meeting summary. It blocks the write on a banned pattern: an em dash, a negative-parallelism construction, or a sentence that explains the document's own conventions instead of stating product content. It never touches a file outside that scope. `plugin/banlist.conf` is the single term list the scanner reads. Every writing agent also loads the same rules before drafting, since narrated meeting dialogue never reaches a file for the scanner to check.

## Output

- `prfaq.tex` — LaTeX source in your project directory
- `prfaq.bib` — Bibliography with sourced citations
- `prfaq.pdf` — Compiled PDF ready for review (requires TeX)
- `prfaq.docx` — Word document via `/prfaq:export` (requires pandoc, not TeX)
- `meetings/meeting-summary-*.md` / `meetings/meeting-hive-summary-*.md` — Meeting decisions log (feeds into `/prfaq:feedback`)

**Example output** — this plugin's own PR/FAQ, produced by the plugin itself: [PDF](./prfaq.pdf) | [DOCX](./prfaq.docx)

The `.tex` files are standard LaTeX — if you need to make hand edits, open them in [Overleaf](https://www.overleaf.com/) or a local editor like [TeXShop](https://pages.uoregon.edu/koch/texshop/) (macOS).

## What Is Working Backwards?

Working Backwards is Amazon's product discovery process: write a mock press release and detailed FAQ *before* building anything. This forces clarity about customer value, surfaces risks early, and creates a shared decision-making artifact.

The PR/FAQ document includes:

- **Press Release** — Headline, summary, problem, solution, customer quote, getting started, spokesperson quote, call to action
- **External FAQs** — Customer-facing questions and answers (numbered, cross-referenceable)
- **Internal FAQs** — Business-facing questions organized by value/market, technical, and business risk
- **Four Risks Assessment** — Value, usability, feasibility, viability — each rated with evidence
- **Feature Appendix** — Scope boundary: must do, should do, won't do (numbered, cross-referenceable)
- **Bibliography** — Sourced citations for all factual claims

## The Workflow

The typical workflow is: **generate** (or **import**) → **badge** → **review** → **meeting** → **listen** → **feedback** → repeat → **streamline** → **vote** → **export** → **externalize** → share.

1. `/prfaq` generates the initial document from a structured conversation — or `/prfaq:import` converts an existing document
2. `/prfaq:badge` embeds a stage-colored badge in your README linking to the PDF
3. `/prfaq:review` gives you an adversarial peer review
4. `/prfaq:meeting` stress-tests with four personas where you make each call — or `/prfaq:meeting-hive` for autonomous consensus via [Agent Teams](https://code.claude.com/docs/en/agent-teams)
5. `/prfaq:meeting-listen` plays back the meeting as a voiced debate between personas (requires [punt-vox](https://github.com/punt-labs/vox))
6. `/prfaq:feedback` applies the meeting's decisions (or your own feedback) surgically
7. `/prfaq:streamline` tightens the final document — removes redundancy, weasel words, and bloat
8. `/prfaq:vote` renders a go/no-go decision based on the document's evidence across three gates
9. `/prfaq:externalize` turns the internal PR/FAQ into a customer-facing press release for the shipped version
10. `/prfaq:feedback-to-us` when you're done — helps us improve the plugin

Each step produces a compiled PDF. The document improves with each cycle.

## Documentation

[Changelog](CHANGELOG.md) | [Design decisions](DESIGN.md)

## Development

Quality gates — both must pass before every commit:

```bash
make prfaq                    # Every .tex in TEX_DIRS compiles to a valid PDF
sh tests/test_permissions.sh  # Permission scripts behave correctly
```

Or run both together:

```bash
make check
```

## License

MIT
