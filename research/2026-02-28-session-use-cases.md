# PR/FAQ Session: use-cases (Use-Case Methodology Plugin)

**Date:** 2026-02-28
**Product:** use-cases — Claude Code plugin for Jacobson-Cockburn Use-Case Foundation v1.1
**Document:** `~/Coding/punt-labs/use-cases/prfaq.tex`
**Starting version:** n/a (new document)
**Ending version:** v1.0 (hypothesis stage)
**Plugin version:** 1.2.0
**Model:** Opus 4.6

---

## Session Timeline

Single context window. No compactions during the workflow. The session ran ~56 minutes (21:06–22:02 UTC) for the full Phase 0–5 cycle, then continued in a second context window for post-delivery cleanup (git init, dateline fix).

1. **Phase 0: Research discovery** — Found 3 pre-existing files in `./research/` (autonomous agent conversation transcript, Beadle product claims, and a .docx). Launched researcher agent in background for use-cases-specific claims. Simultaneously launched a standards explorer agent to read `punt-kit/` conventions.

2. **Phase 1: Discovery** — 4 rounds of Q&A with the user. User corrected initial framing (Beadle → use-cases), specified product name, target audience, and "methodology first" positioning. User pointed to proof-of-concept files and existing prfaq.tex as pattern reference.

3. **Phase 2: Press release draft** — Written from template. Spokesperson: Jim Freeman (from plugin.json marketplace config). Dateline: San Francisco (later corrected to Seattle by user in post-delivery edit).

4. **Phase 3: FAQs + risk assessment + feature appendix** — 6 external FAQs, 16 internal FAQs (including one added during peer review fixes), risk assessment (4 dimensions), feature appendix (13 features across 3 categories).

5. **Phase 3c: Peer review** — Single invocation. Verdict: ITERATE (2 criticals, 6 warnings). User accepted all 8 findings immediately ("Accept all, fix now"). All fixed in a single editing pass.

6. **Phase 4: Compile** — 3 compile cycles. First had 1 overfull hbox warning (line 377-378, `\texttt{/use-cases:review}` in a long sentence). First fix attempt (restructure sentence) didn't resolve. Second attempt (remove the `\texttt{}` reference) compiled clean.

7. **Phase 5: Review** — Presented 7-criterion assessment. Weakest area: customer evidence (expected at hypothesis stage).

8. **Post-delivery** — User requested git init + commit (10 files), dateline change (San Francisco → Seattle), and this session notes document.

---

## Skills Used

| Skill | Invocations | Notes |
|-------|-------------|-------|
| `/prfaq` | 1 | Full Phase 0–5 workflow, single context window |
| `/notify` | 1 | Enabled TTS notifications mid-session |
| `/voice` | 1 | Switched to charlie (post-delivery) |

---

## Research Phase Details

### Pre-Existing Research (3 files)

| File | Content | Relevance |
|------|---------|-----------|
| `autonomous_agent_conversation.md` | Full Beadle design transcript | Context only — the use-case methodology was applied here, but Beadle is a different product |
| `autonomous_agent_use_cases_v1.0.docx` | Binary (unreadable by agent) | Skipped |
| `research-2026-02-28-beadle-product-claims.md` | 8 Beadle-specific claims with 16 bib entries | Reused some general entries (OWASP, AWS agent security) |

### Researcher Agent Output

Investigated 6 claims for the use-cases product specifically:

| # | Claim | Verdict | Key Evidence |
|---|-------|---------|-------------|
| 1 | Demand for structured requirements in AI-assisted dev | SUPPORTED | Thoughtworks Technology Radar SDD entry, multiple industry sources |
| 2 | Use-case methodology decline in modern practice | SUPPORTED | Jacobson & Cockburn 2023 ACM article explicitly laments this |
| 3 | AI-assisted requirements generation is viable | SUPPORTED | AWS Kiro (July 2025) validates the category with EARS-format specs |
| 4 | Vibe coding produces quality problems | SUPPORTED (strongest) | CodeRabbit report: 1.7x more issues, 2.74x more XSS in AI code; Red Hat, New Stack backlash articles |
| 5 | Claude Code ecosystem is large enough to target | PARTIALLY SUPPORTED | 115K developers (July 2025) but stat is 8 months stale; marketplace exists with 36 plugins |
| 6 | Methodology can be taught by AI through application | SUPPORTED | The Beadle transcript itself is existence proof; Kiro demonstrates commercial viability |

**Bibliography entries produced:** 25 total in `prfaq.bib`

---

## Discovery Phase Details

### User Corrections During Discovery

The discovery phase required 4 rounds because the initial product understanding was wrong. Key corrections:

1. **Product identity pivot** — The research files focused on Beadle (autonomous agent daemon). User clarified: "this prfaq is focused on the use-case generation capability. The name of the product is use cases." This was a fundamental reframe — the methodology itself is the product, not the system it was applied to.

2. **Audience redirection** — Instead of defining the target customer from scratch, user said "look at the ../prfaq/prfaq.tex — this is similar target audience." Reading the existing prfaq plugin document provided the audience segmentation pattern.

