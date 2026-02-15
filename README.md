# prfaq

A Claude Code plugin that brings Amazon's Working Backwards PR/FAQ process to engineers and founders — generate, review, stress-test, and iterate on product discovery documents inside the terminal.

## What It Does

`prfaq` turns product thinking into a terminal command. Type `/prfaq` in any Claude Code session and Claude walks you through a structured conversation: who is the customer, what is their problem, why is this solution different, what are the risks. From your answers, it generates a complete PR/FAQ document — a mock press release followed by detailed FAQs — compiled to a polished PDF.

The output is a decision-making artifact, not a brainstorm. It is designed to be read, debated, and revised before committing to building anything.

Five commands form a complete product-thinking workflow:

| Command | What it does |
|---------|-------------|
| `/prfaq` | Generate a new PR/FAQ from scratch (or revise an existing one) |
| `/prfaq:feedback` | Apply pointed feedback — traces cascading effects and surgically redrafts |
| `/prfaq:meeting` | Simulate an Amazon-style review meeting with four agentic personas |
| `/prfaq:review` | Peer review against Working Backwards principles and cognitive biases |
| `/prfaq:research` | Find evidence for claims using local files, web, and indexed documents |

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh | bash
```

The installer clones the plugin, registers it with Claude Code, and checks for a TeX distribution. Restart Claude Code after installing.

### Prerequisites

PDF compilation requires `pdflatex`. Any TeX distribution works:

```bash
# macOS
brew install --cask mactex

# Ubuntu/Debian
sudo apt install texlive-full
```

The plugin generates `.tex` files regardless — you can install TeX later.

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
  "version": "0.6.0",
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
1. **Discovery** — Gathers customer, problem, and market context
2. **Draft PR** — Generates the press release sections
3. **Draft FAQ** — Generates external and internal FAQs, risk assessment, feature appendix, then runs an adversarial peer review using the Kahneman decision quality framework
4. **Compile** — Produces a PDF via `pdflatex`
5. **Review** — Evaluates against review criteria, identifies weaknesses, iterates

### Iterate: `/prfaq:feedback`

```
/prfaq:feedback the TAM is too large — focus on solo builders, not enterprise teams
```

Takes a directional instruction, traces cascading effects across all affected sections (press release, FAQs, risk assessment, feature appendix), and surgically redrafts. Each cycle recompiles the PDF and runs peer review automatically.

### Stress-Test: `/prfaq:meeting`

```
/prfaq:meeting
```

Simulates an Amazon-style PR/FAQ review meeting with four agentic personas who debate the weak spots in your document:

- **Wei** (Principal Engineer) — feasibility risk, technical honesty
- **Priya** (Target Customer) — value risk, customer reality
- **Alex** (Skeptical Executive) — strategic fit, devil's advocate
- **Dana** (Builder-Visionary) — ambition risk, cost of inaction

You are the PM and final decision-maker. The output is a decisions log with specific revision directives that feed into `/prfaq:feedback`.

### Review: `/prfaq:review`

```
/prfaq:review [path/to/prfaq.tex]
```

Peer review against Working Backwards principles, Cagan's four risks framework, and a Kahneman-informed decision quality checklist. Flags unsupported claims, cognitive biases, vague language, and risk rating inconsistencies.

### Research: `/prfaq:research`

```
/prfaq:research find evidence that developers lack product training
```

Searches local files, web sources, and indexed documents (via quarry-mcp) for evidence. Returns structured biblatex citations ready to add to your `.bib` file.

## Output

- `prfaq.tex` — LaTeX source in your project directory
- `prfaq.bib` — Bibliography with sourced citations
- `prfaq.pdf` — Compiled PDF ready for review

## What Is Working Backwards?

Working Backwards is Amazon's product discovery process: write a mock press release and detailed FAQ *before* building anything. This forces clarity about customer value, surfaces risks early, and creates a shared decision-making artifact.

The PR/FAQ document includes:

- **Press Release** — Summary, problem, solution, customer quote, getting started, spokesperson quote, call to action
- **External FAQs** — Customer-facing questions and answers
- **Internal FAQs** — Business-facing questions organized by value/market, technical, and business risk
- **Four Risks Assessment** — Cagan framework evaluation: value, usability, feasibility, viability
- **Feature Appendix** — Scope boundary: must do, should do, won't do
- **Bibliography** — Sourced citations for all factual claims

## The Workflow

The typical workflow is: **generate** → **review** → **meeting** → **feedback** → repeat.

1. `/prfaq` generates the initial document from a structured conversation
2. `/prfaq:review` gives you an adversarial peer review
3. `/prfaq:meeting` stress-tests the document with four personas who disagree with each other
4. `/prfaq:feedback` applies the meeting's decisions (or your own feedback) surgically

Each step produces a compiled PDF. The document improves with each cycle.

## License

MIT
