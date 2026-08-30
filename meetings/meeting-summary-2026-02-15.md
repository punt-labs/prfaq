# PR/FAQ Review Meeting Summary
**Date:** 2026-02-15
**Document:** prfaq.tex (dogfood)
**Scope:** Full meeting (6 hot spots)

## Decisions

| # | Hot Spot | Severity | Decision | Rationale |
|---|----------|----------|----------|-----------|
| 1 | Customer Evidence: zero primary data | CRITICAL | **REVISE** | Add validation strategy FAQ (10-20 user testing, opt-in metrics/feedback). Keep fictional customer quote (Working Backwards method). |
| 2 | TAM: denominator missing | CRITICAL | **RESEARCH + REVISE** | Researcher returned 21 citations. Rewrite TAM with estimated denominator, broader framing (vibe coders + expert PMs), distribution nuance, trajectory. |
| 3 | Press release confidence vs FAQ hedging | WARNING | **KEEP AS-IS** | This is v1 Working Backwards working correctly. Future iterations replace hedges with evidence. |
| 4 | Anthropic platform risk | WARNING | **REVISE** | Upgrade feasibility to Medium. Reframe as category creation + strategic exposure. Add Codex CLI + other channels to Should Do. Add portability assurance. |
| 5 | Viability: solo maintainer | WARNING | **REVISE** | Add forkability framing. Note engineer users naturally contribute. Add premium research commercial model (Pitchbook, Statista, survey agents), gated on PMF. Reframe strategic value confidently. |
| 6 | Pre-mortem: external attribution | SUGGESTION | **REVISE** | Add 6th scenario: "We misidentified the customer or their motivation." |

## Revision Queue (for /prfaq:feedback)

### Directive 1: Validation Strategy FAQ
Add a new internal FAQ about validation strategy: how we will validate the product by asking 10-20 people to use it, allowing them to send metrics back, and exploring a slash command for user feedback via a single API. Keep the fictional Marcus Okonkwo quote as-is.

### Directive 2: TAM Denominator
Rewrite the TAM FAQ with an estimated denominator range. Use the broader framing: (a) non-technical builders using Lovable/Bolt/Replit who need product discipline; cite Lovable 8M users, Replit 75% non-coders, YC 25% AI-generated codebases, (b) expert PMs seeking AI leverage for leaner teams, (c) Claude Code crossing the chasm to non-technical users. Add distribution nuance: Claude Code is the right architecture, imperfect distribution for some segments, perfect for others. Include trajectory alongside current estimates. Add new biblatex citations from researcher.

### Directive 3: Platform Risk + Multi-Platform
Upgrade feasibility risk from Low to Medium. Reframe competitors FAQ to acknowledge both strategic exposure (Anthropic could build native feature) and category-creation leverage (if Anthropic features or copies us, both validate the category). Add customer-facing portability assurance (LaTeX output is standalone). Relocate "Alternative LLM backends" from Won't Do to Should Do; add Codex CLI and other CLI-based distribution channels.

### Directive 4: Viability + Commercial Model
Revise viability section: add forkability/user-resilience framing ("designed to survive maintainer abandonment: 9 files, no backend, standalone output"). Note that engineer-heavy user base naturally tracks maintainers. Add internal FAQ about potential commercial model: premium research access (Pitchbook, Statista, survey agents) as future subscription tier, gated on PMF evidence. Reframe strategic value from "learning vehicle" to "establishing punt-labs as the reference implementation for AI-assisted product development tooling."

### Directive 5: Pre-mortem
Add 6th pre-mortem failure scenario: "Sixth, we misidentified the customer or their motivation: the tool solves the wrong person's problem, or targets the right person for the wrong reason (e.g., builders want stakeholder theater, not genuine product discipline)."

## Research Completed
TAM evidence researcher returned 21 biblatex citations covering:
- Vibe coding growth (Lovable 8M users, Bolt $40M ARR, Replit 35M users/75% non-coders, Cursor $1B ARR)
- Claude Code trajectory (WAU doubled Jan-Feb 2026, business subs 4x, $2.5B ARR)
- AI-assisted dev market ($7.37B in 2025, projected $24-65B by 2030)
- YC W25: 25% of startups have 95% AI-generated codebases
- AI code quality burden (66% cite "almost right" frustration, 8,000+ startups need rebuilds)
- PM tooling market ($2.5B in 2025, 1.06M PMs globally)
- Token economics (50x cost decrease, but total spend rising due to agentic workflows)

## New Beads Created
- `prfaq-gt7`: Explore versioned/staged PR/FAQ documents (P3)

## Notes
- The meeting itself validated the /prfaq:meeting feature: all four personas produced substantively different analyses, the debates surfaced real tradeoffs, and the user made 6 decisions in ~1 hour that would have taken days of unstructured thinking.
- Key strategic shifts from this meeting: multi-platform distribution (Codex CLI), premium research commercial model, forkability as viability mitigation, broader TAM framing (vibe coders + expert PMs).
