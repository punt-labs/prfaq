# Claude Desktop Support — Brainstorm

**Date:** 2026-03-02
**Status:** Exploratory — no commitment to build

## The Question

Can prfaq run in Claude Desktop? What would it take, what would we lose, and is it worth it?

## Reference: How langlearn-tts Does It

langlearn-tts follows the "CLI + MCP" distribution architecture:

- **Python MCP server** (`FastMCP`, stdio transport) exposes 4 tools: `synthesize`, `synthesize_batch`, `synthesize_pair`, `synthesize_pair_batch`
- **Desktop Extension bundle** (`.mcpb` via `@anthropic-ai/mcpb`) — user double-clicks, enters API keys, done
- **`manifest.json`** defines server config, `user_config` fields for API keys and output directory
- **`langlearn-tts install`** CLI command writes to `~/Library/Application Support/Claude/claude_desktop_config.json` as a fallback
- The MCP server runs locally with full filesystem and subprocess access — it calls ElevenLabs/OpenAI APIs, writes MP3 files, and can even auto-play via `afplay`

Key insight: langlearn-tts is a **stateless tool provider**. Each MCP call is independent — text in, audio file out. No multi-turn conversation, no agent orchestration, no filesystem exploration.

## What prfaq Is (and Why It's Hard)

prfaq is the opposite of a stateless tool. It's an **interactive multi-phase workflow** that:

1. **Reads the user's project** — Glob/Grep/Read to find research files, existing .tex, .bib, meetings/
2. **Drives a structured conversation** — six phases of discovery questions, each building on prior answers
3. **Generates complex output** — LaTeX source with custom environments, bibliography, cross-references
4. **Compiles output** — shells out to pdflatex (3 passes + biber) or pandoc
5. **Iterates** — feedback, review, meeting, streamline all modify the existing document
6. **Orchestrates agents** — researcher, peer-reviewer, feedback, streamliner, 4 meeting personas

### Coupling to Claude Code

| Capability | Claude Code Tool | Desktop Equivalent |
|-----------|-----------------|-------------------|
| Read files | `Read` | MCP tool (filesystem server) |
| Write/edit files | `Write`, `Edit` | MCP tool (filesystem server) |
| Find files | `Glob`, `Grep` | MCP tool (filesystem server) |
| Run shell commands | `Bash` | MCP server subprocess |
| Web search | `WebSearch` | Built-in (Desktop has web search) |
| Web fetch | `WebFetch` | Built-in or MCP tool |
| Interactive prompts | `AskUserQuestion` | Not available — conversation is the interface |
| Parallel agents | `Agent` + `Task` | Not available |
| Agent Teams | `TeamCreate`, `SendMessage` | Not available |
| Plugin root path | `${CLAUDE_PLUGIN_ROOT}` | `${__dirname}` in manifest.json |
| Skill orchestration | SKILL.md multi-phase | Project Instructions (system prompt) |

## Feasibility Assessment

### What Could Work

**1. Document generation (core value)**

An MCP server could expose tools that handle the mechanical parts:

```
prfaq_compile(tex_path) → pdf_path        # shells out to pdflatex
prfaq_export(tex_path) → docx_path        # shells out to pandoc pipeline
prfaq_research(query, research_dir) → evidence    # reads local files + web search
```

The MCP server runs locally, so it CAN call pdflatex, pandoc, python3 — same as the shell scripts do today. The `.mcpb` bundle would include the scripts and assets.

**2. Project Instructions as the skill**

Claude Desktop's "Project Instructions" are roughly equivalent to a skill prompt. We could ship a markdown file that users paste into their project. It would guide Claude through the same six phases. The instructions would reference the MCP tools for file operations and compilation.

This is the langlearn-tts pattern for tutor prompts — they exist as CLI output (`langlearn-tts prompt show`) that users paste into Desktop Project Instructions.

**3. Research**

Claude Desktop has built-in web search. The researcher's local file reading could be handled by an MCP filesystem tool. Quarry already has MCP tools. So the three evidence sources (local files, quarry, web) are all available in Desktop.

### What We'd Lose

**1. Interactive multi-phase conversation flow**

The skill drives a structured six-phase conversation with specific questions at each phase. In Desktop, we'd need to encode this in Project Instructions and trust Claude to follow them. This is less reliable than the explicit phase gating in SKILL.md. Users might skip phases or Claude might collapse them.

**2. Agent orchestration**

- `/prfaq:meeting` runs 4 persona agents in parallel, each with isolated context and specific reference guides. No equivalent in Desktop.
- `/prfaq:meeting-hive` requires Agent Teams. Completely unavailable.
- `/prfaq:review` invokes the peer-reviewer agent with specific reference guides loaded. Could be partially replicated via Project Instructions, but the agent's isolation (separate context window, specific tools) is lost.

**3. Precise file editing**

The `Edit` tool does surgical string replacement. The feedback and streamline commands depend on this to modify specific sections without rewriting the whole file. An MCP server could expose a `replace_in_file(path, old, new)` tool, but Claude would need to use it correctly.

**4. Slash commands**

