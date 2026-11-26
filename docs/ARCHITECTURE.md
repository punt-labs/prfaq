# prfaq architecture

prfaq is a Claude Code plugin. Everything it ships lives under [`plugin/`](../plugin/): the manifest, the slash commands, the agents, the `/prfaq` skill with its reference guides, the LaTeX and Word templates, and the helper scripts.

## Agents

The commands hand work to eight agents. An agent is a Claude subagent with its own instructions and a fixed set of tools. Each agent loads the reference guides it needs and returns structured output to the command that called it. The definitions are in [`plugin/agents/`](../plugin/agents/).

| Agent | Role | Used by |
|-------|------|---------|
| **peer-reviewer** | Critical review against Kahneman's decision quality checklist | `/prfaq:review`, and the review step in `/prfaq`, `/prfaq:feedback`, and `/prfaq:import` |
| **researcher** | Evidence search across local research files and the web | `/prfaq:research`, Phase 0 of `/prfaq`, `/prfaq:import` |
| **feedback** | Finds the sections an instruction affects and edits only those | `/prfaq:feedback` |
| **meeting-engineer** (Wei) | Feasibility risk, hard-to-reverse decisions, technical honesty | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-customer** (Priya) | Value risk, customer reality, concrete user scenarios | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-executive** (Alex) | Strategic fit, opportunity cost, devil's advocate | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **meeting-builder** (Dana) | Ambition risk, cost of inaction, simplest viable version | `/prfaq:meeting`, `/prfaq:meeting-hive` |
| **streamliner** | Removes redundancy, weasel words, and inflated phrases | `/prfaq:streamline` |

## Reference guides

The method is written down in eleven reference guides in [`plugin/skills/prfaq/references/`](../plugin/skills/prfaq/references/). Each guide stands alone, and agents load only the guides they need.

| Guide | Contents |
|-------|----------|
| `pr-structure.md` | Section-by-section press release structure |
| `faq-structure.md` | FAQ organization and LaTeX environments |
| `four-risks.md` | Cagan's four risks framework, review criteria, decision outcomes |
| `common-mistakes.md` | Common mistakes in PR/FAQ documents |
| `decision-quality.md` | Kahneman's decision quality checklist for peer review |
| `meeting-guide.md` | How a meeting runs: personas, combining the debate, consensus rules |
| `principal-engineer.md` | Feasibility risk: architecture trade-offs, hard-to-reverse decisions |
| `unit-economics.md` | Viability risk: customer acquisition cost, lifetime value, payback period, margins |
| `ux-bar-raiser.md` | Usability risk: customer journey, cognitive load, error recovery |
| `precise-writing.md` | Editing rules: redundancy, weasel words, the "so what" test |
| `plain-style.md` | Drafting rules every writing agent applies: no em dash, no negative parallelism, no corporate vocabulary, no value-claim filler, no explaining the document to the reader |

Each guide has a stage calibration section, so the same guide sets different expectations for a hypothesis-stage document and a growth-stage document.

## Prose check

[`plugin/hooks/hooks.json`](../plugin/hooks/hooks.json) registers a `PreToolUse` hook on `Write` and `Edit`. The hook runs [`plugin/scripts/prose_lint.py`](../plugin/scripts/prose_lint.py), a scanner that uses only the Python standard library, on writes to a generated PR/FAQ or meeting summary. It blocks the write if the text contains a banned pattern: an em dash, a negative-parallelism construction, or a sentence that explains the document's own conventions instead of stating product content. It does not check any other file. [`plugin/banlist.conf`](../plugin/banlist.conf) is the single term list the scanner reads.

Meeting dialogue that is spoken or shown in the session is never written to a file, so the hook cannot check it. For that reason every writing agent also loads `plain-style.md` before it drafts.
