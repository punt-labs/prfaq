---
description: Play back a completed meeting summary as a voiced debate between personas
argument-hint: "[path/to/meeting-summary.md]"
allowed-tools: Read, Glob, Grep
---

# PR/FAQ Meeting Listen

Play back a completed meeting summary as a voiced conversation between four personas — Wei, Priya, Alex, and Dana — each speaking in their own voice. This is post-production: the meeting already happened, you're listening to the recording.

## Prerequisites

This command requires the TTS plugin (`punt-tts`) to be installed and active in the session. Check whether `mcp__plugin_tts_vox__speak` is available. If not, tell the user: "TTS plugin is not available. Install punt-tts or run `/voice on` to enable voiced playback." and stop.

## Steps

1. **Find the meeting summary.** If `$ARGUMENTS` specifies a path, use it. Otherwise, use Glob to find `./meetings/meeting-*-summary-*.md` and `./meetings/meeting-hive-summary-*.md`. If multiple exist, pick the most recent by filename date. If none exist, tell the user: "No meeting summaries found. Run `/prfaq:meeting` or `/prfaq:meeting-hive` first."

2. **Read the meeting summary.** Load the full markdown file. Identify the format:
   - **Hive format** — has columns: `Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent`
   - **Interactive format** — has columns: `Hot Spot | Severity | Decision | Rationale`

3. **Load voice profiles.** Read the four agent files to extract voice and vibe configuration:
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-engineer.md` — Wei
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-customer.md` — Priya
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-executive.md` — Alex
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-builder.md` — Dana

   Parse the YAML frontmatter for `voice` and `voice_vibe` fields. These override the session's TTS voice and vibe for each persona's lines.

4. **Transform and voice each hot spot.** Process the decisions table row by row. For each hot spot:

   **a. Write the dialogue.** Transform the structured summary into 4-6 lines of natural conversation between personas. The personas speak to each other — no narrator, no stage directions, no attribution labels in the spoken text.

   **For hive summaries** (persona-attributed):
   - The persona named in "Winning Argument" opens with their core point, expanded into natural speech using that persona's verbal style from their agent file
   - One or two other personas react — agree, push back, or build on the point
   - If there is dissent, the dissenting persona speaks their counterargument
   - The winning persona (or another ally) closes with the decisive line
   - End with a brief consensus statement spoken by whichever persona best owns it

   **For interactive summaries** (no persona attribution):
   - Read the rationale and assign it to the most natural persona based on content:
     - Technical concerns (scaling, architecture, dependencies) → Wei
     - Customer experience concerns (onboarding, confusion, value) → Priya
     - Strategic concerns (positioning, competition, opportunity cost) → Alex
     - Scope or ambition concerns (too conservative, too complex) → Dana
   - Have 2-3 other personas react to the primary argument
   - Close with the decision

   **Dialogue guidelines:**
   - Use each persona's verbal tics naturally (Wei: "What's the denominator?", Priya: "Which of those developers am I?", Alex: "Compared to what?", Dana: "You're thinking too small.")
   - Keep each line 1-3 sentences. Spoken dialogue is shorter than written analysis.
   - The conversation should feel like overhearing a real debate, not a script reading
   - For KEEP decisions, the defending persona should sound confident; for REVISE, the challenger should sound vindicated

   **b. Voice each line.** For each line of dialogue, call `mcp__plugin_tts_vox__speak` with:
   - `text`: The dialogue line. Prepend the persona's `voice_vibe` tags if non-empty (e.g., `[slow] The denominator is missing.`). For emotionally charged lines, add situational tags:
     - Wei finding handwaving: `[frustrated]`
     - Priya losing patience with jargon: `[frustrated]`
     - Alex pattern-matching to a past failure: `[sighs]`
     - Dana seeing the bigger opportunity: `[excited]`
     - Any persona on a KEEP/vindicated moment: `[satisfied]`
   - `voice`: The persona's `voice` field from frontmatter
   - `ephemeral`: `true` (playback audio is transient)
   - Do NOT set `auto_play` to false — each line should play immediately

   **c. Print the hot spot header** before voicing its dialogue:

   ```
   --- Hot Spot N: [title] | [Decision] ---
   ```

   Wait for all lines in one hot spot to finish before moving to the next.

5. **Close the playback.** After all hot spots, print:

   ```
   --- End of meeting playback ---
   [N] hot spots | [date] | [mode]
   ```

   If the meeting had a revision queue, remind the user: "This meeting produced N revision directives. Run `/prfaq:feedback` to apply them."
