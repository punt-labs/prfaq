# PRD: /prfaq:meeting

**Status:** Draft
**Date:** 2026-02-15
**Origin:** Bead prfaq-cx1 — "simulated review meeting with agentic personas"

## Problem Statement

`/prfaq:review` identifies problems in a PR/FAQ document. It returns a structured report: critical issues, warnings, recommendations. But it doesn't force the author to *decide* anything.

Real product decisions emerge from debate between people with competing priorities. The engineer wants technical elegance; the customer wants simplicity; the finance person wants unit economics to pencil out; the skeptic asks whether to build it at all. A solo founder building with Claude Code plays all these roles internally but never makes the tradeoffs explicit.

`/prfaq:meeting` turns a static document review into an interactive decision-making session. The user watches named personas debate the weak spots in their document, then makes explicit tradeoff decisions at each disagreement. The output is a decisions log — a concrete record of what was decided, what was deferred, and what needs revision — that feeds directly into `/prfaq:feedback` for automated iteration.

The value proposition is not "better feedback" (the peer-reviewer already gives good feedback). It is **forcing explicit tradeoff decisions** that the author would otherwise leave implicit.

## Target User

Technical founders and solo builders who have a completed PR/FAQ and want to stress-test it before committing to build. They've already run `/prfaq` and probably `/prfaq:feedback` once or twice. The document looks good. But they're uncertain — is this ready to build, or are they missing something?

**Anti-user:** Someone who hasn't written a PR/FAQ yet. The meeting validates; it doesn't generate.

## Architecture

### Core Pattern: Parallel Agents + Main Skill Synthesis

```
Main skill reads document, runs pre-meeting scan
         |
         v
Launch persona agents in parallel (background Tasks)
Each agent reads document + their reference guides
Each returns structured position on hot spots
         |
         v
Main skill synthesizes positions into debate narrative
Identifies disagreements, escalates to decision points
Presents debate + decision to user via AskUserQuestion
         |
         v
User decides (Accept / Revise / Defer / Research)
Main skill records decision, shows cascade consequences
         |
         v
[Repeat for next hot spot, or end meeting]
         |
         v
Output: Decisions log + revision queue for /prfaq:feedback
```

**Why this architecture:**
- Agents can't talk to each other (Task tool constraint)
- Agents return a single message (no multi-turn)
- Only the main skill can interact with the user
- Parallel invocation keeps rounds fast (~same wall-clock as 1 agent)
- Main skill as facilitator enables dramatic synthesis (not just concatenation)

### Persona Distinctness Strategy

LLMs given different system prompts produce *framing* differences, not *voice* differences. Three techniques create genuine distinctness:

1. **Structural response constraints.** Each persona has a mandatory response format that forces different cognitive paths. The engineer must identify the hardest unsolved problem. The customer must describe a concrete scenario. The skeptic must propose a falsifying test.

2. **Information asymmetry.** Each persona reads *different* reference guides. The engineer reads `principal-engineer.md` but not `unit-economics.md`. The customer reads `ux-bar-raiser.md` but not `principal-engineer.md`. Different knowledge creates different concerns.

3. **Voice direction in system prompts.** Explicit syntax and emotional register guidance per persona — not just "you are a principal engineer" but "you speak in qualified claims, you always ask for the denominator, you are skeptical of round numbers."

### Token Economics

Using Sonnet for persona agents + selective reference loading:
- ~25K input tokens per agent per round (document + 2 reference guides + state context)
- 5 hot spots × 4 agents = 20 agent invocations
- Total: ~500K tokens at Sonnet pricing (~$1.50)
- Acceptable for a high-value validation step

## Meeting Flow

### Phase 0: Pre-Meeting Scan

The main skill runs the existing peer-reviewer (or a lightweight scan) to identify **hot spots** — sections where the document is weakest. Each hot spot is a judgment call with real tradeoffs, not a formatting issue.

