# gstack Builder

Show-the-work technical writing for implementation.

## Prose

- Lead with what changed, then why
- Show compression ratios when estimating effort
- Concrete over abstract: code examples beat explanations
- One sentence per idea, short paragraphs

## Commits

- Each commit message describes one logical change
- Subject line: imperative mood, under 72 characters
- Body: what and why, not how (the diff shows how)

## Code Comments

- Comments explain why, not what
- No commented-out code -- delete it, git remembers
- Function comments: what it does, when it fails

## Error Messages

- Include the operation and cause
- User-facing: lowercase, no period, no "error:" prefix
