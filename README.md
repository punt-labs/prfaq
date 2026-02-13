# Working Backwards

A Claude Code plugin that guides you through the Amazon Working Backwards PR/FAQ process and produces professional LaTeX documents.

## What Is Working Backwards?

Working Backwards is Amazon's product discovery process: write a 1-page mock press release and detailed FAQ *before* building anything. This forces clarity about customer value, surfaces risks early, and creates a shared decision-making artifact.

The output is a PR/FAQ document — a press release describing the product as if it already launched, followed by external (customer-facing) and internal (business-facing) FAQs that stress-test the idea against Cagan's four risks: Value, Usability, Feasibility, and Viability.

## Installation

### As a local plugin (symlink)

```bash
ln -s /path/to/working-backwards ~/.claude/plugins/local-plugins/plugins/working-backwards
```

Then add an entry to `~/.claude/plugins/local-plugins/.claude-plugin/marketplace.json`:

```json
{
  "name": "working-backwards",
  "description": "Amazon Working Backwards PR/FAQ process — generate professional LaTeX documents for product discovery and decision-making",
  "version": "0.1.0",
  "author": { "name": "yourname", "email": "you@example.com" },
  "source": "./plugins/working-backwards",
  "category": "development"
}
```

### Prerequisites

LaTeX must be installed for PDF compilation. Any TeX distribution with `pdflatex` works:

```bash
# macOS
brew install --cask mactex

# Ubuntu/Debian
sudo apt install texlive-full
```

## Usage

In any Claude Code session:

```
/working-backwards
```

The skill walks you through five phases:

1. **Discovery** — Gathers customer, problem, and market context
2. **Draft PR** — Generates the press release sections
3. **Draft FAQ** — Generates external and internal FAQs, evaluates against four risks
4. **Compile** — Produces a PDF via `pdflatex`
5. **Review** — Evaluates against review criteria, identifies weaknesses, iterates

## Output

- `prfaq.tex` — LaTeX source in your project directory
- `prfaq.pdf` — Compiled PDF ready for review
