# PR/FAQ Hive Meeting Summary
**Date:** 2026-02-16
**Document:** prfaq.tex (Stage: validated, v1.5)
**Mode:** Hive (autonomous consensus)
**Scope:** Full meeting: all 7 hot spots debated

## User Action Required

None. All decisions reached consensus or resolved via bias-for-action. No escalations.

## Decisions

| # | Hot Spot | Severity | Door | Decision | Resolution | Winning Argument | Dissent |
|---|----------|----------|------|----------|------------|------------------|---------|
| 1 | Document describes 3 commands; shipped product has 7 | CRITICAL | two-way | REVISE | CONSENSUS | Press release, solution section, and getting started are internally inconsistent with shipped product | None |
| 2 | Customer quote (Marcus Okonkwo) is fabricated | CRITICAL | two-way | REVISE | CONSENSUS | Fabricated attribution at validated stage is dishonest; label as illustrative or replace with real evidence | None |
| 3 | Install URL broken (punt-labs.github.io vs raw.githubusercontent.com) | CRITICAL | one-way | REVISE | CONSENSUS | Broken install command is a feasibility failure at any stage | Dana: aspirational URL could become a redirect target later |
| 4 | Revenue/pricing data has no vintage date | WARNING | two-way | REVISE | CONSENSUS | Time-sensitive market data presented as structural fact; 15-minute fix eliminates needless credibility risk | None |
| 5 | "9 files" claim is outdated (actual: ~27 files) | WARNING | two-way | REVISE | CONSENSUS | File count is wrong by 3x; reframe around zero-infrastructure argument instead | None |
| 6 | Feature Appendix lists shipped features as V2 "Should Do" | WARNING | two-way | REVISE | BIAS-FOR-ACTION | `/prfaq:meeting` shipped v0.6.0, `/prfaq:meeting-hive` v0.8.0, `/prfaq:rate` v0.7.0; document treats shipped work as speculative | Priya and Alex wanted REJECT (stronger); Wei and Dana wanted ITERATE. All agree content must change. |
| 7 | TAM and competitive FAQ missing meeting/hive differentiator | SUGGESTION | two-way | REVISE | CONSENSUS | Meeting simulation is the moat: the one capability competitors cannot replicate by pasting a template into Claude.ai | None |

## Revision Queue (for /prfaq:feedback)

### Directive 1: Rewrite press release, solution, and getting started to reflect the shipped 7-command product

The press release says "three commands: /prfaq, /prfaq:import, and /prfaq:feedback." The shipped product has seven: /prfaq, /prfaq:feedback, /prfaq:meeting, /prfaq:meeting-hive, /prfaq:review, /prfaq:research, and /prfaq:rate. Rewrite the press release lede, solution section, and getting started block to describe the actual product. The workflow is now generate → review → meeting → feedback → iterate, not generate → import → iterate. /prfaq:import is listed in Must Do but hasn't shipped; keep it in the Feature Appendix as planned work, but don't describe it in the press release as if it exists. Add the meeting and review capabilities to the solution section as shipped differentiators.

### Directive 2: Replace fabricated customer quote with honest placeholder

Remove "Marcus Okonkwo, Founder, SyncPilot"; this person doesn't exist. At validated stage, either: (a) label the quote as an illustrative composite with a note like "Composite quote based on builder interviews and community feedback", or (b) replace it with a real quote from a trial user once validation interviews are done, or (c) replace the customerquote section with a brief vignette describing the target customer's pain point without fabricated attribution. Option (a) is the fastest fix that preserves the content while being honest about provenance.

### Directive 3: Fix the install URL to the working command

Replace `https://punt-labs.github.io/prfaq/install` with `https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh` in the Getting Started section and the External FAQ "How do I get started?" These are the only two locations. The command should be: `curl -fsSL https://raw.githubusercontent.com/punt-labs/prfaq/main/install.sh | bash`.

### Directive 4: Add data vintage notes to pricing and revenue claims

In the "How much does it cost?" FAQ, add "(as of Q1 2026)" after Sonnet pricing and after the Claude Code subscription tiers. Add a note: "Pricing changes; check anthropic.com/pricing for current rates." In the TAM FAQ, the Anthropic revenue citation already has a date; no change needed there. Verify that current Sonnet pricing is still $3/$15 per million tokens and that Claude Code subscription tiers haven't changed.

### Directive 5: Replace "9 files" with zero-infrastructure argument

In the cost structure FAQ and viability risk assessment, replace "9 files" with the accurate count (~27 core files), or better yet, remove the file count entirely and reframe around the zero-infrastructure principle: no servers, no API keys, no databases, no backend. The forkability argument rests on architectural simplicity, not file count. Wei's suggestion: "The plugin is markdown files, a LaTeX template, and a shell script: no infrastructure dependencies." Dana's: "Install once, use forever. If punt-labs disappears tomorrow, the plugin continues working."

### Directive 6: Restructure Feature Appendix to separate Shipped from Planned

Create three sections: **Shipped (V1)**: everything through v0.8.1 (discovery workflow, document generation, LaTeX compilation, reference guides, peer review, research, citations, /prfaq:feedback, /prfaq:review, /prfaq:research, /prfaq:meeting with four personas, /prfaq:meeting-hive with autonomous consensus, /prfaq:rate, stage awareness, version tracking, cross-references). **Planned**: features not yet shipped: /prfaq:import, Markdown output mode, comparative analysis, template customization, alternative CLI distribution. **Won't Do**: unchanged. Update the timeline FAQ to reflect that the "most technically ambitious" feature (meeting simulation) shipped in v0.6.0 and the autonomous hive variant shipped in v0.8.0. Remove "meaningful execution risk" language about shipped features; add refinement risks if any remain.

### Directive 7: Add meeting/hive as primary differentiator in TAM and competitive FAQs

In the TAM FAQ, add a paragraph explaining how the meeting feature changes the value proposition for each audience segment, especially Side A (non-technical builders who've never sat in a product review meeting). In the competitive landscape FAQ, lead the differentiator list with meeting simulation: "The most credible alternative is pasting a PR/FAQ template into Claude.ai. What it cannot replicate: a multi-persona review meeting where four experts with distinct risk lenses debate your document and surface blind spots. You cannot simulate that by pasting a template into a chat." Update the validation plan to include testing the meeting feature, not just the generation workflow.

## Deferred Items

None.

## Research Completed

None required. All hot spots were factual accuracy issues, not evidence gaps.

## Notes

The symmetry is worth noting: this hive meeting is itself proof of Hot Spot 7's argument. The meeting feature is running, four personas debated seven hot spots, reached consensus on all seven without user intervention, and produced specific revision directives. The document that describes this capability as "the most ambitious planned feature with meaningful execution risk" is being revised by the very feature it claims hasn't been built yet.

All 7 hot spots reached resolution in Round 1. No Round 2 rebuttals were needed. The only split (Hot Spot 6: 2 ITERATE vs 2 REJECT) was about severity, not direction: all four personas agreed the content must change. This resolved via bias-for-action on a two-way door.

To apply all revisions automatically, run: `/prfaq:feedback`
