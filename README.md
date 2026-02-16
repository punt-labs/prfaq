# prfaq

A Claude Code plugin that brings Amazon's Working Backwards PR/FAQ process to engineers and founders — generate, review, stress-test, and iterate on product discovery documents inside the terminal.

## What It Does

`prfaq` turns product thinking into a terminal command. Type `/prfaq` in any Claude Code session and Claude walks you through a structured conversation: who is the customer, what is their problem, why is this solution different, what are the risks. From your answers, it generates a complete PR/FAQ document — a mock press release followed by detailed FAQs — compiled to a polished PDF.

The output is a decision-making artifact, not a brainstorm. It is designed to be read, debated, and revised before committing to building anything.

Seven commands form a complete product-thinking workflow:

| Command | What it does |
|---------|-------------|
| `/prfaq` | Generate a new PR/FAQ from scratch (or revise an existing one) |
| `/prfaq:feedback` | Apply pointed feedback — traces cascading effects and surgically redrafts |
| `/prfaq:meeting` | Simulate an Amazon-style review meeting with four agentic personas |
| `/prfaq:meeting-hive` | Autonomous consensus meeting — personas debate and decide without you moderating |
| `/prfaq:review` | Peer review against Working Backwards principles and cognitive biases |
| `/prfaq:research` | Find evidence for claims using local files, web, and indexed documents |
| `/prfaq:rate` | Rate your experience with the plugin (anonymous 1-5 feedback) |

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh | bash
```

The installer clones the plugin, registers it with Claude Code, checks for a TeX distribution, and offers to install claude-flow for autonomous meetings. Restart Claude Code after installing.

### Prerequisites

PDF compilation requires `pdflatex`. Any TeX distribution works:

```bash
# macOS
brew install --cask mactex

# Ubuntu/Debian
sudo apt install texlive-full
```

The plugin generates `.tex` files regardless — you can install TeX later.

### Required for `/prfaq:meeting-hive`: claude-flow

The autonomous consensus meeting requires [claude-flow](https://github.com/ruvnet/claude-flow) for hive-mind orchestration. The installer will offer to install it:

```bash
npm install -g claude-flow
```

The installer also registers it as an MCP server in Claude Code. If you skip it during install, `/prfaq:meeting-hive` will not be available — use `/prfaq:meeting` for manual moderation instead.

### Optional: quarry-mcp

If you have [quarry-mcp](https://github.com/jmf-pobox/quarry-mcp) installed, the research agent will automatically search your indexed documents for evidence when writing or revising a PR/FAQ. Install it with:

```bash
pip install quarry-mcp
quarry install
```

No additional configuration is needed — `quarry install` registers the MCP server with Claude Code.

### Manual Installation

```bash
git clone https://github.com/punt-labs/prfaq.git ~/.claude/plugins/local-plugins/plugins/prfaq
```

Then register the plugin in `~/.claude/plugins/local-plugins/.claude-plugin/marketplace.json` by adding an entry to the `plugins` array:

```json
{
  "name": "prfaq",
  "description": "Amazon Working Backwards PR/FAQ process",
  "version": "0.8.0",
  "author": { "name": "punt-labs", "email": "hello@punt-labs.com" },
  "source": "./plugins/prfaq",
  "category": "development"
}
```

The automated installer handles this registration automatically.

## Usage

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

Same four personas, but they debate and reach consensus autonomously via claude-flow hive-mind — you review the final decisions, not each individual debate.

**How it works:**

1. Pre-meeting scan identifies 5-8 hot spots in your document
2. Each hot spot is classified as a **one-way door** (irreversible: architecture, APIs, data models) or **two-way door** (reversible: scope, positioning, framing)
3. All four personas evaluate each hot spot independently (Round 1)
4. Door-weighted resolution: on two-way doors, ties bias toward action (ship and learn); on one-way doors, Wei and Alex's caution carries extra weight
5. Splits trigger a rebuttal round (Round 2) where personas respond to each other's arguments
6. Arguments win or lose — no compromise blending (Amazon LP: Disagree and Commit)
7. Only persistent splits on one-way doors escalate to you for a decision

The output is a consensus summary with a revision queue that feeds into `/prfaq:feedback`.

### Review: `/prfaq:review`

```
/prfaq:review [path/to/prfaq.tex]
```

Peer review against Working Backwards principles, Cagan's four risks framework, and a Kahneman-informed decision quality checklist. Flags unsupported claims, cognitive biases, vague language, and risk rating inconsistencies.

### Research: `/prfaq:research`

```
/prfaq:research find evidence that developers lack product training
```

Searches local files, web sources, and indexed documents (via quarry-mcp if available) for evidence. Returns structured biblatex citations ready to add to your `.bib` file.

## Document Features

### Stage Awareness

Every document declares its stage via `\prfaqstage{hypothesis}`, `\prfaqstage{validated}`, or `\prfaqstage{growth}`. The stage appears in the page header and calibrates evidence expectations across the entire plugin:

- **hypothesis** — early-stage idea, soft evidence acceptable, focus on customer problem clarity
- **validated** — customer interviews done, expects quantitative evidence and specific metrics
- **growth** — post-launch, expects retention data, unit economics, scaling concerns

All seven agents, the peer reviewer, and the meeting personas adjust their standards based on the document's stage.

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

### Seven Specialized Agents

Each agent has a distinct role, loads specific reference guides, and produces structured output:

| Agent | Role | Used by |
|-------|------|---------|
| **peer-reviewer** | Adversarial review using Kahneman decision quality framework | `/prfaq:review`, auto-review in `/prfaq` and `/prfaq:feedback` |
| **researcher** | Evidence search across local files, web, and quarry-mcp | `/prfaq:research`, Phase 0 of `/prfaq` |
| **feedback** | Cascading redraft engine — traces dependencies, surgically edits | `/prfaq:feedback` |
| **meeting-engineer** (Wei) | Feasibility risk, irreversible decisions, technical honesty | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-customer** (Priya) | Value risk, customer reality, concrete user scenarios | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-executive** (Alex) | Strategic fit, opportunity cost, devil's advocate | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-builder** (Dana) | Ambition risk, cost of inaction, simplest viable version | `/prfaq:meeting`, `/prfaq:meeting-hive` |

### Nine Reference Guides

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

Each guide includes stage calibration — the same guide produces different expectations for a hypothesis-stage document vs. a growth-stage document.

## Output

- `prfaq.tex` — LaTeX source in your project directory
- `prfaq.bib` — Bibliography with sourced citations
- `prfaq.pdf` — Compiled PDF ready for review
- `meeting-summary-*.md` / `meeting-hive-summary-*.md` — Meeting decisions log (feeds into `/prfaq:feedback`)

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

The typical workflow is: **generate** → **review** → **meeting** → **feedback** → repeat.

1. `/prfaq` generates the initial document from a structured conversation
2. `/prfaq:review` gives you an adversarial peer review
3. `/prfaq:meeting` stress-tests with four personas where you make each call — or `/prfaq:meeting-hive` for autonomous consensus via claude-flow
4. `/prfaq:feedback` applies the meeting's decisions (or your own feedback) surgically
5. `/prfaq:rate` when you're done — helps us improve the plugin

Each step produces a compiled PDF. The document improves with each cycle.

## License

MIT
