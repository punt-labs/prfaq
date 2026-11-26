# prfaq

> Amazon's Working Backwards PR/FAQ process, grounded in your data.

[![License](https://img.shields.io/github/license/punt-labs/prfaq)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/punt-labs/prfaq/docs.yml?label=CI)](https://github.com/punt-labs/prfaq/actions/workflows/docs.yml)
[![Working Backwards](https://img.shields.io/badge/Working_Backwards-hypothesis-lightgrey)](./prfaq.pdf)

`prfaq` is a Claude Code plugin for product managers and engineers. It writes a PR/FAQ, a mock press release plus a set of frequently asked questions written before a product is built, following Amazon's [Working Backwards](#what-is-working-backwards) process. It builds the document from your own research files (customer interviews, survey results, market reports, competitive analysis, usage metrics) and from web search, then reviews, revises, and compiles it, all from inside Claude Code.

**Platforms:** macOS, Linux

## Quick Start

1. **Install** the plugin:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/d975374/install.sh | sh
   ```

   <details>
   <summary>Manual install</summary>

   Register the Punt Labs marketplace:

   ```bash
   claude plugin marketplace add punt-labs/claude-plugins
   ```

   Install the plugin:

   ```bash
   claude plugin install prfaq@punt-labs
   ```

   </details>

   <details>
   <summary>Verify before running</summary>

   Download the installer:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/d975374/install.sh -o install.sh
   ```

   Check its checksum:

   ```bash
   shasum -a 256 install.sh
   ```

   Read it:

   ```bash
   cat install.sh
   ```

   Run it:

   ```bash
   sh install.sh
   ```

   </details>

   <details>
   <summary>Offline install (no marketplace access)</summary>

   This assumes you keep a local Claude Code marketplace at `~/.claude/plugins/local-plugins`. Clone the repository into it:

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

   The `source` points one level below the clone: the plugin itself (manifest, commands, agents, skill, templates, and scripts) lives in the repository's `plugin/` directory, and a plugin root is the directory that holds `.claude-plugin/`.

   </details>

   The installer registers the Punt Labs marketplace, installs the plugin, and checks for pandoc and TeX (see [Setup](#setup) for what each is for). Restart Claude Code after installing. The installer does not grant the plugin any permissions; run `/prfaq:permissions` inside a project to do that (see [Permissions](#permissions)).

2. **Add your research.** Put customer interviews, survey data, market reports, and competitive analysis in a `./research/` directory in your project. The plugin reads `.md`, `.txt`, and `.pdf` files there and treats them as primary sources. Without research files, the plugin uses web search alone, and the document has less evidence behind it.

3. **Run `/prfaq`** in Claude Code.

The plugin reads your research, searches the web for more evidence, asks you a series of questions about the customer, problem, and market, and writes `prfaq.tex`. If TeX is installed, it compiles the PDF. From there: `/prfaq:review` for peer review, `/prfaq:meeting` for a simulated review meeting, `/prfaq:feedback` to revise, and `/prfaq:streamline` to shorten.

## Features

- **Evidence from your files first:** sources in priority order are your local `./research/` files, then web search to fill gaps
- **Citations for factual claims:** each factual claim cites a source in `prfaq.bib` or is marked `[CITATION NEEDED]`; the peer reviewer flags claims without a citation
- **Stage-aware review:** the hypothesis, validated, and growth stages set different evidence expectations for every agent
- **Four Risks assessment:** value, usability, feasibility, and viability, each rated with evidence (Marty Cagan's framework)
- **Cross-referenceable FAQs and feature appendix:** numbered entries (`Q1`, `Q2`, ...) linkable with `\faqref{}` and `\featureref{}`
- **Automatic version tracking:** `/prfaq:feedback` bumps the document's minor or major version based on the size of the change
- **Critical review and simulated meetings:** a peer reviewer that applies Daniel Kahneman's decision quality checklist, plus four persona agents (Claude subagents, each playing one reviewer role) who debate the document's weak points in a simulated review meeting
- **PDF or Word output:** compiles with `pdflatex`, or exports to `.docx` with pandoc, which needs no TeX installation

## Commands

| Command | What it does |
|---------|-------------|
| `/prfaq` | Generate a new PR/FAQ from scratch, or revise an existing one |
| `/prfaq:import` | Import an existing document and run the full `/prfaq` workflow with its content |
| `/prfaq:externalize` | Generate an external press release from the PR/FAQ and CHANGELOG for a specific release |
| `/prfaq:badge` | Add a stage-colored badge to your README that links to the PR/FAQ PDF |
| `/prfaq:feedback` | Apply one instruction, or a meeting's decisions, and edit only the sections it affects |
| `/prfaq:meeting` | Run a simulated review meeting with you and four persona agents |
| `/prfaq:meeting-hive` | Run the meeting without you moderating: the personas debate and decide each point |
| `/prfaq:meeting-listen` | Play back a completed meeting, with each persona in its own voice |
| `/prfaq:review` | Peer review against Working Backwards principles and common cognitive biases |
| `/prfaq:research` | Find evidence for claims in local files and on the web |
| `/prfaq:export` | Export as a Word document (`.docx`) with pandoc; no TeX installation required |
| `/prfaq:streamline` | Remove redundancy, weasel words, and inflated phrases (target: 10–20% shorter) |
| `/prfaq:vote` | Go/no-go decision: three gates, each with a binary verdict and its evidence |
| `/prfaq:feedback-to-us` | Send the plugin's authors an anonymous 1–5 rating, with an optional comment |
| `/prfaq:permissions` | Grant prfaq's permissions in the current project, or check and revoke them |

### Generate: `/prfaq`

```text
/prfaq
```

If a `prfaq.tex` already exists, the skill enters **revise mode**: you can refine the product, add new research, add FAQs, or update risk assessments without starting over.

For a new document, the skill takes you through six phases:

0. **Research Discovery:** scans `./research/` for primary data and offers web research
1. **Discovery:** gathers customer, problem, and market context; sets the document stage
2. **Draft PR:** writes the press release sections
3. **Draft FAQ:** writes the external and internal FAQs, risk assessment, and feature appendix, then runs a peer review that applies Kahneman's decision quality checklist
4. **Compile:** produces a PDF with `pdflatex`
5. **Review:** checks the draft against the review criteria, identifies weaknesses, and revises

### Import: `/prfaq:import`

```text
/prfaq:import path/to/existing-document.md
```

Already have a PR/FAQ draft, product brief, or pitch deck? Import reads your document, extracts its ideas, and runs the full `/prfaq` workflow with that content as a starting point. You confirm and refine each section in the same question-and-answer process as `/prfaq`, with your existing content filled in.

Accepts `.md`, `.txt`, and `.pdf` files, or text pasted directly as the argument.

### Export: `/prfaq:export`

```text
/prfaq:export
```

Exports the PR/FAQ as a Word document (`.docx`) with pandoc. This needs no TeX installation, only pandoc (about 50 MB, against about 4 GB for TeX).

The export converts prfaq's custom LaTeX environments into standard LaTeX that pandoc can read, converts that to `.docx`, then formats the Word document: Palatino body text, dark blue headings, a centered title, and a footer with the document stage and version.

### Externalize: `/prfaq:externalize`

```text
/prfaq:externalize [version]
```

Turns your internal PR/FAQ into a customer-facing press release for a specific release. Reads `prfaq.tex` and `CHANGELOG.md`, detects the release type (first release, major update, or minor/patch), rewrites the relevant sections for an external audience, and compiles a PDF.

The press release covers only what shipped: the CHANGELOG entries and the Feature Appendix items marked shipped, not planned scope. Customer quotes are flagged for replacement with real testimonials. Defaults to the latest version in the CHANGELOG; pass a version to target a specific release.

### Badge: `/prfaq:badge`

```text
/prfaq:badge [path/to/prfaq.tex]
```

Adds a stage-colored shields.io badge to your README that links to the compiled PDF. The color follows the document stage:

- **hypothesis:** grey
- **validated:** blue
- **growth:** green

The command reads `\prfaqstage{}` from your `.tex` file, generates the badge, and adds it to `README.md` next to any existing badges. If a Working Backwards badge already exists, it replaces it in place, which is useful when the stage changes. Example output:

```markdown
[![Working Backwards](https://img.shields.io/badge/Working_Backwards-hypothesis-lightgrey)](./prfaq.pdf)
```

### Iterate: `/prfaq:feedback`

```text
/prfaq:feedback the TAM is too large — focus on solo builders, not enterprise teams
```

Takes one instruction, finds every section it affects (press release, FAQs, risk assessment, feature appendix), and edits only those sections. Each run recompiles the PDF, increments the document version, and runs a peer review.

**Batch mode:** run `/prfaq:feedback` with no arguments after a meeting. It finds the most recent meeting summary and applies all of its revision directives in order, with one compile and one review at the end instead of one per directive.

### Review Meeting: `/prfaq:meeting`

```text
/prfaq:meeting
```

Simulates an Amazon-style PR/FAQ review meeting with four persona agents who debate the weak points in your document:

- **Wei** (Principal Engineer): feasibility risk, technical honesty, "What's the denominator?"
- **Priya** (Target Customer): value risk, customer reality, "Which of those developers am I?"
- **Alex** (Skeptical Executive): strategic fit, devil's advocate, "Compared to what?"
- **Dana** (Builder-Visionary): ambition risk, cost of inaction, "You're thinking too small."

The meeting works through an agenda of hot spots: the weak points in the document that are worth debating. Alex opens with a short assessment before the agenda and closes, after every hot spot is decided, with a verdict and a proposed next step or follow-up meeting. Both assessments answer three questions: is this a problem worth solving, is the solution strong and differentiated, and should we build it now given other priorities. You are the PM and make the final decisions. At each hot spot, the personas debate and you choose KEEP, REVISE, RESEARCH, or DEFER. The output is a decisions log, including Alex's opening and closing assessments, with revision directives that `/prfaq:feedback` can apply.

### Autonomous Review Meeting: `/prfaq:meeting-hive`

```text
/prfaq:meeting-hive
```

The same four personas debate and reach decisions on their own, using Claude Code [Agent Teams](https://code.claude.com/docs/en/agent-teams), an experimental Claude Code feature that runs several agents in parallel. You review the final decisions, not each debate. [Watch a recording](https://www.punt-labs.com/demos).

**How it works:**

1. Alex gives an opening assessment of what is at stake before the agenda
2. A scan of the document identifies 5–8 hot spots
3. Each hot spot is classified as a **one-way door** (hard to reverse: architecture, APIs, data models) or a **two-way door** (easy to reverse: scope, positioning, framing)
4. All four personas evaluate each hot spot independently and in parallel (Round 1), each in its own context
5. The door type weights the result: on two-way doors, ties favor action (ship and learn); on one-way doors, Wei's and Alex's caution counts for more
6. A split triggers a rebuttal round (Round 2), where each persona sees the others' Round 1 positions and answers the strongest counterargument
7. One argument wins; positions are not averaged into a compromise (Amazon's "Disagree and Commit" principle)
8. Persistent splits on one-way doors are recorded and the debate continues without asking you
9. Once every hot spot has a verdict, any recorded splits are presented to you together (REVISE / KEEP / DEFER)
10. Alex gives a closing assessment: a verdict and a concrete next step, noting anything you deferred

The output is a consensus summary, including Alex's opening and closing assessments, with a revision queue that `/prfaq:feedback` can apply.

**Requires** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Run `/prfaq:permissions` to set it in the project's `.claude/settings.json`, then restart Claude Code.

### Listen: `/prfaq:meeting-listen`

```text
/prfaq:meeting-listen [path/to/meeting-summary.md]
```

Plays back a completed meeting summary as a spoken debate, with each of the four personas in its own voice. Alex's opening and closing assessments are spoken too, and the close lists the follow-up items and, when the closing assessment proposes one, the follow-up meeting. Works with both interactive and hive meeting summaries.

**Voices:** each persona has a voice profile for ElevenLabs, one for OpenAI, and a fallback that uses the provider's default voice. The command detects the active text-to-speech provider and picks the matching voice.

**Requires** the [punt-vox](https://github.com/punt-labs/vox) plugin for spoken playback. Without it, the command prints the dialogue with speaker labels and no audio.

### Review: `/prfaq:review`

```text
/prfaq:review [path/to/prfaq.tex]
```

Peer review against Working Backwards principles, Cagan's four risks framework, and a decision quality checklist based on Kahneman's work. Flags unsupported claims, cognitive biases, vague language, and inconsistent risk ratings.

### Research: `/prfaq:research`

```text
/prfaq:research find evidence that developers lack product training
```

Searches your local `./research/` files first, then the web. Returns biblatex citations (entries for the LaTeX bibliography file) ready to add to your `.bib` file. Results are saved to `./research/` so later runs reuse them. Local files always take priority over web results.

### Streamline: `/prfaq:streamline`

```text
/prfaq:streamline
```

Edits the final document for length. Removes redundancy across sections, removes weasel words and empty adjectives, shortens inflated phrases, and asks of every sentence whether it tells the reader anything ("so what"). Targets a 10–20% reduction without changing evidence, citations, customer quotes, risk assessments, or document structure. Use it after revisions are done, before you share the document.

### Decide: `/prfaq:vote`

```text
/prfaq:vote [path/to/prfaq.tex ...or multiple paths for portfolio comparison]
```

Go/no-go decision. Reads the document's own evidence (risk ratings, FAQs, citations, feature scope) and assesses three gates:

1. **Is this a customer problem worth solving?** (value + viability)
2. **Do we have a differentiated solution?** (usability + feasibility)
3. **Should we do this now?** (opportunity cost)

Each gate gets a binary **GO** or **NO-GO** with 3–5 bullet points of evidence. Gate 1 is a hard prerequisite: NO-GO on the customer problem means NO-GO overall, whatever the solution looks like.

**Single-document mode:** assesses one PR/FAQ. If no FAQ addresses opportunity cost or alternatives, the command flags the gap and suggests adding one ("What are the best alternatives for us to pursue if we do not build this?").

**Multi-document mode:** pass several `.tex` paths. Each document gets its own assessment, then a ranked portfolio table shows which projects have the strongest evidence relative to the investment they need.

The vote also checks `./meetings/` for meeting summaries and notes whether their decisions have been applied.

### Permissions: `/prfaq:permissions`

```text
/prfaq:permissions [check|remove]
```

Grants prfaq's permission rules in the current project, reports which are in place, or revokes them. Writes only the project's own `.claude/settings.json`; see [Permissions](#permissions) below for what the rules cover and why they are never global.

## Setup

### Output Dependencies

You need **at least one** of TeX or pandoc to produce output. Without either, the plugin writes `.tex` source but cannot render it.

| Dependency | What it's for | Size |
|-----------|---------------|------|
| **TeX distribution** | `.pdf` output, the recommended and highest-fidelity format | ~4 GB |
| **[pandoc](https://pandoc.org/)** | `.docx` export with `/prfaq:export`, a smaller alternative when TeX isn't practical | ~50 MB |

We recommend TeX, because the PDF is the version people usually circulate and review. Use pandoc if TeX isn't practical for your setup.

### Other Optional Dependencies

| Dependency | What it's for | Size | Required? |
|-----------|---------------|------|-----------|
| **[Agent Teams](https://code.claude.com/docs/en/agent-teams)** | Runs the personas in parallel for `/prfaq:meeting-hive`; `/prfaq:permissions` enables it in your project | None (environment variable) | Only for autonomous meetings (use `/prfaq:meeting` without it) |
| **[punt-vox](https://github.com/punt-labs/vox)** | Spoken playback for `/prfaq:meeting-listen` | ~5 MB | No; without it, meeting-listen prints the dialogue as text |

### Permissions

prfaq's commands compile documents, edit `.tex` files, and search the web. By default, Claude Code asks for approval each time. To stop the prompts, run this inside the project you're writing the PR/FAQ in:

```text
/prfaq:permissions
```

That writes prfaq's rules into the project's `.claude/settings.json` and nothing else. Two things follow:

- **The rules apply only to that project.** `/prfaq:permissions` never writes to your global `~/.claude/settings.json`, because rules there would apply in every project you open, including projects that have nothing to do with prfaq. Older prfaq releases did write global rules; if your global file still has some, remove them by hand (the [Changelog](CHANGELOG.md) lists the change).
- **`.claude/settings.json` is normally committed**, so the permissions are shared with everyone who works in the repository. To keep them to yourself, move the rules into `.claude/settings.local.json`, which is gitignored.

`/prfaq:permissions check` reports what's in place; `/prfaq:permissions remove` takes it back out. The rules cover the plugin's own compile and export scripts, edits to `*prfaq*.tex`, `*prfaq*.bib`, `press-release-*.tex`, `meetings/**`, `research/**`, `README.md`, and `.gitignore`, plus `WebSearch` and `WebFetch` for the researcher agent, and `Skill(prfaq:*)` for every command, with `ask` rules so `/prfaq:permissions` and `/prfaq:feedback-to-us` still prompt. `Bash(curl *)` and every `Bash(rm *)` form are left out on purpose, so those keep prompting.

Requires `jq`. Without it, the command prints the rule list so you can add it by hand.

## Document Features

### Stage Awareness

Every document declares its stage with `\prfaqstage{hypothesis}`, `\prfaqstage{validated}`, or `\prfaqstage{growth}`. The stage appears in the page header and sets the evidence expectations used across the plugin:

- **hypothesis:** early-stage idea; soft evidence is acceptable; the focus is on a clear customer problem
- **validated:** customer interviews are done; expects quantitative evidence and specific metrics
- **growth:** after launch; expects retention data, unit economics, and scaling concerns

All eight agents adjust their standards to the document's stage.

### Version Tracking

Documents record their version with `\prfaqversion{major}{minor}`. The version appears in the page header next to the stage (for example, `Stage: hypothesis | v1.5`). `/prfaq:feedback` increments the version each time it applies a change: a minor bump for editorial changes, a major bump for structural changes (persona change, problem reframe, business model change).

### Cross-References

FAQ questions are numbered (`Q1`, `Q2`, ...) and can be cross-referenced with `\faqref{faq:slug}`, which renders as a clickable "FAQ 7". Feature appendix entries use `\featureref{feat:slug}`. These let one section point to an exact entry in another.

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

prfaq runs entirely inside Claude Code. The commands hand work to eight agents (Claude subagents with their own instructions and tools): a peer reviewer, a researcher, a feedback editor, a streamliner, and the four meeting personas. Each agent loads reference guides that describe one part of the method, such as press release structure or the four risks, and each guide sets different expectations for each document stage.

When the plugin writes a PR/FAQ `.tex` file or a meeting summary, a hook checks the text before it is saved. It blocks the write if the text contains a banned pattern, such as an em dash, and leaves every other file alone. See [Architecture](docs/ARCHITECTURE.md) for the agent list, the reference guides, and how the check works.

## Output

- `prfaq.tex`: LaTeX source in your project directory
- `prfaq.bib`: bibliography with the sources behind each citation
- `prfaq.pdf`: compiled PDF (requires TeX)
- `prfaq.docx`: Word document from `/prfaq:export` (requires pandoc, not TeX)
- `meetings/meeting-summary-*.md` and `meetings/meeting-hive-summary-*.md`: meeting decision logs, which `/prfaq:feedback` can apply

**Example output:** this plugin's own PR/FAQ, written with the plugin: [PDF](./prfaq.pdf) | [DOCX](./prfaq.docx)

The `.tex` files are standard LaTeX. To edit them by hand, open them in [Overleaf](https://www.overleaf.com/) or a local editor such as [TeXShop](https://pages.uoregon.edu/koch/texshop/) (macOS).

## What Is Working Backwards?

Working Backwards is Amazon's product discovery process: write a mock press release and a detailed FAQ *before* building anything. The aim is to make the team state the customer value clearly, find risks early, and have one shared document to base decisions on.

The PR/FAQ document includes:

- **Press Release:** headline, summary, problem, solution, customer quote, getting started, spokesperson quote, call to action
- **External FAQs:** customer-facing questions and answers (numbered, cross-referenceable)
- **Internal FAQs:** business-facing questions organized by value/market, technical, and business risk
- **Four Risks Assessment:** value, usability, feasibility, and viability, each rated with evidence
- **Feature Appendix:** the scope boundary: must do, should do, won't do (numbered, cross-referenceable)
- **Bibliography:** sources for the factual claims

## The Workflow

The typical order is: **generate** (or **import**) → **badge** → **review** → **meeting** → **listen** → **feedback** → repeat → **streamline** → **vote** → **export** → **externalize** → share.

1. `/prfaq` writes the first draft from your answers, or `/prfaq:import` converts an existing document
2. `/prfaq:badge` adds a stage-colored badge to your README that links to the PDF
3. `/prfaq:review` gives you a critical peer review
4. `/prfaq:meeting` runs a simulated review meeting with four personas where you make each decision, or `/prfaq:meeting-hive` lets the personas decide on their own with [Agent Teams](https://code.claude.com/docs/en/agent-teams)
5. `/prfaq:meeting-listen` plays back the meeting as a spoken debate between the personas (requires [punt-vox](https://github.com/punt-labs/vox))
6. `/prfaq:feedback` applies the meeting's decisions, or your own feedback, to the affected sections
7. `/prfaq:streamline` shortens the final document by removing redundancy, weasel words, and inflated phrases
8. `/prfaq:vote` gives a go/no-go decision based on the document's evidence across three gates
9. `/prfaq:externalize` turns the internal PR/FAQ into a customer-facing press release for the shipped version
10. `/prfaq:feedback-to-us` sends the plugin's authors a rating when you're done

`/prfaq`, `/prfaq:import`, `/prfaq:feedback`, `/prfaq:streamline`, and `/prfaq:externalize` recompile the PDF when TeX is installed. `/prfaq:export` writes the `.docx`; the other commands produce reviews, meeting summaries, decisions, or audio, or edit your README.

## Documentation

[Architecture](docs/ARCHITECTURE.md) |
[Contributing](CONTRIBUTING.md) |
[Changelog](CHANGELOG.md) |
[Design decisions](DESIGN.md)

## License

MIT
