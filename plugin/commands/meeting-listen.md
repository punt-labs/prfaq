---
description: Play back a completed meeting summary as a voiced debate between personas
argument-hint: "[path/to/meeting-summary.md]"
allowed-tools: Read, Glob, Grep
---

# PR/FAQ Meeting Listen

Play back a completed meeting summary as a voiced conversation between four personas — Wei, Priya, Alex, and Dana — each speaking in their own voice. This is post-production: the meeting already happened, you're listening to the recording.

## Prerequisites

Check whether `mcp__plugin_vox_mic__unmute` is available. Set a session flag:
- **Voiced mode** — TTS is available. Voices will be used.
- **Text-only mode** — TTS is not available. Tell the user: "TTS plugin not available — playing back as text-only transcript. Install punt-vox for voiced playback." Continue with all steps below, but skip all `mcp__plugin_vox_mic__*` calls. Print dialogue as attributed text instead.

## Steps

1. **Find the meeting summary.** If `$ARGUMENTS` specifies a path, use it. Otherwise, use Glob to find meeting summaries with both patterns:
   - `meetings/meeting-summary-*.md` (interactive meetings)
   - `meetings/meeting-hive-summary-*.md` (hive meetings)

   Search from the user's current working directory (not the plugin root). If no results, broaden the search using `**/meetings/meeting-summary-*.md` and `**/meetings/meeting-hive-summary-*.md` to find meetings in subdirectories.

   If multiple exist, parse the `YYYY-MM-DD` date from each filename and choose the latest date. If there are multiple on the same date, choose the one with the highest numeric suffix (e.g., `...-2.md` after the unsuffixed original). If none exist, tell the user: "No meeting summaries found. Run `/prfaq:meeting` or `/prfaq:meeting-hive` first."

2. **Read the meeting summary.** Load the full markdown file. Identify the format:
   - **Hive format** — has columns: `Hot Spot | Door | Decision | Resolution | Winning Argument | Dissent`
   - **Interactive format** — has columns: `Hot Spot | Severity | Decision | Rationale`

