#!/usr/bin/env python3
"""
PostToolUse hook: lint prose after Claude writes or edits a file.

Contract:
    stdin   JSON describing the tool call
    stdout  JSON: {"block": bool, "additionalContext": str}
    exit 0  always, unless the hook itself is misconfigured

Policy, which mirrors the linter's tiers:
    banned term present   -> block, and tell Claude exactly what to fix
    over a rationed rate  -> allow, inject the findings as context
    clean                 -> silent

A banned term blocks because zero tolerance means zero. A density warning
informs, because the judgement is the author's.

Scope guard, the load-bearing part of this hook. It ships installed as part
of the prfaq plugin and fires on every Write|Edit in every session where the
plugin is active -- not just sessions working on this repo. Only two file
classes are ever in scope:

    (a) a .tex file whose content contains \\prfaqversion or \\prfaqstage --
        the markers that appear only in a prfaq template or dogfood
        document, never in an arbitrary LaTeX file from an unrelated project
    (b) meetings/meeting-summary-*.md or meetings/meeting-hive-summary-*.md
        -- the meeting-persona transcripts this plugin generates

Everything else -- any other .md/.txt/.rst/.org file, a .tex file without
the prfaq markers, a vote-*.md ballot in the same meetings/ directory -- is
out of scope and passes through unlinted. An unscoped hook would block edits
to files that have nothing to do with prfaq in whatever other project the
plugin happens to be loaded in.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

# Set PRFAQ_PROSE_PROFILE to override. `strict` for anything you publish.
# Namespaced separately from plain-style's PLAIN_STYLE_PROFILE so the two
# plugins don't cross-read each other's env var if both happen to be
# installed in the same session.
PROFILE = os.environ.get("PRFAQ_PROSE_PROFILE", "business")

EXIT_CLEAN, EXIT_RATIONED, EXIT_BANNED, EXIT_ERROR = 0, 1, 2, 3

PROSE_MARKERS = ("\\prfaqversion", "\\prfaqstage")
MEETING_SUMMARY_RE = re.compile(r"^meeting-(?:hive-)?summary-.*\.md$")


def respond(block=False, context="") -> None:
    out = {"block": block}
    if context:
        out["additionalContext"] = context
    json.dump(out, sys.stdout)
    sys.exit(0)


def target_paths(payload: dict) -> list[Path]:
    """Pull file paths out of the tool input, tolerating shape changes."""
    ti = payload.get("tool_input") or payload.get("toolInput") or {}
    candidates = []
    for key in ("file_path", "filePath", "path", "notebook_path"):
        val = ti.get(key)
        if isinstance(val, str):
            candidates.append(val)
    for edit in ti.get("edits", []) or []:
        if isinstance(edit, dict) and isinstance(edit.get("file_path"), str):
            candidates.append(edit["file_path"])
    return [Path(c) for c in candidates]


def in_scope(path: Path) -> bool:
    """True only for the two file classes this hook is allowed to lint."""
    if not path.is_file():
        return False
    if path.suffix.lower() == ".tex":
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            return False
        return any(marker in content for marker in PROSE_MARKERS)
    return path.parent.name == "meetings" and bool(
        MEETING_SUMMARY_RE.match(path.name)
    )


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        respond()

    root = Path(os.environ.get("CLAUDE_PLUGIN_ROOT", Path(__file__).parent.parent))
    script = root / "scripts" / "prose_lint.py"
    config = root / "banlist.conf"
    if not script.is_file() or not config.is_file():
        respond()

    files = [p for p in target_paths(payload) if in_scope(p)]
    if not files:
        respond()

    try:
        proc = subprocess.run(
            [sys.executable, str(script), "--config", str(config),
             "--profile", PROFILE, *[str(f) for f in files]],
            capture_output=True, text=True, timeout=30,
        )
    except (subprocess.TimeoutExpired, OSError):
        respond()

    report = (proc.stdout or "").strip()

    if proc.returncode == EXIT_BANNED:
        respond(
            block=True,
            context=(
                "prose-lint found banned terms in the file you just wrote. "
                "These are zero-tolerance: the length and quality of the rest "
                "of the document do not offset them. Fix every finding below "
                "and write the file again.\n\n"
                f"{report}\n\n"
                "If an occurrence is a legitimate literal use, such as a "
                "load-bearing wall, add `<!-- lint-ok: TERM -->` on that line "
                "rather than rephrasing correct English."
            ),
        )

    if proc.returncode == EXIT_RATIONED:
        respond(
            block=False,
            context=(
                "prose-lint density warnings for the file you just wrote. "
                "Not blocking. Tighten these if you are still drafting.\n\n"
                f"{report}"
            ),
        )

    respond()


if __name__ == "__main__":
    main()