3. **Framing choice** — User explicitly chose "methodology first" over alternatives. This shaped the entire document: the primary value is bringing Jacobson-Cockburn to AI-assisted development, not just generating documents.

4. **Standards context** — User asked to read `punt-kit/**` for organizational standards. This was launched as a background agent and informed the feature appendix and technical FAQ sections.

### Discovery Inputs (Final)

| Input | Value |
|-------|-------|
| Stage | Hypothesis |
| Product name | use-cases |
| Form factor | Claude Code plugin (`/use-cases` slash command) |
| Target customer | Engineers building systems with multiple actors, workflows, or failure modes using Claude Code |
| Problem | AI coding tools generate code from vague prompts; no specification step means accumulated ambiguity |
| Solution | Guided methodology application via conversational AI — actors, goals, scenarios, extensions |
| Differentiation | Only tool using Jacobson-Cockburn format; methodology-first (teaches through application) |
| Model | Open source (Punt Labs) |
| Proof of concept | `~/Coding/local-scripts/prompts*yml` + healthcheck system |

---

## Peer Review Details

Verdict: **ITERATE** (2 criticals, 6 warnings)

### Criticals

| # | Finding | Fix Applied |
|---|---------|-------------|
| 1 | Phantom citation — "60-70% rework rate" attributed to `thoughtworks2025sddblog` but not found at URL | Removed the claim from Problem paragraph. Fixed bib entry note. |
| 2 | TAM uses 8-month-stale statistic (115K developers from July 2025) as if current | Reframed TAM to acknowledge staleness, present as trajectory evidence rather than point estimate |

### Warnings

| # | Finding | Fix Applied |
|---|---------|-------------|
| 3 | Stack Overflow 69% stat misused — measures "don't plan to use AI for project planning," not "skip specification" | Reframed to match what the stat actually measures |
| 4 | Usability and Feasibility risk rated Low despite document's own analysis supporting Medium | Re-rated both to Medium with honest rationale |
| 5 | No FAQ documenting what prfaq has/hasn't proven about plugin development | Added "What has prfaq taught us?" FAQ with honest prfaq status (v1.2.0, pre-launch, no external validation) |
| 6 | "Proven" used 5+ times for methodology that is "established" not "proven" in this context | Replaced all instances: "established," "40-year track record," "practiced," "shipping" |
| 7 | [CITATION NEEDED] marker left in Call to Action | Resolved with planned repo URL |
| 8 | Vague customer definition ("anyone building software with Claude Code") | Tightened to "engineers building systems with multiple actors, workflows, or failure modes" with examples |

**All 8 findings accepted without rejection.** User said "Accept all, fix now" — zero deliberation time on any finding. This suggests the peer reviewer's findings were clearly correct (no debatable flags).

---

## Compilation Issues

| Issue | Location | Fix | Compiles Needed |
|-------|----------|-----|-----------------|
| Overfull hbox (9.23pt) at lines 377-378 | Phase 3 sentence with `\texttt{/use-cases:review}` | Attempt 1: restructured sentence (still overfull). Attempt 2: removed `\texttt{}` reference entirely. | 3 |

**Total compile cycles:** 3 (initial + 2 overfull fixes)

---

## Document Statistics

| Metric | Value |
|--------|-------|
| `.tex` file size | 52 KB |
| `.bib` entries | 25 |
| `.pdf` file size | 185 KB |
| External FAQs | 6 |
| Internal FAQs | 16 (15 original + 1 added during peer review fixes) |
| Risk dimensions | 4 (Value: Medium, Usability: Medium, Feasibility: Medium, Viability: Low) |
| Feature Appendix — Must Do | 4 |
| Feature Appendix — Should Do | 4 |
| Feature Appendix — Won't Do | 5 |
| `\cite{}` references | ~30 |
| `\faqref{}` cross-references | ~8 |
| `\featureref{}` cross-references | ~3 |
| `[CITATION NEEDED]` markers remaining | 0 |

---

## Key Observations

### What Worked Well

1. **Single-session completion** — Full Phase 0–5 in one context window (~56 min), no compactions needed. Compare to Beadle which required 3 context windows. The difference: no hive meeting or batch feedback in this session. The core `/prfaq` workflow fits comfortably in one window.

2. **Researcher agent found the competitive killer** — AWS Kiro was the most important finding. It validates the entire SDD category and positions use-cases as the Jacobson-Cockburn alternative in a field Kiro created. The researcher surfaced this autonomously via web search. The Martin Fowler article analyzing Kiro/spec-kit/Tessl provided the competitive landscape framing.