3. **Detect TTS provider and load voice profiles.** Read the four agent files to extract voice configuration:
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-engineer.md` — Wei
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-customer.md` — Priya
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-executive.md` — Alex
   - `${CLAUDE_PLUGIN_ROOT}/agents/meeting-builder.md` — Dana

   Parse the YAML frontmatter for these fields:
   - `voice_elevenlabs` — ElevenLabs voice name (may be a custom/community voice)
   - `voice_openai` — OpenAI voice name
   - `voice_fallback` — value `default` means use the provider's default voice
   - `voice_vibe` — expressive tags (ElevenLabs only)

   **In voiced mode**, detect the active provider. Call `mcp__plugin_vox_mic__who` and read the `provider` field from the response. Select the voice field for each persona:

   | Provider | Voice Field | Vibe Tags |
   |----------|-------------|-----------|
   | `elevenlabs` | `voice_elevenlabs` | Use `voice_vibe` + situational tags |
   | `openai` | `voice_openai` | Skip all vibe tags (not supported) |
   | Any other | `voice_fallback` | Skip all vibe tags |

   When `voice_fallback` is `default`, omit the `voice` parameter entirely from unmute calls — let TTS use the provider's default voice. All four personas will share the same voice on fallback providers, but the dialogue text still differentiates them.

   **In text-only mode**, skip this step entirely.

4. **Validate ElevenLabs voices (voiced mode, ElevenLabs provider only).** The `voice_elevenlabs` values may be community voices that require the user to add them to their ElevenLabs voice library. Before voicing any hot spots:

   - Read the `all` array from the `mcp__plugin_vox_mic__who` response (this lists all voices in the user's library)
   - Check whether each persona's `voice_elevenlabs` value appears in the list
   - For any missing voices, build a fallback map using built-in ElevenLabs voices:

     | Persona | Custom Voice | Built-in Fallback |
     |---------|-------------|-------------------|
     | Wei | `yu` (community) | `george` |
     | Priya | `nila` (community) | `sarah` |
     | Alex | `bill` (built-in) | `bill` |
     | Dana | `river` (built-in) | `river` |

     `bill` and `river` are built-in ElevenLabs voices available to all users — their fallback is identity because they don't require library addition. Only `yu` and `nila` are community voices that need user action.

   - If any custom voices are missing, tell the user before starting playback:
     ```
     Note: Custom voice(s) [names] not found in your ElevenLabs library.
     Using built-in fallback(s) [names] instead.
     To use the custom voices, add them to your library at elevenlabs.io.
     ```
   - Use the fallback voice for affected personas for the rest of the playback.

5. **Transform and voice each hot spot.** Process the decisions table row by row. For each hot spot:

   **a. Normalize the decision and print the hot spot header.** The raw `Decision` cell may contain markdown formatting (`**REVISE**`) or compound values (`RESEARCH + REVISE`). Before display:

   - Strip markdown formatting (`**`, backticks, leading/trailing whitespace) to get a clean decision label.
   - Derive a canonical decision tone for dialogue guidelines:
     - Values containing "keep" (and not "revise" or "research") → **KEEP** tone
     - Values containing "revise", "research", "iterate", or "change" → **REVISE** tone
     - When ambiguous, default to **REVISE** if the value implies further work

   Print the header with the cleaned label:

   ```
   --- Hot Spot N: [title] | [cleaned Decision label] ---
   ```

   **b. Write the dialogue.** Transform the structured summary into 4-6 lines of natural conversation between personas. The personas speak to each other — no narrator, no stage directions.

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
   - For KEEP-tone decisions, the defending persona should sound confident; for REVISE-tone, the challenger should sound vindicated

   **c. Output each line.** Always print each dialogue line with a speaker label prefix for the transcript, regardless of mode:

   ```
   **Wei:** The denominator is missing entirely.
   **Priya:** Which of those developers am I?
   ```

   **In voiced mode**, after printing all dialogue lines for the hot spot, make a single `mcp__plugin_vox_mic__unmute` call with:
   - `ephemeral`: `true`
   - `segments`: An array starting with a **narrator segment**, then one segment per dialogue line:

     **Narrator segment** (first in array):
     - `text`: A scene-setter that orients the listener. Synthesize from the summary row:
       - Name the hot spot and which part of the document it concerns
       - For hive summaries: mention the door and the core tension from the resolution
       - For interactive summaries: mention the severity and the gist of the rationale
       - End with the decision outcome so the listener knows the frame
       - Example: "Hot spot 3: Pricing model, in the customer FAQ section. The team debated whether per-seat pricing alienates small teams. They decided to revise."
     - Keep it to 2-3 sentences — enough context to follow the debate, not a full recap
     - Omit `voice` — uses the session default, naturally distinguishing the narrator from persona voices
     - Omit `vibe_tags`

     **Dialogue segments** (one per line):
     - `text`: The dialogue line text only (without the speaker label — labels are for reading, not speaking)
     - `voice`: The resolved voice for this persona (from step 3/4)
     - `vibe_tags` (ElevenLabs only): The persona's `voice_vibe` value. For emotionally charged lines, use situational tags instead:
       - Wei finding handwaving: `[frustrated]`
       - Priya losing patience with jargon: `[frustrated]`
       - Alex pattern-matching to a past failure: `[sighs]`
       - Dana seeing the bigger opportunity: `[excited]`
       - Any persona on a KEEP/vindicated moment: `[satisfied]`
     - For non-ElevenLabs providers: omit `vibe_tags` from segments entirely. Do NOT prepend tags to the text — they will be spoken literally.

   Example (ElevenLabs):
   ```
   unmute(
       ephemeral: true,
       segments: [
           {"text": "Hot spot 3: Pricing model, in the customer FAQ section. The team debated whether per-seat pricing alienates small teams. They decided to revise."},
           {"voice": "yu", "text": "The denominator is missing.", "vibe_tags": "[slow]"},
           {"voice": "nila", "text": "Which of those developers am I?", "vibe_tags": "[frustrated]"},
           {"voice": "bill", "text": "Compared to what?", "vibe_tags": "[sighs]"},
           {"voice": "river", "text": "You're thinking too small.", "vibe_tags": "[excited]"}
       ]
   )
   ```

   **In text-only mode**, just print the labeled lines. No TTS calls.

6. **Close the playback.** After all hot spots, print:

   ```
   --- End of meeting playback ---
   [N] hot spots | [date] | [mode]
   ```

   If the meeting had a revision queue, remind the user: "This meeting produced N revision directives. Run `/prfaq:feedback` to apply them."
