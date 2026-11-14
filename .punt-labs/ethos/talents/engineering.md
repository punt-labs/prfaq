# Engineering

Systems design in Go and Python. Correctness over speed.

## Go

- Go 1.26+, internal/ for everything, no interface{}/any unless unavoidable
- Table-driven tests with testify/assert and testify/require
- Errors are values — wrap with fmt.Errorf("context: %w", err)
- No panics in library code
- Race detection mandatory on all test runs

## Python

- Punt Labs Python standards: ruff, mypy strict, pytest
- uv for dependency management, pyproject.toml for config
- Type annotations on all public functions
- Stdlib-only helpers for hot paths (hook startup, CLI dispatch)

## Cross-Cutting

- Shell scripting (bash, shellcheck, POSIX-compatible where possible)
- CI/CD pipeline design (GitHub Actions, quality gates)
- MCP server and plugin development
- Non-blocking I/O patterns for hook handlers
