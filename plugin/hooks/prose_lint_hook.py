#!/usr/bin/env python3
"""
PreToolUse hook: lint prose before Claude's Write or Edit lands on disk.

Contract, matching Claude Code's actual PreToolUse schema (verified against
the official hookify plugin's core/rule_engine.py and README, and against
Anthropic's hooks documentation):
    stdin   JSON describing the pending tool call:
            {"hook_event_name": "PreToolUse", "tool_name": "Write"|"Edit",
             "tool_input": {...}, ...}
    stdout  JSON, one of:
            deny      {"hookSpecificOutput": {"hookEventName": ...,
                       "permissionDecision": "deny",
                       "permissionDecisionReason": <text>}}
            advisory  {"hookSpecificOutput": {"hookEventName": ...,
                       "additionalContext": <text>}}
            silent    {}
    exit 0  always, unless the hook itself is misconfigured

This has to run PreToolUse, not PostToolUse: a PostToolUse hook fires after
the tool has already executed, so its "permissionDecision: deny" has
nothing left to prevent -- the file is already on disk. Only a PreToolUse
hook can stop the write from landing at all.

Reconstructing the proposed content:
    Write   tool_input["content"] IS the whole proposed file. No disk read
            is needed, and none would be correct: for a brand-new file
            there is nothing on disk yet.
    Edit    tool_input holds only old_string/new_string (and optionally
            replace_all), not the resulting file. The current on-disk
            content is read and the substitution is applied virtually, so
            a banned pattern spanning the edit boundary, or a scope marker
            (\\prfaqversion, \\prfaqstage) sitting outside the edited
            region entirely, is still visible to the checks below.

prose_lint.py's CLI takes file paths, not stdin text, so the reconstructed
content is written to a throwaway temp file (same suffix as the real path,
so .tex-aware masking still applies) before the linter runs, and deleted
immediately after. The report text has the temp path substituted back to
the real path before it reaches Claude -- nobody downstream should ever see
a temp filename.

Policy, which mirrors the linter's tiers:
    banned term present   -> deny, and tell Claude exactly what to fix
    over a rationed rate  -> allow, inject the findings as additionalContext
    clean                 -> silent

A banned term blocks because zero tolerance means zero. A density warning
informs, because the judgement is the author's.

Scope guard. This check confines the hook to files the prfaq plugin owns.
It ships installed as part of the plugin and fires on every Write|Edit in
every session where the plugin is active -- not just sessions working on
this repo. Only two file classes are ever in scope:

    (a) a .tex file whose *reconstructed proposed content* contains
        \\prfaqversion or \\prfaqstage -- the markers that appear only in a
        prfaq template or dogfood document, never in an arbitrary LaTeX
        file from an unrelated project. Checked against the reconstructed
        text, not a disk read, because a Write's target may not exist on
        disk yet and an Edit's marker may live outside the edited region.
    (b) meetings/meeting-summary-*.md or meetings/meeting-hive-summary-*.md
        -- the meeting-persona transcripts this plugin generates, matched
        on path alone since a Write's target need not exist yet either

Everything else -- any other .md/.txt/.rst/.org file, a .tex file without
the prfaq markers, a vote-*.md ballot in the same meetings/ directory -- is
out of scope and passes through unlinted. An unscoped hook would block edits
to files that have nothing to do with prfaq in whatever other project the
plugin happens to be loaded in.

Every fail-open branch below (malformed stdin, missing script/config,
unreconstructable tool input, subprocess timeout or launch failure) writes
one line to stderr before returning the silent response, so a regression
that makes the hook stop linting shows up in the transcript instead of
vanishing without a trace. The hook still never blocks Claude's pipeline on
its own infra failure -- only a genuine prose-lint finding does that.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# Set PRFAQ_PROSE_PROFILE to override. `strict` for anything you publish.
# Namespaced separately from plain-style's PLAIN_STYLE_PROFILE so the two
# plugins don't cross-read each other's env var if both happen to be
# installed in the same session.
PROFILE = os.environ.get("PRFAQ_PROSE_PROFILE", "business")

EXIT_CLEAN, EXIT_RATIONED, EXIT_BANNED, EXIT_ERROR = 0, 1, 2, 3

PROSE_MARKERS = ("\\prfaqversion", "\\prfaqstage")
MEETING_SUMMARY_RE = re.compile(r"^meeting-(?:hive-)?summary-.*\.md$")

DEFAULT_HOOK_EVENT = "PreToolUse"

# The only two tools this hook is registered against (see hooks.json's
# matcher). Anything else reaching main() -- which should not happen --
# has no reconstruction rule and is treated as out of scope.
RECONSTRUCTABLE_TOOLS = ("Write", "Edit")


def respond(hook_event: str, *, block: bool = False, reason: str = "",
            context: str = "") -> None:
    """
    Emit the PreToolUse response and exit.

    `permissionDecision: "deny"` is the only mechanism that stops the tool
    call; `additionalContext` is the non-blocking mechanism that still
    hands Claude text. The two are mutually exclusive -- a response is
    either a denial or an advisory, never both -- and an empty dict is the
    silent, clean response that lets the write proceed untouched.
    """
    out: dict = {}
    if block:
        out["hookSpecificOutput"] = {
            "hookEventName": hook_event,
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    elif context:
        out["hookSpecificOutput"] = {
            "hookEventName": hook_event,
            "additionalContext": context,
        }
    json.dump(out, sys.stdout)
    sys.exit(0)


def target_paths(payload: dict) -> list[Path]:
    """
    Pull file paths out of the tool input, tolerating shape changes.

    `tool_input` is the real key Claude Code sends; `toolInput` and a
    per-edit `file_path` are tolerated defensively in case a future Claude
    Code version or an unusual caller sends either shape, not because
    either is documented today.
    """
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


def resolve_proposed_content(tool_name: str, tool_input: dict,
                              path: Path) -> str | None:
    """
    Return the prose `path` will contain once this tool call lands, or
    None if the shape can't be reconstructed (an unsupported tool, a
    malformed tool_input, or an on-disk read failure for an Edit's
    starting point).

    Write: `tool_input["content"]` already IS the full proposed file.
    Edit: only `old_string`/`new_string` (and optional `replace_all`) are
    given; the current on-disk content is read and the substitution
    applied virtually, since Claude Code's Edit tool requires old_string
    to be unique in the file (or replace_all=true) -- the same assumption
    Claude Code itself relies on to apply the edit.
    """
    if tool_name == "Write":
        content = tool_input.get("content")
        return content if isinstance(content, str) else None

    if tool_name == "Edit":
        old_string = tool_input.get("old_string")
        new_string = tool_input.get("new_string")
        if not isinstance(old_string, str) or not isinstance(new_string, str):
            return None
        try:
            current = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            print(f"prose-lint hook: could not read {path} to reconstruct "
                  f"the pending edit, passing through: {exc}",
                  file=sys.stderr)
            return None
        if not old_string:
            return current
        if tool_input.get("replace_all"):
            return current.replace(old_string, new_string)
        return current.replace(old_string, new_string, 1)

    return None


def in_scope(path: Path, proposed_text: str | None) -> bool:
    """
    True only for the two file classes this hook is allowed to lint.

    `proposed_text` is the reconstructed post-write content, required for
    the .tex marker check: a PreToolUse hook fires before the write lands,
    so a brand-new .tex file has no on-disk content to read yet, and an
    edited file's marker may sit outside the edited region entirely. The
    meetings/ markdown check is path-only and needs no content, for the
    same reason -- a brand-new meeting summary need not exist on disk yet
    either.
    """
    if path.suffix.lower() == ".tex":
        if proposed_text is None:
            return False
        return any(marker in proposed_text for marker in PROSE_MARKERS)
    return path.parent.name == "meetings" and bool(
        MEETING_SUMMARY_RE.match(path.name)
    )


def suppression_hint(path: Path) -> str:
    """
    The working suppression directive for `path`'s file type.

    `<!-- lint-ok: TERM -->` is an HTML comment: correct for a markdown
    meeting summary, but pdflatex types it literally into the PDF of a
    .tex file. `% lint-ok: TERM` is the LaTeX-comment equivalent.
    """
    if path.suffix.lower() == ".tex":
        return "% lint-ok: TERM"
    return "<!-- lint-ok: TERM -->"


def lint_proposed_text(script: Path, config: Path, text: str, path: Path,
                       profile: str) -> subprocess.CompletedProcess:
    """
    Run prose_lint.py against `text` as if it already lived at `path`.

    prose_lint.py's CLI takes file paths, not stdin text, so the
    reconstructed content is written to a throwaway temp file sharing
    `path`'s suffix (so .tex-aware masking applies) and removed again
    immediately after. The temp path is substituted back to `path` in the
    captured stdout, so a reviewer never sees a temp filename.
    """
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=path.suffix, delete=False, encoding="utf-8",
    ) as fh:
        fh.write(text)
        tmp_path = Path(fh.name)
    try:
        proc = subprocess.run(
            [sys.executable, str(script), "--config", str(config),
             "--profile", profile, str(tmp_path)],
            capture_output=True, text=True, timeout=30,
        )
    finally:
        tmp_path.unlink(missing_ok=True)
    proc.stdout = (proc.stdout or "").replace(str(tmp_path), str(path))
    return proc


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError) as exc:
        print(f"prose-lint hook: malformed stdin JSON, passing through: {exc}",
              file=sys.stderr)
        respond(DEFAULT_HOOK_EVENT)
        return

    hook_event = payload.get("hook_event_name", DEFAULT_HOOK_EVENT)
    tool_name = payload.get("tool_name", "")

    root = Path(os.environ.get("CLAUDE_PLUGIN_ROOT", Path(__file__).parent.parent))
    script = root / "scripts" / "prose_lint.py"
    config = root / "banlist.conf"
    if not script.is_file() or not config.is_file():
        print(f"prose-lint hook: script or config missing under {root}, "
              "passing through", file=sys.stderr)
        respond(hook_event)
        return

    paths = target_paths(payload)
    if not paths:
        respond(hook_event)
        return
    path = paths[0]

    if tool_name not in RECONSTRUCTABLE_TOOLS:
        respond(hook_event)
        return

    ti = payload.get("tool_input") or payload.get("toolInput") or {}
    proposed = resolve_proposed_content(tool_name, ti, path)
    if not in_scope(path, proposed):
        respond(hook_event)
        return

    try:
        proc = lint_proposed_text(script, config, proposed, path, PROFILE)
    except subprocess.TimeoutExpired:
        print("prose-lint hook: linter timed out after 30s, passing through",
              file=sys.stderr)
        respond(hook_event)
        return
    except OSError as exc:
        print(f"prose-lint hook: failed to launch linter, passing through: {exc}",
              file=sys.stderr)
        respond(hook_event)
        return

    report = proc.stdout.strip()

    if proc.returncode == EXIT_BANNED:
        respond(
            hook_event,
            block=True,
            reason=(
                "prose-lint found banned terms in the file you are about to "
                "write. These are zero-tolerance: the length and quality of "
                "the rest of the document do not offset them. Fix every "
                "finding below and issue the write again.\n\n"
                f"{report}\n\n"
                "If an occurrence is a legitimate literal use, such as a "
                "structural wall that actually bears load, add "
                f"`{suppression_hint(path)}` on that line rather than "
                "rephrasing correct English."
            ),
        )
        return

    if proc.returncode == EXIT_RATIONED:
        respond(
            hook_event,
            context=(
                "prose-lint density warnings for the file you are about to "
                "write. Not blocking. Tighten these if you are still "
                "drafting.\n\n"
                f"{report}"
            ),
        )
        return

    if proc.returncode == EXIT_ERROR:
        stderr = (proc.stderr or "").strip()
        print(f"prose-lint hook: linter exited with a config/usage error: "
              f"{stderr}", file=sys.stderr)
        respond(
            hook_event,
            context=(
                "prose-lint could not run: a configuration or usage error in "
                "the linter itself, not a content problem with the file you "
                "are about to write. Not blocking.\n\n"
                f"{stderr}"
            ),
        )
        return

    respond(hook_event)


if __name__ == "__main__":
    main()
