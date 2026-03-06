# PR/FAQ Plugin Usage Report: Beadle

**Product:** Beadle — Autonomous Agent Daemon
**Date:** 2026-02-28
**Plugin version:** 1.2.0
**Model:** Opus 4.6
**Document stage:** hypothesis

---

## Inputs

- Product concept provided by user (verbal description of Beadle's trust model, GPG signing, email-triggered execution)
- User-supplied links: AutoGPT GitHub, punt-labs.com/tenets
- User-supplied facts: Seattle location, 182k AutoGPT stars, ClawdBot/OpenClaw incident details, Punt Labs organizational tenets
- No prior document existed — created from scratch

## Time Spent

| Phase | Approximate Wall Clock | Context Windows |
|-------|----------------------|-----------------|
| Document creation (prfaq.tex + prfaq.bib) | ~30 min | 1 |
| Hive meeting (7 hot spots, 28 persona instances) | ~20 min | 1 (compacted during) |
| Batch feedback (7 directives from meeting) | ~15 min | 1 (compacted during) |
| Manual feedback round (user-driven edits) | ~20 min | 1 |
| **Total** | **~85 min** | **3 (2 compactions)** |

## Iterations

| Version | Trigger | Bump Type | What Changed |
|---------|---------|-----------|--------------|
| v1.0 | Initial creation | — | Full document: press release, 15 FAQs, risk assessment, feature appendix, 12 bib entries |
| v2.0 | Hive meeting → batch feedback | Major | 7 directives applied: headline reframed to trust model, competitive moat restructured, GPG/SSH evaluation added, PoC contradiction fixed, kill switch metrics added |
| v2.1 | User manual feedback | Minor | ClawdBot incident added (3 new citations), Punt Labs tenets integrated, star count fixed, headline/location corrected |

## Hive Meeting Statistics

| Metric | Count |
|--------|-------|
| Hot spots identified | 7 |
| Hot spots debated | 7 |
| Persona instances spawned | 28 (4 personas x 7 hot spots) |
| Round 2 rebuttals needed | 0 |
| Unanimous consensus (4-0) | 7 |
| Decisions: REVISE | 7 |
| Decisions: KEEP | 0 |
| Recorded dissent | 1 (Dana on GPG choice — committed) |

## Feedback Application Statistics

| Metric | Count |
|--------|-------|
| Batch directives (from meeting) | 7 |
| Manual feedback items (from user) | 6 |
| Total feedback agent invocations | 9 (7 batch + 2 manual) |
| Direct edits (no agent needed) | 3 (star count x2, version bump) |
| Peer review invocations | 1 |
| Peer review criticals found | 2 |
| Peer review warnings found | 8 |

## Compilation Statistics

| Metric | Count |
|--------|-------|
| Total compile cycles | ~8 |
| Overfull hbox warnings encountered | 2 |
| Recompiles to fix warnings | 3 |

## Outputs

| Output | Location |
|--------|----------|
| PR/FAQ document (LaTeX) | `beadle/prfaq.tex` (893 lines) |
| Bibliography | `beadle/prfaq.bib` (139 lines, 16 entries) |
| Compiled PDF | `beadle/prfaq.pdf` (zero warnings) |
| Hive meeting summary | `beadle/meetings/meeting-hive-summary-2026-02-28.md` |

## Document Statistics (Final)

| Metric | Count |
|--------|-------|
| Press release sections | 6 (lede, problem, solution, customer quote, spokesperson quote, getting started, CTA) |
| External FAQs | 7 |
| Internal FAQs | 9 |
| Risk assessment rows | 4 |
| Feature appendix items | 17 (8 Must Do, 5 Should Do, 6 Won't Do) |
| Bibliography entries | 16 (3 unused flagged by peer review) |
| Citations in document | ~19 `\cite{}` instances |

## Hive Meeting Detail

### Hot Spots Identified (Pre-Meeting Scan)

| # | Hot Spot | Severity | Door | Outcome |
|---|----------|----------|------|---------|
| 1 | GPG as authentication primitive | Critical | One-way | REVISE (consensus) |
| 2 | Email vs CLI as primary interface | Critical | Two-way | REVISE (consensus) |
| 3 | Competitive moat lifespan | Warning | One-way | REVISE (consensus) |
| 4 | Next validation FAQ contradicts PoC | Warning | Two-way | REVISE (consensus) |
| 5 | Proton Bridge as single point of failure | Warning | One-way | REVISE (consensus) |
| 6 | TAM — honest niche or methodology showcase? | Suggestion | Two-way | REVISE (consensus) |
| 7 | 300-500 hours opportunity cost | Suggestion | Two-way | REVISE (consensus) |

### Debate Summaries

**1. GPG as Authentication Primitive (One-way, Critical):** Wei identified that `beadle init`'s GPG abstraction is asserted but never designed. Priya reinforced: "No GPG knowledge needed" has no evidence. Alex noted SSH signing was never evaluated. Dana pushed back — GPG is the only standard with signing + identity + non-repudiation. Majority won: remove misleading `age` fallback (age has no signing), add SSH signing evaluation, be honest that GPG abstraction is the hardest unsolved UX problem. Dana disagreed, committed.

**2. Email vs CLI as Primary Interface (Two-way, Critical):** All four converged independently: the headline leads with "via Email" but Getting Started leads with CLI, and the pre-mortem names email-as-control-plane as the top failure mode. Wei: the trust model, not email, is the actual differentiator. Dana: "Trusted autonomous agent with cryptographic owner control" is stronger than "agent via email." Unanimous: reframe headline around trust model, demote email to one delivery mechanism.

**3. Competitive Moat Lifespan (One-way, Warning):** Dana delivered the winning argument: cloud-hosted AI assistants have an inherent conflict between their business model (data, telemetry, platform lock-in) and the security model a paranoid developer needs. Beadle occupies space structurally off-limits to commercial cloud products. Unanimous: replace "12-18 months" concession with the structural argument.

**4. Next Validation FAQ Contradicts PoC (Two-way, Warning):** Copy-editing gap: Customer Evidence FAQ describes a working prototype running daily for weeks. Next Step FAQ says "Build a minimal prototype" as if starting from scratch. Wei: a reader will conclude either the author forgot what they built, or the evidence is fabricated. Unanimous: rewrite Next Step FAQ to start from actual PoC state.

**5. Proton Bridge as Single Point of Failure (One-way, Warning):** Wei: "CLI-only fallback" means the product loses its primary feature when Bridge crashes — that's describing the failure, not mitigating it. Priya: a Fastmail user needs a new Proton account just to try Beadle. Alex: is this a product that requires Proton, or one that uses email and starts with Proton? Unanimous: defend Proton as a trust model choice, acknowledge IMAP/SMTP abstraction, honest operational mitigation.

**6. TAM — Honest Niche or Methodology Showcase? (Two-way, Suggestion):** Wei mapped the structural problem: "methodology showcase" appears in four contexts doing three different jobs — it's simultaneously the fallback position, opportunity cost mitigation, named failure mode, and viability risk mitigation. Using the same phrase as both success condition and safety net undermines both. Unanimous: remove conditional hedge from TAM FAQ, keep showcase in Revenue FAQ and pre-mortem only.

**7. 300-500 Hours Opportunity Cost (Two-way, Suggestion):** Wei and Priya: 67% variance range with no per-phase breakdown. Alex: the opportunity cost mitigation relies on "methodology showcase" already flagged as insufficient. Dana: existing PoC covers significant Phase 0 scope, so the estimate may be high. Unanimous: add per-phase hour estimates, account for PoC acceleration, replace showcase mitigation with concrete kill switch.

### Observation: Unanimity Pattern

Unlike the prfaq plugin's own hive meeting (2026-02-22), which had a genuine 3-1 split on the TAM and a 2-2 split on the revenue model, the Beadle meeting produced near-perfect unanimity across all 28 votes. This may indicate the document's issues were clearly diagnosable, or that the personas didn't differentiate enough on this domain. The 2022 session's dissent (Wei's REJECT, the Dana/Alex vs Wei/Priya revenue split) forced sharper resolution narratives.

## Batch Feedback Detail

| Directive | Sections Modified | Key Change |
|-----------|-------------------|------------|
| 1. GPG ownership | Tech Risks FAQ, Usability risk, GPG Knowledge FAQ | Removed `age` fallback, added SSH signing evaluation, redesigned `beadle init` abstraction |
| 2. Headline reframe | Headline, lede, solution, Getting Started, CTA, pre-mortem, risk rows, timeline | Trust model replaces email as primary positioning |
| 3. Competitive moat | Competitive Landscape FAQ table + closing | Structural argument replaces "12-18 months" concession |
| 4. Next Step FAQ | Next Step FAQ | Rewritten to start from actual PoC state |
| 5. Proton Bridge defense | Tech Risks, Scaling FAQ, Feature Appendix | Explained why Proton, added operational mitigation, new Should Do feature |
| 6. TAM tightening | TAM FAQ | Removed "methodology showcase" hedge sentence |
| 7. P&L hour breakdown | Timeline FAQ, P&L FAQ, Viability risk | Added Hours column, kill switch metrics, concrete archival conditions |

## Peer Review Results (Post-v2.0)

Verdict: **ITERATE** (2 criticals, 8 warnings)

Criticals:
1. TAM needs derivation chain — "tens of thousands" claimed but no derivation from cited sources
2. Auto-GPT star count mismatch — bib said 160k, document said 180k (fixed in v2.1)

Notable warnings: 4 unused bib entries flagged, pre-mortem doesn't name signing ceremony as specific failure mechanism, several hedging patterns.

## Compilation Issues

| Issue | Location | Fix | Compiles Needed |
|-------|----------|-----|-----------------|
| Overfull hbox (multi-provider feature) | Feature Appendix Should Do | Shortened text twice, then full rewrite | 3 |
| Overfull hbox (Kaspersky bib note) | References (bibliography) | Shortened bib note from full CVE list to summary | 2 |
| Edit tool "file modified since read" | Version bump after feedback agent | Re-read file, retried edit | 1 retry |

## Experience Notes

**What the plugin automated well:**
- Hot spot identification and severity ranking calibrated correctly to hypothesis stage
- One-way/two-way door classification was useful for weighting debate resolution
- Batch feedback application from meeting summary was seamless (auto-discovery, sequential application, cross-reference verification)
- Version bump logic (major vs minor) matched the scope of changes
- Overfull hbox detection and the fix-recompile cycle caught all layout issues
- Each feedback agent made surgical edits with cross-reference verification — no broken `\faqref{}` or `\label{}` references

**Where human input added the most value:**
- ClawdBot/OpenClaw incident (real-world evidence from 5 weeks prior — no persona could surface this; became the strongest "why now" evidence in the document)
- Punt Labs organizational tenets ("earn trust to go fast" — connects product design to company identity)
- Geographic and factual corrections (Seattle, 182k stars)
- Headline/subline wording preferences ("Punt Labs Launches Beadle" — product name in headline)
- The manual feedback round after the automated review cycle was where the document gained its real-world grounding

**Friction observed:**
- Context window pressure from hive meeting (28 persona agents) caused 2 compactions across the session
- Hive meeting unanimity (28/28 ITERATE) produced clean directives but less productive dissent than the use-cases session
- Bibliography overfull hbox warnings are a recurring pattern — long URLs + long notes overflow reliably
- Voice availability (aria unavailable, required fallback to bella) — minor UX friction
