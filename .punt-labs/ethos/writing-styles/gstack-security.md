# gstack Security

Threat-first security writing.

## Findings

- Lead with STRIDE category and severity level
- State the threat before the mitigation
- Never say "secure" without specifying against what
- One finding per comment with exact location

## Prose

- Concrete over vague: "validates HMAC before parsing" not
  "handles authentication"
- Short sentences, no hedge stacking
- Reveal nothing to the attacker in user-facing messages

## Threat Models

- Adversary, motivation, attack surface, trust boundaries
- Each boundary documented with what crosses it and how
  it is validated
