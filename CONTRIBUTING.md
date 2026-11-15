# Contributing to prfaq

The development process (issue, branch, local review, pull request) is in [docs/WORKFLOW.md](docs/WORKFLOW.md). Read it before you change anything. Every change lands on `main` through a merged pull request.

## Quality gates

All three gates must pass before every commit. Run them together:

```bash
make check
```

`make check` runs the three targets below. Run one on its own when you only need that gate.

Compile every `.tex` file in `TEX_DIRS` (`.`, `plugin/assets`, `docs`) to a valid PDF. This needs a TeX distribution with `pdflatex`:

```bash
make test
```

`make test` is an alias for `make prfaq`. The target compiles every `.tex` file present in those directories, tracked or not, so keep scratch `.tex` files in `.tmp/`.

To compile one file on its own:

```bash
bash plugin/scripts/compile_prfaq.sh path/to/file.tex
```

Test the permission script (`plugin/scripts/prfaq_permissions.sh`) and check that `install.sh` leaves `~/.claude/settings.json` untouched. This needs `jq`:

```bash
make test-perms
```

Test the prose scanner (`plugin/scripts/prose_lint.py`) and its `PreToolUse` hook:

```bash
make test-prose
```

Markdown files are linted in CI with markdownlint-cli2. To run the same check locally:

```bash
npx markdownlint-cli2 "**/*.md"
```

## Scratch files

Put scratch and temporary files in `.tmp/` at the repository root, not `/tmp`. Its contents are gitignored.

## Changelog

The changelog follows [Keep a Changelog](https://keepachangelog.com/). Add the entry for a user-facing change in the same pull request as the change, under `[Unreleased]`.
