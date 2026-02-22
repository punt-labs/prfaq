# prfaq

A Claude Code plugin that brings Amazon's [Working Backwards](#what-is-working-backwards) PR/FAQ process to engineers and founders — generate, review, stress-test, and iterate on product discovery documents inside the terminal.

## What It Does

`prfaq` turns product thinking into a terminal command. Type `/prfaq` in any Claude Code session and Claude walks you through a structured conversation: who is the customer, what is their problem, why is this solution different, what are the risks. From your answers, it generates a complete PR/FAQ document — a mock press release followed by detailed FAQs — compiled to a polished PDF.

The output is a decision-making artifact, not a brainstorm. It is designed to be read, debated, and revised before committing to building anything.

Eleven commands form a complete product-thinking workflow:

| Command | What it does |
|---------|-------------|
| `/prfaq` | Generate a new PR/FAQ from scratch (or revise an existing one) |
| `/prfaq:import` | Import an existing document and launch the full `/prfaq` workflow with extracted content |
| `/prfaq:externalize` | Generate an external press release from the PR/FAQ and CHANGELOG for a specific release |
| `/prfaq:feedback` | Apply pointed feedback — traces cascading effects and surgically redrafts |
| `/prfaq:meeting` | Amazon-style review meeting with you and four agentic personas |
| `/prfaq:meeting-hive` | Autonomous meeting — personas debate and decide without you moderating |
| `/prfaq:review` | Peer review against Working Backwards principles and cognitive biases |
| `/prfaq:research` | Find evidence for claims using local files, web, and indexed documents |
| `/prfaq:streamline` | Scalpel edit — remove redundancy, weasel words, and bloat (10–20% tighter) |
| `/prfaq:vote` | Go/no-go decision — three-gate assessment with binary verdict and evidence trail |
| `/prfaq:feedback-to-us` | Tell us how the plugin is working for you (anonymous 1-5 feedback) |

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/a4d30cc/install.sh | sh
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
curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/a4d30cc/install.sh -o install.sh
shasum -a 256 install.sh
cat install.sh
sh install.sh
```

</details>

The installer registers the Punt Labs marketplace and installs the plugin. It also checks for TeX dependencies needed for PDF output. Restart Claude Code after installing.

### Optional Dependencies

| Dependency | What it's for | Size | Required? |
|-----------|---------------|------|-----------|
| **TeX distribution** | Compiling the PDF — the core output you circulate and debate | ~4 GB | Yes (without it you only get raw `.tex` source) |
| **Agent Teams** | Parallel persona execution for `/prfaq:meeting-hive` — enabled via `.claude/settings.json` (shipped with the plugin) | None (env var) | Only for autonomous meetings (use `/prfaq:meeting` without it) |
| **[punt-quarry](https://github.com/punt-labs/quarry)** | Semantic search across your indexed documents during research | ~20 MB | No — enhances `/prfaq:research` but not required |

Install TeX separately if the installer reports it missing:

```bash
# macOS
brew install --cask mactex

# Ubuntu
sudo apt-get install texlive-full
```

## Quick Start

```bash
# 1. Install
curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/a4d30cc/install.sh | sh

# 2. Navigate to your project
cd ~/your-project

# 3. (Optional) Add your existing research
mkdir -p research
# Drop customer interviews, survey data, market reports, or
# competitive analysis into ./research/ — the plugin reads
# .md, .txt, and .pdf files and treats them as primary sources.

