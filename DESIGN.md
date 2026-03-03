# Design Decisions

Architectural decisions that shape the project. Each entry records what was decided, why, and when to revisit.

## 2026-03-02: No Claude Desktop support (for now)

**Decision:** prfaq remains a Claude Code plugin only. No MCP server or `.mcpb` Desktop Extension.

**Context:** Explored feasibility using langlearn-tts as a reference (see `research/claude-desktop-brainstorm.md`). An MCP server could handle the mechanical parts (compile, export, research) since it runs locally with filesystem and subprocess access. The conversation flow would move to Project Instructions.

**Why not:**
- The target audience (builders, engineers) works in terminals with Claude Code
- Desktop would deliver ~40% of the feature set — no agent orchestration (meetings, parallel personas), no precise editing (feedback, streamline), no slash commands
- DOCX export already solves the "no TeX installation" problem without changing platforms
- The effort (rewrite 3 bash scripts to Python, build MCP server, write Project Instructions, test all output formats) is not justified by the incremental reach

**Revisit when:**
- Claude Desktop gains agent orchestration or multi-tool workflow capabilities
- We see demand from non-engineer users (product managers, founders without CLI access)
- Markdown output mode is built anyway, making Desktop support cheap to add