Hot spots are ranked by severity:
- **Critical** — undermines the core argument (must address)
- **Warning** — weakens the document (should address)
- **Suggestion** — could improve (nice to have)

### Phase 1: Agenda & Scope Selection

Present the agenda to the user:

```
MEETING AGENDA

 CRITICAL (must address):
  1. Customer Evidence FAQ — no primary data cited
  2. TAM calculation — three proxies deep, denominator unclear

 WARNING (should address):
  3. Feasibility risk — timeline has no reference class
  4. Competitive response — doesn't address platform risk

 SUGGESTION (nice to have):
  5. Getting Started — no user testing data

How do you want to run this?

 1. Full meeting (all 5 items, ~15 min)
 2. Critical only (2 items, ~5 min)
 3. Pick specific items
 4. Skip meeting — show me the written report instead
```

The user always has the option to skip. Some users just want the report.

### Phase 2: Debate Per Hot Spot

For each agenda item:

1. **Show the claim** — quote the specific text from the document
2. **Launch persona agents in parallel** — each reads the document section + their reference guides + the meeting state so far
3. **Main skill synthesizes debate** — not concatenation, but narrative:
   - Identify who disagrees with whom
   - Escalate: have personas build on each other's points
   - Find the irreconcilable disagreement
   - Present the decision point

4. **User decides** via AskUserQuestion:
   - Accept flag — revise the section (queued for /prfaq:feedback)
   - Reject flag — current text is fine, move on
   - Request research — invoke researcher agent on this claim
   - Defer — needs more thinking, address later

5. **Show cascade consequences** — "This decision changes 3 other sections: [list]. Do you want to review those now or queue them?"

### Phase 3: Post-Meeting Summary

```
MEETING SUMMARY

Decisions made: 4
  1. Customer Evidence FAQ — REVISE (add primary research caveat)
  2. TAM calculation — REVISE (commit to viral model, de-emphasize market size)
  3. Feasibility risk — DEFER (needs spike estimate)
  4. Competitive response — ACCEPT (added platform risk paragraph)

Revision queue (for /prfaq:feedback):
  - "Rewrite Customer Evidence FAQ to cite primary research gap explicitly"
  - "Reframe TAM FAQ around viral distribution model"
  - "Add platform risk mitigation to competitive landscape FAQ"

Deferred items:
  - Feasibility risk timeline needs reference class (research needed)

Run /prfaq:feedback to apply revisions? (y/n)
```

## Leadership Principle Weighting

Each persona is anchored to 2-3 primary Amazon Leadership Principles. This prevents the meeting from becoming a pile-on — the cast has genuine tension between caution and ambition because their LPs conflict.

