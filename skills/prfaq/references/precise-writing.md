# Precise Writing for PR/FAQ Documents

*Adapted from Vervago's Precision Q+A framework and Amazon's "Write Like an Amazonian"*

This guide defines the editorial standard for PR/FAQ documents. The streamline agent uses these rules. Human authors should internalize them.

## Core Rule

Every sentence earns its place or gets cut. The document does not repeat things because they are important — it makes what remains important by removing what is not.

## What to Cut

### Redundancy Across Sections

The most common bloat in iterated PR/FAQ documents. Claims repeated across multiple FAQs, the press release restating what the solution section already said, or the same evidence cited in three different answers. Each fact appears once, in its most natural location.

**Test:** Search for the same noun phrase or data point across sections. If it appears more than once, keep the strongest instance and cut or compress the others to a cross-reference ("see Q14" or simply delete).

### Weasel Words

These create the impression of meaning without substance:

- "significantly better" — better by how much?
- "nearly all customers" — what percentage?
- "in many cases" — which cases?
- "quite impressive" — by what measure?
- "arguably the best" — who argues?
- "a large majority" — what number?

When you encounter these, either replace with data or delete the sentence.

### Hollow Adjectives and Adverbs

Adjectives are imprecise. Replace with data:

- "much faster" → "3x faster" or a specific latency number
- "significantly improved" → "improved 23%"
- "very large" → the actual number
- "recently" → the actual date

### Hedge Stacking

One hedge per claim is honest. Two or more is evasion:

- "It might possibly perhaps be the case..." → "This might..."
- "We believe it is likely that this could potentially..." → "We believe this will..." or "This might..."

Pick the hedge that matches your actual confidence and commit.

### Inflated Phrases

| Cut | Replace with |
|-----|-------------|
| "Due to the fact that" | "Because" |
| "In order to" | "To" |
| "At this point in time" | "Now" |
| "In the event that" | "If" |
| "Has the capability to" | "Can" |
| "It is important to note that" | *(delete entirely)* |
| "It is worth noting that" | *(delete entirely)* |
| "The question is whether" | *(rephrase as direct statement)* |

### Throat-Clearing Sentences

Opening sentences that delay the actual point:

- "There are several factors to consider here."
- "This is a complex question that requires careful analysis."
- "Before we address this, it's important to understand..."

Delete the opener. Start with the substance.

### The "So What" Test

Every statement must survive this: if a reader could respond "so what?", the statement needs data or should be cut.

- "Performance improved significantly." → So what? By how much?
- "This is an important consideration." → So what? Why?
- "The market is large and growing." → So what? How large? Growing at what rate?

## What to Preserve

These elements are untouchable:

- **Evidence and citations** — `\cite{}` references, survey data, financial figures
- **Customer quotes** — `\begin{customerquote}` blocks
- **Risk assessments** — pre-mortem scenarios, risk ratings, mitigation plans
- **Numbers and metrics** — targets, costs, timelines, percentages
- **Structural elements** — section headers, FAQ pair boundaries, environment commands
- **Distinctive voice** — the document's perspective and argumentative stance

The streamliner removes mass, not meaning. If cutting a sentence changes the document's argument, keep the sentence.

## Calibrated Language

Match language to actual confidence:

| Confidence | Language |
|------------|----------|
| Verified/Tested | "This works." "This is correct." |
| High confidence | "This should work." "This will likely..." |
| Moderate confidence | "This might work." "One approach would be..." |
| Speculation | "I suspect..." "It's possible that..." |
| Unknown | "I don't know, but..." |

A PR/FAQ at **hypothesis** stage should use moderate-confidence language for unvalidated claims. A PR/FAQ at **validated** stage can use high-confidence language where evidence supports it.

## Sentence Length

Target: under 30 words per sentence. Long sentences usually contain two ideas that should be two sentences, or one idea plus a qualification that should be cut.

## Output Standard

After streamlining, the document should be:
- 10–20% shorter by word count
- Zero redundant claims across sections
- Zero weasel words without backing data
- Zero inflated phrases where a shorter form exists
- Every sentence passing the "so what" test
