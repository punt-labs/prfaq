<!-- lint-config: mode=off -->
<!-- This guide teaches its rules by quoting the violation next to the fix
     ("Bad:" / "Good:"). The "Bad:" lines are deliberate banned-term and
     em-dash examples, not lapses; prose_lint.py has no way to exempt a
     quoted counter-example without exempting the document that contains
     it, so the whole file runs with the linter off (see
     plugin/scripts/prose_lint.py's file_overrides() docstring). -->

# Plain Style

Generative writing rules for every agent that drafts PR/FAQ prose, evaluates a section in a persona's voice, or produces meeting debate and narration in this plugin. These rules apply at the moment a sentence is written, before there is anything for a reviewer or a linter to catch.

## Relationship to Other Guides

Three documents govern prose quality in this plugin, and each does a different job:

- `common-mistakes.md` catches structural anti-patterns once a section already exists (skills-forward thinking, vague customer definition, explaining the document to the reader). Read it to check a finished draft.
- `precise-writing.md` is the streamliner's editing pass on a finished document (redundancy, weasel words, hedge stacking, inflated phrases). Read it to tighten prose that already exists.
- `plain-style.md` (this guide) is generative. It has no draft to inspect and nothing to tighten; it governs the sentence as it is being produced.

The authoritative, machine-checked term list lives in `banlist.conf`, enforced against every in-scope `.tex` file and meeting-summary file by `prose_lint.py`'s PostToolUse hook. Two of the five rules below (no em dash, no negative parallelism) are hard-banned there: a single occurrence blocks the write. The other three (corporate-register vocabulary, value-claim filler, explaining the document) are rationed there, not banned. A linter has to tolerate some noise in a large document, so those three stay under a density threshold instead. This guide holds all five to the same standard: zero occurrences, decided at write time, not after a linter counts them. That standard matters most where no linter ever runs: a live persona debate, a hive-consensus narrative, and a meeting-listen playback segment. None of the three is ever written to a file, so the hook structurally cannot see them. See "Narration and Debate" below.

## Rule 1: No Em Dash

An em dash lets a sentence sprawl instead of choosing a structure. Every use has a plainer substitute: a period for two sentences, a comma for a light break, a colon to introduce an explanation. Parentheses work for an aside; a semicolon joins two related independent clauses.

Bad: "The document flags every risk as low, that is not a finding, it is an evasion."
Good: "The document flags every risk as low. That is not a finding; it is an evasion."

This rule is absolute: zero em dashes, in any register, including a quick aside or a spoken line. If a sentence seems to need one, that is the signal to restructure the sentence, not to reach for the character.

## Rule 2: No Negative Parallelism

"It's not X, it's Y" (and its variants: "this is not X, it's Y"; "that's not X, that's Y") asserts a claim by first raising and dismissing a strawman. The construction spends a clause naming something nobody claimed, then a second clause taking credit for correcting it.

Bad: "This isn't a minor tweak, it's a fundamental rearchitecture."
Good: "This is a fundamental rearchitecture: it changes the data model every downstream FAQ depends on."

State the positive claim directly. If a contrast with an actual, attributable wrong belief is useful context, name who holds that belief and why it is wrong. Do not erect an anonymous straw version of it instead.

## Rule 3: No Corporate-Register Vocabulary

Do not write any of the following as a verb or adjective: leverage, unlock, foster, harness, navigate, elevate, seamless, robust, holistic, paradigm, cornerstone, testament, landscape, tapestry. Each signals confidence without adding a claim a reader could disagree with; the sentence reads as filler with the specific noun swapped out.

Bad: "This plugin leverages Claude's agentic capabilities to unlock deeper analysis."
Good: "This plugin uses Claude's agentic loop to run deeper analysis."

Two of these words keep a legitimate literal sense. "Leverage" is the finance noun (financial leverage, leverage ratio, operating leverage); "harness" is the noun for an agent's execution environment (test harness, coding harness, agent harness). Write either word when it names that literal thing. Never write either as a verb meaning "use."

## Rule 4: No Value-Claim Filler

A sentence that asserts its own importance, instead of stating the fact that would let a reader judge importance for themselves, is filler. Do not write: "it is important to note that," "it's important to note," "worth noting," "worth considering," "worth exploring," "worth examining," or "this matters."

Bad: "It's important to note that the TAM estimate has no cited source."
Good: "The TAM estimate has no cited source."

Delete the throat-clearing clause and start the sentence at the claim. If a fact is actually important, its content carries that weight on its own; the reader does not need to be told to notice it.

## Rule 5: No Explaining the Document to the Reader

See `common-mistakes.md`, "Explaining the Document to the Reader," for the full definition, examples, and the argument against treating any instance as a locally justified exception. That entry is the complete rule; this guide does not restate it, only places it next to the vocabulary rules it is most often confused with in review. A sentence that violates Rule 4 and Rule 5 together is the most common failure mode. "It's important to note that this section uses a future dateline" claims importance and narrates the document's own convention in the same clause.

## Narration and Debate: The Same Bar, No Safety Net

Every rule above applies with full force to text that is spoken or debated and never written to a file. Three cases matter: the persona debate that `meeting.md` synthesizes, the consensus narrative that `meeting-hive.md` synthesizes, and the playback dialogue that `meeting-listen.md` constructs from a summary. `prose_lint.py` runs against `.tex` files and `meetings/meeting-*-summary-*.md` files; it never sees a debate transcript or a spoken narration segment, because neither is written to disk before it reaches the user. This guide is the only enforcement layer for that content. A persona's spoken line that leverages a corporate synergy fails the same way a press-release paragraph would. So does a narrator segment that explains why the meeting used a particular format, and no hook downstream catches either one.

## Quick Check

Before returning any prose, whether a document section, a persona's structured response, a debate narrative, or a narration segment, scan it for:

1. Any em dash character.
2. Any "it's/this is/that's not X, it's Y" construction.
3. Any of the fourteen corporate-register words used as a verb or adjective (the finance and agent-harness nouns are exempt).
4. Any "it's important to note," "worth noting," "worth considering," "worth exploring," "worth examining," or "this matters."
5. Any sentence that explains this document's dateline, structure, or drafting history to the reader.

If a hit exists, rewrite the sentence before returning it. There is no suppression marker for narration and no linter downstream that will ever see it, so the rewrite has to happen now.