| LP | Wei (Engineer) | Priya (Customer) | Alex (Skeptic) | Dana (Builder) |
|---|---|---|---|---|
| Customer Obsession | | ★★★ | | ★ |
| Ownership | ★★ (ops burden) | | ★★ (strategic) | ★★ (builder's pride) |
| Invent and Simplify | | ★★ | | ★★★ |
| Are Right, A Lot | ★★ | | ★★ | |
| Learn and Be Curious | | | | ★★ |
| Insist on Highest Standards | ★★★ | | | ★ |
| Think Big | | | | ★★★ |
| Bias for Action | | ★★ | | ★★ |
| Frugality | ★★ | | ★★ | |
| Earn Trust | | | ★★★ | |
| Dive Deep | ★★★ | | | |
| Have Backbone | | | ★★★ | ★★ |
| Deliver Results | | ★★ | | ★★ |

The key tension: Wei + Alex pull toward caution (Dive Deep, Earn Trust, Highest Standards). Dana pulls toward ambition (Think Big, Bias for Action, Invent and Simplify). Priya grounds both sides in customer reality (Customer Obsession). The user resolves the tension.

## The Cast (V1: Four Personas)

### Principal Engineer — Wei

**Primary LPs:** Dive Deep, Insist on the Highest Standards
**Lens:** Feasibility risk. Technical honesty.
**Reference guides:** `principal-engineer.md`, `four-risks.md`
**Voice:** Qualified claims, suspicious of round numbers, always asks for the denominator. Speaks in dependent clauses. Respects "I don't know yet" more than confident handwaving.
**Verbal tics:** "What's the denominator?" / "Show me the filters, not the headline number."
**Response format:**
```
1. What is the hardest unsolved technical problem in this section?
2. What decision here is irreversible?
3. Position: APPROVE / ITERATE / REJECT with rationale
```

### Target Customer — Priya

**Primary LPs:** Customer Obsession, Bias for Action
**Lens:** Value risk. Customer reality.
**Voice:** Concrete scenarios over abstractions. Personal experience as evidence. Impatient with marketing language. Collapses abstractions into "what would I actually do at 2 AM?"
**Verbal tics:** "Which of those developers am I?" / "I didn't search for [abstract concept]. I searched for [concrete need]."
**Reference guides:** `ux-bar-raiser.md`, `common-mistakes.md`
**Response format:**
```
1. As a [specific user], what's my reaction to this claim?
2. What's missing from my perspective?
3. Position: APPROVE / ITERATE / REJECT with rationale
```

### Skeptical Executive — Alex

**Primary LPs:** Have Backbone; Disagree and Commit, Earn Trust
**Lens:** Value risk + strategic fit. Devil's advocate.
**Voice:** Challenges the frame, not just the claim. Reframes assertions as harder questions. Treats optimism as a red flag. Has seen ten versions of this pitch before.
**Verbal tics:** "Compared to what?" / "Five hundred thousand who *could* or who *would*?"
**Reference guides:** `decision-quality.md`, `common-mistakes.md`
**Response format:**
```
1. What is the single biggest assumption, and what would falsify it?
2. Why should we build this instead of ten other things?
3. Position: APPROVE / ITERATE / REJECT with rationale
```

### Builder-Visionary — Dana

**Primary LPs:** Think Big, Invent and Simplify, Bias for Action
**Lens:** Ambition risk. The cost of *not* building. Scope simplification.
**Voice:** Sees the 10x version. Pushes back on risk aversion. Finds the elegant simplification. Not a cheerleader — has high standards — but defaults to "ship, learn, iterate" over "analyze until certain."
**Verbal tics:** "You're thinking too small." / "What's the simplest version that could matter?" / "We have enough signal to ship. What are we waiting for?"
**Reference guides:** `pr-structure.md`, `four-risks.md`
**Response format:**
```
1. What's the bigger opportunity this section is underselling?
2. What's the simplest version that captures the core value?
3. Position: APPROVE / ITERATE / REJECT with rationale
```

**Why Dana matters:** Without a positive voice, the meeting degenerates into four critics finding problems. Dana creates productive tension in *both directions* — too cautious vs. too ambitious — so the user's decisions feel like genuine tradeoffs rather than "which problem should I fix?"

**Dana is not a cheerleader.** She challenges the skeptics, but she also challenges the author when they're thinking too small or overcomplicating the solution. Her "Insist on Highest Standards" (★) means she won't ship garbage — she'll push for scope reduction, not quality reduction.

### V2 Additions (if V1 validates)

- **UX Bar Raiser — Jordan:** Usability lens. Obsessed with first impressions. Reads `ux-bar-raiser.md`. Primary LPs: Customer Obsession, Insist on Highest Standards.
- **Unit Economics Reviewer — Sam:** Viability lens. Converts claims to math. Reads `unit-economics.md`. Primary LPs: Frugality, Are Right A Lot, Deliver Results.

## User Stories

### P0 — Must Have

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-1 | Run `/prfaq:meeting` and see a structured debate between distinct personas | Personas sound different without labels. User can identify who's speaking from voice alone. |
| US-2 | Make explicit decisions when personas disagree | AskUserQuestion presents clear choices. Decision is recorded in state. |
| US-3 | Receive a decisions log at meeting end | Log lists every decision, deferred items, and revision queue. |
| US-4 | Feed decisions into `/prfaq:feedback` for automated revision | Revision queue produces valid feedback directives. |
| US-5 | Choose meeting scope (full / critical only / skip) | User is never trapped in an un-skippable meeting. |

### P1 — Should Have

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-6 | See cascade consequences after each decision | "This changes 3 other sections" with specific names. |
| US-7 | Exit the meeting early and still get a useful artifact | Partial decisions log shows what was decided and what wasn't. |
| US-8 | See dramatic disagreement between personas (not just with the document) | At least one debate per meeting where personas challenge each other. |

### P2 — Nice to Have

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-9 | Focus the meeting on specific sections | User picks from agenda. |
| US-10 | Save meeting transcript to project directory | Markdown file with full debate + decisions. |
| US-11 | See humor grounded in truth (not gimmicks) | Personas occasionally make pointed observations that are funny because they're accurate. |

## Scope Boundaries (Explicitly OUT)

- **Real-time streaming from subagents** — agents return complete responses; main skill synthesizes
- **Agents talking to each other** — main skill mediates all interaction
- **Persona customization** — fixed cast for V1
- **Multi-session meetings** — single session, single document version
- **Meeting transcript PDF** — markdown log is sufficient
- **Multiple humans** — solo PM tool

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Personas sound identical | High | Critical | Structural constraints + info asymmetry + voice direction. Two-persona prototype validates before scaling. |
| Debate is theatrical, not substantive | Medium | High | Agents cite specific document text. Disagreements must reference sections. No generic critique. |
| Meeting too long / verbose | Medium | High | Hot-spot focus (5-8 items, not 15+). Progressive disclosure. Exit ramps after each decision. |
| Token cost too high | Medium | Medium | Sonnet for personas. Selective reference loading. Lazy invocation in V2. |
| User doesn't know how to decide | Low | Medium | Facilitator frames decisions as concrete choices, not open-ended questions. |

## Go/No-Go: Two-Persona Prototype

Before building the full feature, build a **two-persona prototype** (Wei + Priya) and test it on the dogfood `prfaq.tex`:

**Pass criteria:**
1. Personas sound distinct — you can tell who's speaking without the label
2. At least one substantive disagreement that `/prfaq:review` wouldn't surface
3. User decision cascades to at least one other section
4. Decisions log feeds cleanly into `/prfaq:feedback`

**Kill criteria:**
- Personas sound the same despite structural constraints
- Debate feels performative (agree too easily or disagree on trivia)
- Orchestration is too brittle (errors, character bleed, hangs)

If the prototype passes, scale to four personas. If it fails, the learning informs improvements to `/prfaq:feedback` instead.

## Implementation Plan

### New Files

```
agents/
  meeting-engineer.md      # Wei — Principal Engineer persona
  meeting-customer.md      # Priya — Target Customer persona
  meeting-executive.md     # Alex — Skeptical Executive persona
  meeting-builder.md       # Dana — Builder-Visionary persona

skills/prfaq/references/
  meeting-guide.md         # How the meeting works (loaded by main skill)

commands/
  meeting.md               # /prfaq:meeting command definition
```

### Modified Files

```
skills/prfaq/SKILL.md      # Add meeting orchestration logic
```

### Build Sequence

1. Write persona agent files with structural constraints + voice direction
2. Write meeting-guide.md reference
3. Write meeting command (commands/meeting.md)
4. Add meeting orchestration to SKILL.md
5. Test two-persona prototype on dogfood prfaq.tex
6. If prototype passes: add remaining personas (Alex + Dana)
7. Test full meeting flow with scope selection + decisions log
8. Verify decisions log → /prfaq:feedback pipeline