Desktop has no slash command system. All 14 commands would need to be invoked via natural language ("review my prfaq", "run a meeting", "export to docx"). This actually works fine — the commands are human-describable.

### What's Unclear

**1. File output model**

Desktop's MCP tools can write files, but the user experience is different. In Claude Code, the user sees the file being written. In Desktop, the tool runs silently and returns a result. We'd need to clearly communicate "your PDF is at /path/to/prfaq.pdf".

**2. LaTeX template bundling**

The `.mcpb` bundle includes the source directory. Scripts and assets would be available at `${__dirname}/scripts/` and `${__dirname}/assets/`. The LaTeX template could be copied from there to the user's project. This should work.

**3. User config requirements**

What would `user_config` in manifest.json need?

- `output_dir` — where to write generated documents (required)
- `tex_path` — path to pdflatex, if not on PATH (optional)
- Nothing else — no API keys needed (all processing is local)

## Output Format Options for Desktop

| Format | External Deps | Quality | Desktop Feasibility |
|--------|--------------|---------|-------------------|
| **PDF** (pdflatex) | TeX ~4 GB | Highest | Feasible — MCP server shells out, same as today |
| **DOCX** (pandoc) | pandoc ~50 MB | Good (~80% of PDF) | Feasible — same pipeline |
| **Markdown** | None | Readable but no styling | Easy — no compilation step, just write .md |
| **HTML** | None | Could match PDF styling with CSS | Medium — would need a LaTeX-to-HTML converter or HTML template |

Markdown is interesting for Desktop because it requires zero external dependencies. The document structure (headings, quotes, lists, bold) maps cleanly to Markdown. We'd lose: Palatino font, SectionBlue headings, page breaks, header/footer, cross-reference links. But the content would be identical.

An MCP tool could offer all four: `prfaq_render(tex_path, format="pdf|docx|md|html")`.

## Architecture Sketch

If we built this, it would be a Python MCP server (like langlearn-tts):

```
prfaq/
  src/prfaq_server/
    server.py          # FastMCP server, stdio transport
    tools.py           # MCP tool definitions
    compiler.py        # pdflatex wrapper (from compile_prfaq.sh)
    exporter.py        # pandoc pipeline (from export_prfaq_docx.sh)
    preprocessor.py    # LaTeX preprocessor (from preprocess_for_docx.sh)
    researcher.py      # local file search + evidence evaluation
  manifest.json        # .mcpb Desktop Extension config
  scripts/build-mcpb.sh
```

### MCP Tools (strawman)

| Tool | What it does |
|------|-------------|
| `prfaq_init(project_dir)` | Copy template to project, create research/ dir |
| `prfaq_compile(tex_path)` | Run pdflatex pipeline, return pdf_path |
| `prfaq_export(tex_path, format)` | Export to docx/md/html |
| `prfaq_research(query, project_dir)` | Search local research files, return evidence |
| `prfaq_read_template()` | Return the LaTeX template content for reference |
| `prfaq_list_research(project_dir)` | List available research files with summaries |

The conversation flow (phases 0-5) would live in **Project Instructions**, not in the MCP server. The server provides tools; Claude provides the workflow.

### What Would NOT Port

- `/prfaq:meeting` and `/prfaq:meeting-hive` — no agent orchestration
- `/prfaq:meeting-listen` — no TTS tools (unless punt-tts is also installed as MCP)
- `/prfaq:feedback` precise editing — could approximate with a file-rewrite tool
- `/prfaq:streamline` — same limitation as feedback

These are the "power user" features that justify Claude Code. Desktop would get the core: generate, compile, export, research, review (via Project Instructions, not an isolated agent).

## Effort Estimate Factors

- **Rewriting 3 bash scripts to Python**: Medium. The preprocessor is ~280 lines of bash with regex — Python would be cleaner. The compiler is a subprocess wrapper. The exporter is a pipeline.
- **MCP server boilerplate**: Small. FastMCP + tool definitions, following langlearn-tts patterns.
- **Project Instructions document**: Medium. Translating SKILL.md's six phases into a system prompt that works without explicit phase gating.
- **Testing**: High. Every output format, every edge case in the preprocessor, macOS + Linux.
- **`.mcpb` packaging**: Small. Follow langlearn-tts's build-mcpb.sh pattern.

## Recommendation

**Not yet.** The ROI isn't there today:

1. **Claude Code is the right home for this tool.** The workflow is deeply interactive and benefits from agent orchestration. Desktop would get a severely diminished version.
2. **The target audience uses terminals.** Builders and engineers who write PR/FAQs work in terminals. They have Claude Code.
3. **Markdown output is the low-hanging fruit.** If the goal is "no TeX required," the DOCX export already solves this. A Markdown renderer (no external deps at all) could be added to Claude Code trivially.
4. **Desktop's value would be for non-technical PMs.** If product managers (not engineers) want to write PR/FAQs, Desktop makes sense. But the LaTeX source and compilation step are barriers regardless of interface — they'd need the Markdown/HTML output path.

**Revisit when:** (a) Claude Desktop gets agent orchestration / multi-tool workflows, (b) we see demand from non-engineer users, or (c) we build the Markdown output mode anyway and Desktop support becomes cheap.