# 4. Launch Claude Code and generate your PR/FAQ
claude
/prfaq
```

The plugin walks you through a structured conversation, searches your research for evidence, and produces a compiled PDF. From there: `/prfaq:review` for peer review, `/prfaq:meeting` to stress-test, `/prfaq:feedback` to iterate, `/prfaq:streamline` to tighten.

## Command Reference

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

### Externalize: `/prfaq:externalize`

```
/prfaq:externalize [version]
```

Turn your internal PR/FAQ into a customer-facing press release for a specific release. Reads `prfaq.tex` and `CHANGELOG.md`, detects the release type (first release, major update, or minor/patch), extracts and rewrites the relevant sections for external audiences, and compiles a PDF.

The output is scoped to what actually shipped — CHANGELOG entries and Feature Appendix shipped items, not aspirational scope. Customer quotes are flagged for replacement with real testimonials. Defaults to the latest CHANGELOG version; pass a version argument to target a specific release.

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

You are the PM and final decision-maker. At each hot spot, the personas debate and you make the call: KEEP, REVISE, or DEFER. The output is a decisions log with specific revision directives that feed into `/prfaq:feedback`.

### Autonomous Stress-Test: `/prfaq:meeting-hive`

```
/prfaq:meeting-hive
```

Same four personas, but they debate and reach consensus autonomously using Claude Code Agent Teams — you review the final decisions, not each individual debate.

**How it works:**

1. Pre-meeting scan identifies 5-8 hot spots in your document
2. Each hot spot is classified as a **one-way door** (irreversible: architecture, APIs, data models) or **two-way door** (reversible: scope, positioning, framing)
3. All four personas evaluate each hot spot independently in parallel (Round 1), each with an isolated context window
4. Door-weighted resolution: on two-way doors, ties bias toward action (ship and learn); on one-way doors, Wei and Alex's caution carries extra weight
5. Splits trigger a rebuttal round (Round 2) where personas see each other's Round 1 positions and respond to the strongest counterargument
6. Arguments win or lose — no compromise blending (Amazon LP: Disagree and Commit)
7. Only persistent splits on one-way doors escalate to you for a decision

The output is a consensus summary with a revision queue that feeds into `/prfaq:feedback`.

**Requires** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — shipped in `.claude/settings.json`, enabled automatically when you install the plugin.

### Review: `/prfaq:review`

```
/prfaq:review [path/to/prfaq.tex]
```

Peer review against Working Backwards principles, Cagan's four risks framework, and a Kahneman-informed decision quality checklist. Flags unsupported claims, cognitive biases, vague language, and risk rating inconsistencies.

### Research: `/prfaq:research`

```
/prfaq:research find evidence that developers lack product training
```

Searches local files, web sources, and indexed documents (via quarry-mcp if available) for evidence. Returns structured biblatex citations ready to add to your `.bib` file. Results are cached in `./research/` so future runs reuse prior findings.

**Bring your own research.** Drop customer interviews, survey data, market reports, or competitive analysis into `./research/` before running `/prfaq` or `/prfaq:research`. The researcher reads all `.md`, `.txt`, and `.pdf` files in that directory and treats them as primary sources — they take priority over web search results.

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

### Ten Reference Guides

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

Each guide includes stage calibration — the same guide produces different expectations for a hypothesis-stage document vs. a growth-stage document.

## Output

- `prfaq.tex` — LaTeX source in your project directory
- `prfaq.bib` — Bibliography with sourced citations
- `prfaq.pdf` — Compiled PDF ready for review
- `meetings/meeting-summary-*.md` / `meetings/meeting-hive-summary-*.md` — Meeting decisions log (feeds into `/prfaq:feedback`)

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

The typical workflow is: **generate** (or **import**) → **review** → **meeting** → **feedback** → repeat → **streamline** → **vote** → **externalize** → share.

1. `/prfaq` generates the initial document from a structured conversation — or `/prfaq:import` converts an existing document
2. `/prfaq:review` gives you an adversarial peer review
3. `/prfaq:meeting` stress-tests with four personas where you make each call — or `/prfaq:meeting-hive` for autonomous consensus via Agent Teams
4. `/prfaq:feedback` applies the meeting's decisions (or your own feedback) surgically
5. `/prfaq:streamline` tightens the final document — removes redundancy, weasel words, and bloat
6. `/prfaq:vote` renders a go/no-go decision based on the document's evidence across three gates
7. `/prfaq:externalize` turns the internal PR/FAQ into a customer-facing press release for the shipped version
8. `/prfaq:feedback-to-us` when you're done — helps us improve the plugin

Each step produces a compiled PDF. The document improves with each cycle.

## Manual Installation

```bash
git clone https://github.com/punt-labs/prfaq.git ~/.claude/plugins/local-plugins/plugins/prfaq
```

Then register the plugin in `~/.claude/plugins/local-plugins/.claude-plugin/marketplace.json` by adding an entry to the `plugins` array:

```json
{
  "name": "prfaq",
  "description": "Amazon Working Backwards PR/FAQ process",
  "version": "1.2.0",
  "author": { "name": "Your Name", "email": "you@example.com", "organization": "Your Org" },
  "source": "./plugins/prfaq",
  "category": "development"
}
```

## License

MIT
