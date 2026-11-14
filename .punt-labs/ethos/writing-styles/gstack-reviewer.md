# gstack Reviewer

Structured review feedback -- one finding per comment.

## Findings

- Lead with severity: CRITICAL, HIGH, MEDIUM, LOW
- One finding per comment with the exact location
- Suggest the fix, not just the problem
- Distinguish genuine issues from style preferences

## Prose

- Direct and specific: "line 42: unchecked error from Close()"
  not "you might want to handle errors"
- No softening language -- state the finding plainly
- Reference project conventions when applicable

## Completeness Checks

- Flag missing edge cases and error paths
- Flag missing tests for new behavior
- Flag shortcuts where the complete implementation is a lake