3. **Peer reviewer caught real issues** — The phantom 60-70% stat (Critical #1) would have been embarrassing in a review. The stat appeared to come from the Thoughtworks blog but was not actually there. This is a hallucination that the reviewer's URL-checking caught. The risk-rating inconsistency (Warning #4) was also substantive — the document's own analysis contradicted its ratings.

4. **Cross-document learning** — Reading `../prfaq/prfaq.tex` for audience pattern and spokesperson convention saved 1-2 rounds of discovery questions. The user's instruction to "look at the prfaq" was efficient shorthand that the workflow supported.

5. **Bibliography-first approach** — Creating the `.bib` file from Phase 0 research before writing any prose meant every claim could be cited immediately. Zero `[CITATION NEEDED]` markers in the initial draft (the one that appeared was in the Call to Action, which is a placeholder by nature).

### Friction Points

1. **Product identity confusion** — The research files were about Beadle, but the product being documented was use-cases. This caused the first discovery round to go in the wrong direction. The user had to explicitly correct: "this prfaq is focused on the use-case generation capability." A future improvement: ask "what is the product?" before reading research files, so research interpretation is product-aware from the start.

2. **Overfull hbox persistence** — The first fix attempt (restructuring the sentence) didn't resolve the overfull. `\texttt{}` commands in flowing paragraphs are a recurring problem. The compile script correctly flags these, but the fix is sometimes non-obvious — the `\texttt{}` itself may need to be removed rather than the surrounding text restructured.

3. **Background agents** — Two agents were launched in background (researcher + standards explorer). Both completed successfully, but the results weren't available until several turns later. The workflow proceeded with discovery questions while waiting, which was efficient. However, the standards agent output wasn't heavily utilized in the final document — it informed tone but not specific content.

4. **Proof-of-concept was thin** — The user pointed to `~/Coding/local-scripts/prompts*yml` and healthcheck as proof-of-concept, but these demonstrate autonomous agent execution (Beadle's value prop), not use-case methodology application. The real PoC for use-cases is the Beadle conversation transcript in `research/`. This mismatch wasn't caught during discovery.

### Process Insights

- **The methodology-first framing was a user decision, not an AI discovery.** The plugin could have been positioned as "document generator" (like prfaq), "specification tool" (like Kiro), or "methodology teacher." The user chose "methodology first" — a framing that differentiates from Kiro (which uses EARS, not Jacobson-Cockburn) and from spec-kit (which is format-agnostic). This is the kind of strategic positioning decision that the discovery phase surfaced but could not make.

- **Peer review acceptance rate: 8/8 (100%).** Zero rejections. Compare to Beadle post-hive review where the user engaged more selectively with findings. The difference may be: (a) this was the first pass (v1.0) so findings felt like "of course, fix it" rather than defending prior work, or (b) the findings were genuinely uncontroversial. Either way, 100% acceptance on first review suggests the reviewer is well-calibrated at hypothesis stage.

- **The "what has prfaq taught us" FAQ (Warning #5) was meta-recursive.** The peer reviewer flagged that a PR/FAQ for a methodology plugin should address its sibling plugin's track record. The resulting FAQ honestly documents prfaq's pre-launch status and what it has/hasn't proven. This is the kind of intellectual honesty that a human reviewer would demand — "you're selling methodology plugins, but has your first one even shipped?"

- **Dateline city mattered to the user.** Post-delivery, the user corrected San Francisco → Seattle. This is a detail the plugin couldn't know (the user's location). Small but a reminder that geographic identity carries meaning in press release format — it signals where the company is, not where the product is used.

---

## Comparison to Beadle Session (Same Day)

| Dimension | Beadle | use-cases |
|-----------|--------|-----------|
| Context windows | 3 (2 compactions) | 1 (no compaction) |
| Skills invoked beyond `/prfaq` | `/prfaq:meeting-hive`, `/prfaq:feedback`, peer review | peer review only |
| Final version | v2.1 | v1.0 |
| Peer review findings | 2 critical, 8 warnings (post-v2.0) | 2 critical, 6 warnings (post-v1.0) |
| User feedback rounds | 1 batch (7 directives) + 1 manual (6 items) | 1 ("Accept all, fix now") |
| Compile cycles | ~8 | 3 |
| Overfull hbox fixes | 2 (feature appendix, bib note) | 1 (FAQ reference in paragraph) |
| Version bumps | 2 (1.0→2.0 major, 2.0→2.1 minor) | 0 (delivered at v1.0) |
| Research files pre-existing | 2 | 3 (one was binary/unreadable) |
| New research generated | 0 | 1 (use-cases-product-claims.md) |
| Time estimate | ~2-3 hours (multi-window) | ~56 min (single window) |

The use-cases session was lighter because it stopped at v1.0 — no meeting, no batch feedback, no iteration cycle. The core `/prfaq` workflow (Phase 0-5 + peer review) is the fast path. The Beadle session's additional skills (hive meeting + feedback) added significant value but also significant cost (2 additional context windows).

---

## Files Produced

| File | Size | Notes |
|------|------|-------|
| `prfaq.tex` | 52 KB | Full document with 8 peer review fixes applied |
| `prfaq.bib` | 10 KB | 25 entries |
| `prfaq.pdf` | 185 KB | Zero overfull hbox warnings |
| `research/research-2026-02-28-use-cases-product-claims.md` | 37 KB | Researcher agent output: 6 claims investigated |
