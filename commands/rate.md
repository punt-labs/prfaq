---
description: Rate your experience with the prfaq plugin (1-5)
---

# Rate Your Experience

Send anonymous feedback to help improve the prfaq plugin. One question, one click.

## Telemetry Endpoint

Supabase REST API with insert-only RLS policy. No PII is collected.

```
URL:   https://ywikngjtcnyjrddrurhi.supabase.co/rest/v1/ratings
Key:   sb_publishable_iDt3ITGKyP_BZ5oksdgAkw_YxDIfkt0
```

**Table schema:** `anonymous_id` (text, required), `rating` (smallint 1-5, required), `version` (text), `stage` (text), `comment` (text). The `id` and `created_at` columns are auto-generated.

## Steps

1. **Read document context.** Search for `prfaq.tex` in the project root using Glob. If found, extract the version from `\prfaqversion{M}{m}` and the stage from `\prfaqstage{value}` using Grep. If no document exists, proceed without version and stage.

2. **Get or create anonymous ID.** Read `.claude/prfaq.local.md`. If it contains `anonymous_id:` in YAML frontmatter, use that value. If the file does not exist, generate a UUID via `uuidgen`, then write the file:
   ```yaml
   ---
   anonymous_id: <generated-uuid>
   ---
   ```

3. **Ask for a rating.** Prompt via AskUserQuestion:
   - Header: "Rating"
   - Question: "How is the prfaq plugin working for you?"
   - Options:
     - **5 - Excellent** — Exactly what I needed
     - **4 - Good** — Valuable, minor issues
     - **3 - Average** — Works but could be better
     - **2 - Below average** — Some value but major friction
     - **1 - Poor** — Not useful, significant problems

   If the user selects "Other", treat their text as a comment and ask for a 1-5 number separately.

4. **Ask for an optional comment.** Prompt via AskUserQuestion:
   - Header: "Feedback"
   - Question: "Any specific feedback? (optional)"
   - Options:
     - **Skip** — No comment
     - **Add comment** — I have feedback

   If they choose "Add comment" or type something via "Other", capture the text.

5. **Send the rating.** POST the JSON payload to the endpoint above via Bash. Use curl, wget, or python3 — whichever is available. The key goes in both `apikey` and `Authorization: Bearer` headers.

   If the response is `201`: "Thanks — your anonymous feedback has been recorded."

   If anything else: "Could not send feedback (network issue). Your rating was not recorded." Do not retry or debug.
