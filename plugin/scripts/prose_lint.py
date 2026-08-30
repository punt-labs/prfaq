#!/usr/bin/env python3
"""
prose_lint.py - measure LLM-speak density in prose.

Reads every term list from banlist.conf. Holds none of its own.

Exit codes:
    0   clean
    1   rationed threshold exceeded (advisory)
    2   banned term or pattern present (hard failure)
    3   usage or config error

Usage:
    prose_lint.py FILE [FILE ...]
    prose_lint.py --json FILE
    prose_lint.py --baseline FILE ...      # densities only, always exits 0
    prose_lint.py --config path/to/banlist.conf FILE

Python 3.9+ (the --json path merges dicts with `|`, PEP 584). Standard
library only. No third-party imports, deliberately, so this runs in a hook
on any machine without a virtualenv.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import NoReturn

BANNED, RATIONED, REVIEW = "banned", "rationed", "review"
EXIT_CLEAN, EXIT_RATIONED, EXIT_BANNED, EXIT_ERROR = 0, 1, 2, 3


def fatal(message: str) -> NoReturn:
    """
    Abort on a config or usage error, exiting EXIT_ERROR.

    `sys.exit(str)` prints the string and exits 1 -- which collides with
    EXIT_RATIONED, so a caller reading only the exit code cannot tell a
    malformed banlist.conf from a document that is merely over its density
    rations. Every config/usage abort in this module goes through here
    instead, so EXIT_ERROR (3) is the only exit code a config error can ever
    produce.
    """
    print(message, file=sys.stderr)
    raise SystemExit(EXIT_ERROR)

# Emoji and pictographs. Deliberately excludes ordinary punctuation and
# does not treat variation selectors alone as emoji.
EMOJI_RE = re.compile(
    "["
    "\U0001F300-\U0001F5FF"
    "\U0001F600-\U0001F64F"
    "\U0001F680-\U0001F6FF"
    "\U0001F900-\U0001F9FF"
    "\U0001FA70-\U0001FAFF"
    "\U00002600-\U000026FF"
    "\U00002700-\U000027BF"
    "\U00002B00-\U00002BFF"
    "]"
)

WEAK_VERBS = (
    "make", "makes", "made", "making",
    "provide", "provides", "provided",
    "conduct", "conducts", "conducted",
    "perform", "performs", "performed",
    "achieve", "achieves", "achieved",
    "reach", "reaches", "reached",
    "give", "gives", "gave",
    "undertake", "undertakes", "undertook",
    "is", "are", "was", "were", "be", "been",
)
NOMINALIZATION_RE = re.compile(
    r"\b(" + "|".join(WEAK_VERBS) + r")\b(?:\s+\w+){0,2}\s+"
    r"\b(\w{4,}(?:tion|tions|ment|ments|ance|ence|ity|ities|ness))\b",
    re.IGNORECASE,
)
PASSIVE_RE = re.compile(
    r"\b(?:is|are|was|were|be|been|being)\s+"
    r"(?:\w+ly\s+)?"
    r"(\w+ed|written|given|taken|made|done|seen|known|shown|held|built|"
    r"found|kept|left|sent|told|brought|thought|caught|drawn)\b",
    re.IGNORECASE,
)
# A sentence may begin with a camelCase proper noun: eCommerce, iPhone, eBay,
# macOS, gRPC. Requiring a capital immediately after the period merges two
# sentences into one and inflates the word count of the pair. Allow a
# lowercase initial only when an uppercase letter follows it, which admits
# those brand forms without splitting on ordinary lowercase continuations.
# Up to three lowercase letters before the capital, so macOS works as well as
# eCommerce, iPhone, eBay, and gRPC. The letters must be contiguous with the
# capital, which is what keeps ordinary prose ("the DNS record") from matching:
# there a space intervenes.
SENTENCE_SPLIT_RE = re.compile(
    r"(?<=[.!?])[\s\)\"']+(?=[A-Z0-9\"'\(]|[a-z]{1,3}[A-Z])|\n{2,}")
WORD_RE = re.compile(r"\b[\w'-]+\b")

# --------------------------------------------------------------------------- #
# LaTeX-aware masking
#
# Applied only when the source file is .tex (see `lint`). A markdown meeting
# summary never runs this pass, so a literal '%' in ordinary prose is left
# alone -- only LaTeX source has comment/math/macro syntax to strip.
# --------------------------------------------------------------------------- #
LATEX_COMMENT_RE = re.compile(r"(?<!\\)%.*$", re.MULTILINE)
LATEX_INLINE_MATH_RE = re.compile(r"(?<!\\)\$(?:\\.|[^$\\])*(?<!\\)\$", re.DOTALL)
LATEX_DISPLAY_MATH_RE = re.compile(r"\\\[.*?\\\]", re.DOTALL)

# Commands whose entire invocation -- name, braces, and content -- is not
# prose: citation keys, cross-reference labels, version/stage macros,
# figure paths. Blanked whole-match, same as a code fence.
LATEX_OPAQUE_COMMANDS = (
    "cite", "label", "faqref", "featureref", "ref",
    "prfaqversion", "prfaqstage", "includegraphics",
)
LATEX_OPAQUE_RE = re.compile(
    r"\\(?:" + "|".join(LATEX_OPAQUE_COMMANDS) + r")\b"
    r"(?:\s*\[[^\]\n]*\])?"
    r"(?:\s*\{[^{}]*\})+"
)

# Text-formatting commands wrap prose, they do not replace it. \texttt{},
# \textit{}, \textbf{}, and \emph{} lose their command wrapper here but keep
# the inner text as ordinary prose -- quoted and emphasized text get the same
# scrutiny as everything else, no exemption for typography.
LATEX_TEXT_COMMANDS = ("texttt", "textit", "textbf", "emph")
LATEX_TEXT_WRAP_RE = re.compile(
    r"\\(?:" + "|".join(LATEX_TEXT_COMMANDS) + r")\{([^{}]*)\}"
)

# \item and \item[(n)] are list-structure markers, not sentence starts. Used
# only by `prose_only` (see below): the marker is blanked from the
# sentence-shaped view, but the label text after it is left as prose for term
# matching -- consistent with how prose_only already treats headings and
# bullets.
LATEX_ITEM_RE = re.compile(r"\\item(?:\[[^\]\n]*\])?")

# LaTeX's code-block equivalents. verbatim/lstlisting/minted content is source
# text, not prose -- the same reason a markdown ``` fence is masked. minted
# takes a language argument (\begin{minted}{python}); the rest take none.
LATEX_VERBATIM_ENVIRONMENTS = ("verbatim\\*?", "lstlisting", "minted")
LATEX_VERBATIM_RE = re.compile(
    r"\\begin\{(" + "|".join(LATEX_VERBATIM_ENVIRONMENTS) + r")\}"
    r"(?:\[[^\]\n]*\])?(?:\{[^{}]*\})?"
    r".*?"
    r"\\end\{\1\}",
    re.DOTALL,
)


def mask_latex(text: str) -> str:
    """Blank LaTeX source syntax so only prose reaches the term/structure checks."""

    def blank(m: re.Match) -> str:
        return re.sub(r"[^\n]", " ", m.group(0))

    def blank_wrapper(m: re.Match) -> str:
        # Keep the captured inner text; blank only the command name and the
        # braces around it, so offsets stay exact and the text keeps reading
        # as prose.
        inner = m.group(1)
        prefix_len = m.start(1) - m.start(0)
        suffix_len = m.end(0) - m.end(1)
        return (" " * prefix_len) + inner + (" " * suffix_len)

    # Verbatim-like environments first: their content is not prose and must
    # not be re-interpreted by the comment/math/command passes that follow --
    # a code sample containing a literal % or $ is not a LaTeX comment or math.
    text = LATEX_VERBATIM_RE.sub(blank, text)
    text = LATEX_COMMENT_RE.sub(blank, text)
    text = LATEX_INLINE_MATH_RE.sub(blank, text)
    text = LATEX_DISPLAY_MATH_RE.sub(blank, text)
    text = LATEX_OPAQUE_RE.sub(blank, text)
    text = LATEX_TEXT_WRAP_RE.sub(blank_wrapper, text)
    return text


# --------------------------------------------------------------------------- #
# findings
# --------------------------------------------------------------------------- #
@dataclass
class Finding:
    tier: str
    rule: str
    term: str
    line: int
    col: int
    excerpt: str
    detail: str = ""

    def format(self) -> str:
        loc = f"{self.line}:{self.col}"
        head = f"  {loc:<9} {self.term}"
        if self.detail:
            head += f"  ({self.detail})"
        return f"{head}\n            {self.excerpt}"


@dataclass
class Report:
    path: str
    words: int = 0
    sentences: int = 0
    banned: list[Finding] = field(default_factory=list)
    rationed: list[Finding] = field(default_factory=list)
    review: list[Finding] = field(default_factory=list)
    densities: dict[str, float] = field(default_factory=dict)
    structure: list[Finding] = field(default_factory=list)
    suppressed: int = 0
    skipped: bool = False

    def hard_findings(self) -> list[Finding]:
        """All BANNED-tier findings, flat and structural alike.

        `structure` mixes tiers -- a structural check like `emoji = banned`
        can produce a BANNED finding there, not just in `banned`. Both
        `exit_code` and `render()` read this method so a finding can never
        again be visible in the text report but invisible to the exit code.
        """
        return self.banned + [f for f in self.structure if f.tier == BANNED]

    def soft_findings(self) -> list[Finding]:
        """All RATIONED-tier findings, flat and structural alike."""
        return self.rationed + [f for f in self.structure if f.tier == RATIONED]

    @property
    def exit_code(self) -> int:
        if self.skipped:
            return EXIT_CLEAN
        if self.hard_findings():
            return EXIT_BANNED
        if self.soft_findings():
            return EXIT_RATIONED
        return EXIT_CLEAN


# --------------------------------------------------------------------------- #
# config
# --------------------------------------------------------------------------- #
TRUTHY = {"on", "true", "yes", "1"}
FALSY = {"off", "false", "no", "0"}


def _coerce(raw: str):
    # Strip a trailing comment. Only ever applied to key = value lines, so a
    # '#' inside a regex pattern is unaffected: patterns use the :: format
    # in their own section and never pass through here.
    raw = re.split(r"\s+#", raw, maxsplit=1)[0]
    low = raw.strip().lower()
    if low in TRUTHY:
        return True
    if low in FALSY:
        return False
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        pass
    return raw.strip()


def default_config() -> Path:
    """
    Find banlist.conf without duplicating it.

    Searched in order: beside this script, then the parent directory, then
    the plugin root. When installed as a plugin the script sits in scripts/
    and the config sits at the root, and there must be exactly one copy or
    the single-source guarantee is broken.
    """
    here = Path(__file__).resolve().parent
    roots = [here, here.parent]
    env = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if env:
        roots.append(Path(env))
    for root in roots:
        candidate = root / "banlist.conf"
        if candidate.is_file():
            return candidate
    return here / "banlist.conf"      # report the expected path in the error


def load_config(path: Path) -> dict:
    """
    Parse banlist.conf.

    Sections:
      [settings]          key = value
      [banned]            one term per line
      [banned.metaphor]   one term per line
      [banned.patterns]   id :: label :: regex
      [exempt]            one phrase per line
      [rationed]          term   or   term: rate
      [review]            one term per line
    """
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        fatal(f"prose_lint: config not found: {path}")

    cfg = {
        "settings": {},
        "profiles": {},
        "banned": {"terms": [], "metaphor": [], "patterns": []},
        "exempt": {"phrases": []},
        "rationed": {"terms": [], "rates": {}},
        "review": {"terms": []},
    }
    section = None

    for lineno, raw in enumerate(lines, start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip().lower()
            known = {"settings", "banned", "banned.metaphor", "banned.patterns",
                     "exempt", "rationed", "review"}
            if section.startswith("profile."):
                cfg.setdefault("profiles", {}).setdefault(
                    section.split(".", 1)[1], {})
            elif section not in known:
                fatal(f"prose_lint: {path}:{lineno}: unknown section "
                      f"[{section}]. known: {', '.join(sorted(known))}, "
                      f"or [profile.<name>]")
            continue
        if section is None:
            fatal(f"prose_lint: {path}:{lineno}: entry outside any section")

        if section.startswith("profile."):
            if "=" not in line:
                fatal(f"prose_lint: {path}:{lineno}: expected 'key = value'")
            key, _, val = line.partition("=")
            cfg["profiles"][section.split(".", 1)[1]][key.strip()] = _coerce(val)

        elif section == "settings":
            if "=" not in line:
                fatal(f"prose_lint: {path}:{lineno}: expected 'key = value'")
            key, _, val = line.partition("=")
            cfg["settings"][key.strip()] = _coerce(val)

        elif section == "banned":
            cfg["banned"]["terms"].append(line)

        elif section == "banned.metaphor":
            cfg["banned"]["metaphor"].append(line)

        elif section == "banned.patterns":
            parts = [p.strip() for p in line.split("::")]
            if len(parts) != 3:
                fatal(f"prose_lint: {path}:{lineno}: expected "
                      f"'id :: label :: regex'")
            pid, label, rx = parts
            try:
                re.compile(rx)
            except re.error as exc:
                fatal(f"prose_lint: {path}:{lineno}: bad regex "
                      f"for '{pid}': {exc}")
            cfg["banned"]["patterns"].append(
                {"id": pid, "label": label, "regex": rx})

        elif section == "exempt":
            cfg["exempt"]["phrases"].append(line)

        elif section == "rationed":
            if ":" in line:
                term, _, rate = line.rpartition(":")
                term = term.strip()
                try:
                    cfg["rationed"]["rates"][term.lower()] = float(rate)
                except ValueError:
                    fatal(f"prose_lint: {path}:{lineno}: "
                          f"'{rate.strip()}' is not a number")
                cfg["rationed"]["terms"].append(term)
            else:
                cfg["rationed"]["terms"].append(line)

        elif section == "review":
            cfg["review"]["terms"].append(line)

    return cfg


def setting(cfg: dict, key: str, default):
    return cfg.get("settings", {}).get(key, default)


def num(cfg: dict, key: str, default: float) -> float:
    """
    Read a numeric threshold, tolerating a malformed value.

    A mistyped threshold should degrade to the default and say so, not abort
    a run halfway through a batch of files.
    """
    raw = setting(cfg, key, default)
    if isinstance(raw, bool):
        return float(default) if raw else 0.0
    try:
        return float(raw)
    except (TypeError, ValueError):
        print(f"prose_lint: warning: {key} = {raw!r} is not a number; "
              f"using {default}", file=sys.stderr)
        return float(default)


def mode_of(cfg: dict, key: str) -> str:
    """
    Normalise a tri-state setting to "off", "rationed", or "banned".
    A bare `off`/`false`/`0` in the config coerces to boolean False, so
    treat any falsy value as off.
    """
    raw = setting(cfg, key, "off")
    if raw is False or raw is None or raw == 0:
        return "off"
    if raw is True:
        return "rationed"
    text = str(raw).strip().lower()
    return text if text in {"off", "rationed", "banned"} else "off"


SEP = r"[\s\-]+"
GAP = r"(?:[\w'-]+[\s\-]+){1,3}"


def term_regex(term: str) -> re.Pattern:
    """
    Word-boundary match for a configured term.

    Hyphens and spaces are treated as the same separator, so a single
    config entry written with a hyphen also matches the spaced form and
    vice versa. The config therefore never needs both spellings.

    An asterisk matches up to three intervening words, which lets an
    exempt phrase span a gap: "read * aloud" covers "read it aloud" and
    "read the whole passage aloud".
    """
    parts = [p for p in re.split(r"[\s\-]+", term.strip()) if p]
    chunks = [GAP if p == "*" else re.escape(p) + SEP for p in parts]
    body = "".join(chunks)
    if body.endswith(SEP):
        body = body[: -len(SEP)]
    return re.compile(rf"(?<![\w-]){body}(?![\w-])", re.IGNORECASE)


# --------------------------------------------------------------------------- #
# masking
# --------------------------------------------------------------------------- #
def mask(text: str, cfg: dict, is_latex: bool = False) -> str:
    """Replace non-prose regions with spaces, preserving offsets exactly."""

    def blank(m: re.Match) -> str:
        return re.sub(r"[^\n]", " ", m.group(0))

    # HTML comments always go. Suppression markers name the very terms they
    # exempt, so linting them would report every suppression as a finding.
    text = re.sub(r"<!--.*?-->", blank, text, flags=re.DOTALL)

    # YAML frontmatter is metadata, and its --- fences are not em dashes.
    text = re.sub(r"\A---\n.*?\n---[ \t]*$", blank, text,
                  flags=re.DOTALL | re.MULTILINE)

    # Markdown table delimiter rows are pure syntax: |---|---:|. They contain
    # no prose, and their runs of hyphens otherwise read as em dashes.
    text = re.sub(r"(?m)^[ \t]*\|[ \t]*:?-{2,}:?[ \t]*(?:\|[ \t]*:?-{2,}:?[ \t]*)*\|?[ \t]*$",
                  blank, text)
    text = re.sub(r"(?m)^[ \t]*:?-{3,}:?([ \t]*\|[ \t]*:?-{3,}:?)+[ \t]*$",
                  blank, text)

    # The 4-space-indent code block and single-backtick inline-code rules are
    # markdown conventions. LaTeX uses 4-space indentation for ordinary
    # \item continuation lines, and a lone ` opens a typographic quote
    # (`` ... '' ), not a code span -- applying either rule to a .tex file
    # blanks real prose. LaTeX's own code-block equivalents (verbatim,
    # lstlisting, minted) are masked by mask_latex() below instead.
    if setting(cfg, "skip_code_blocks", True):
        text = re.sub(r"```.*?```", blank, text, flags=re.DOTALL)
        if not is_latex:
            text = re.sub(r"^(?: {4}|\t).*$", blank, text, flags=re.MULTILINE)
    if setting(cfg, "skip_inline_code", True) and not is_latex:
        text = re.sub(r"`[^`\n]+`", blank, text)
    if setting(cfg, "skip_urls", True):
        text = re.sub(r"https?://\S+", blank, text)
        text = re.sub(r"\]\([^)\n]*\)", blank, text)
    if setting(cfg, "skip_blockquotes", False):
        text = re.sub(r"^\s*>.*$", blank, text, flags=re.MULTILINE)
    if setting(cfg, "skip_tables", False):
        text = re.sub(r"^\s*\|.*$", blank, text, flags=re.MULTILINE)

    if is_latex:
        text = mask_latex(text)

    return text


def mask_exemptions(text: str, phrases: list[str]) -> str:
    """Blank out legitimate literal phrases before term matching."""
    for phrase in sorted(phrases, key=len, reverse=True):
        text = term_regex(phrase).sub(lambda m: " " * len(m.group(0)), text)
    return text


# --------------------------------------------------------------------------- #
# position helpers
# --------------------------------------------------------------------------- #
class LineIndex:
    def __init__(self, text: str):
        self.starts = [0]
        for i, ch in enumerate(text):
            if ch == "\n":
                self.starts.append(i + 1)
        self.lines = text.splitlines()

    def locate(self, offset: int) -> tuple[int, int]:
        lo, hi = 0, len(self.starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self.starts[mid] <= offset:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1, offset - self.starts[lo] + 1

    def line_text(self, lineno: int) -> str:
        return self.lines[lineno - 1] if 0 < lineno <= len(self.lines) else ""

    def excerpt(self, offset: int, width: int = 78) -> str:
        lineno, col = self.locate(offset)
        raw = self.line_text(lineno).strip()
        if len(raw) <= width:
            return raw
        start = max(0, col - width // 2)
        return ("..." if start else "") + raw[start:start + width].strip() + "..."


def suppressions(index: LineIndex, marker: str) -> dict[int, set[str]]:
    """
    Map line number -> set of suppressed ids. Empty set means suppress all.

    Two forms: `<!-- lint-ok: TERM -->` (markdown) and `% lint-ok: TERM`
    (LaTeX). A .tex file has no working suppression without the second form
    -- an HTML comment left in a .tex source is not a comment to pdflatex,
    it is literal text that would typeset into the PDF. The `%` form uses
    the same escaped-percent guard as LATEX_COMMENT_RE: `\\%` is a literal
    percent sign, not the start of a comment.
    """
    html = rf"<!--\s*{re.escape(marker)}\s*(?::\s*([^>]*?))?\s*-->"
    latex = rf"(?<!\\)%\s*{re.escape(marker)}\s*(?::\s*(.*?))?\s*$"
    pattern = re.compile(rf"{html}|{latex}")
    found: dict[int, set[str]] = {}
    for i, line in enumerate(index.lines, start=1):
        m = pattern.search(line)
        if not m:
            continue
        ids = m.group(1) if m.group(1) is not None else m.group(2)
        targets = {t.strip().lower() for t in ids.split(",")} if ids else set()
        # applies to this line and the next
        for target_line in (i, i + 1):
            found.setdefault(target_line, set())
            if targets:
                found[target_line] |= targets
    return found


def is_suppressed(sup: dict[int, set[str]], line: int, term: str) -> bool:
    if line not in sup:
        return False
    ids = sup[line]
    return not ids or term.lower() in ids


# --------------------------------------------------------------------------- #
# checks
# --------------------------------------------------------------------------- #
def prose_only(text: str) -> str:
    """
    Strip markdown and LaTeX furniture before sentence analysis.

    Headings, table rows, bare list items, and \\item markers are not
    sentences. Counting them inflates the sentence total and makes any run
    of headings look like a staccato passage. They are still linted for
    terms; this view is used only for sentence-shaped checks.
    """
    def blank(m: re.Match) -> str:
        return re.sub(r"[^\n]", " ", m.group(0))

    text = re.sub(r"^#{1,6}\s+.*$", blank, text, flags=re.MULTILINE)
    text = re.sub(r"^\s*\|.*$", blank, text, flags=re.MULTILINE)
    text = re.sub(r"^\s*[-*+]\s+\S.*$", blank, text, flags=re.MULTILINE)
    text = re.sub(r"^\s*\d+\.\s+\S.*$", blank, text, flags=re.MULTILINE)
    text = LATEX_ITEM_RE.sub(blank, text)
    return text


def sentences_of(text: str) -> list[str]:
    parts = SENTENCE_SPLIT_RE.split(text)
    out = []
    for s in parts:
        s = s.strip()
        # a fragment with no verb-bearing length is furniture, not a sentence
        if s and len(WORD_RE.findall(s)) >= 3:
            out.append(s)
    return out


def check_terms(prose, exempted, index, sup, cfg, report) -> None:
    banned_cfg = cfg.get("banned", {})
    rationed_cfg = cfg.get("rationed", {})
    review_cfg = cfg.get("review", {})
    unit = num(cfg, "density_unit", 1000)
    default_max = num(cfg, "default_max_per_1000", 0.5)
    floor = int(num(cfg, "min_occurrences_for_density", 2))
    overrides = rationed_cfg.get("rates", {})

    # tier 1: plain terms and metaphor-only terms
    for term in list(banned_cfg.get("terms", [])) + list(
        banned_cfg.get("metaphor", [])
    ):
        for m in term_regex(term).finditer(exempted):
            line, col = index.locate(m.start())
            if is_suppressed(sup, line, term):
                report.suppressed += 1
                continue
            report.banned.append(
                Finding(BANNED, "term", term, line, col, index.excerpt(m.start()))
            )

    # tier 1: patterns
    for pat in banned_cfg.get("patterns", []):
        try:
            rx = re.compile(pat["regex"])
        except re.error as exc:
            fatal(f"prose_lint: bad regex for pattern '{pat.get('id')}': {exc}")
        for m in rx.finditer(prose):
            line, col = index.locate(m.start())
            if is_suppressed(sup, line, pat["id"]):
                report.suppressed += 1
                continue
            report.banned.append(
                Finding(BANNED, "pattern", pat["id"], line, col,
                        index.excerpt(m.start()), pat.get("label", ""))
            )

    # tier 2
    scale = report.words / unit if report.words else 0.0
    for term in rationed_cfg.get("terms", []):
        hits = [m for m in term_regex(term).finditer(exempted)]
        kept = []
        for m in hits:
            line, _ = index.locate(m.start())
            if is_suppressed(sup, line, term):
                report.suppressed += 1
            else:
                kept.append(m)
        if not kept:
            continue
        rate = len(kept) / scale if scale else float(len(kept))
        report.densities[term] = round(rate, 2)
        limit = float(overrides.get(term.lower(), default_max))

        # A rate of 0.0 means "report any occurrence" and bypasses the floor.
        # Otherwise require the floor, because in a short document a single
        # use produces a high rate and a low limit becomes an accidental ban.
        if limit == 0.0:
            over = True
        else:
            over = len(kept) >= floor and rate > limit

        if over:
            m = kept[0]
            line, col = index.locate(m.start())
            detail = (f"{len(kept)}x = {rate:.1f}/{unit}w, limit {limit}"
                      if limit else f"{len(kept)}x, any use reported")
            report.rationed.append(
                Finding(RATIONED, "density", term, line, col,
                        index.excerpt(m.start()), detail)
            )

    # tier 3
    for term in review_cfg.get("terms", []):
        for m in term_regex(term).finditer(exempted):
            line, col = index.locate(m.start())
            if is_suppressed(sup, line, term):
                report.suppressed += 1
                continue
            report.review.append(
                Finding(REVIEW, "adjudicate", term, line, col,
                        index.excerpt(m.start()))
            )


def check_structure(prose, index, sup, cfg, report) -> None:
    unit = num(cfg, "density_unit", 1000)
    sents = sentences_of(prose_only(prose))
    report.sentences = len(sents)

    def add(tier, rule, term, offset, detail="", excerpt=None):
        line, col = index.locate(offset)
        if is_suppressed(sup, line, rule):
            report.suppressed += 1
            return
        report.structure.append(
            Finding(tier, rule, term, line, col,
                    excerpt if excerpt is not None else index.excerpt(offset),
                    detail)
        )

    def sentence_excerpt(s: str, width: int = 150) -> str:
        """
        Show the sentence that was measured, not a window on its line.

        A line-based excerpt starts at the finding's offset, which lands mid
        line in single-line paragraphs. A reviewer then reads the wrong span
        and rewrites the wrong sentence.
        """
        s = " ".join(s.split())
        if len(s) <= width:
            return s
        return s[: width - 20].rstrip() + " ... " + s[-15:].lstrip()

    # long sentences
    limit = num(cfg, "max_sentence_words", 30)
    if limit:
        for s in sents:
            n = len(WORD_RE.findall(s))
            if n > limit:
                off = prose.find(s[:40])
                add(RATIONED, "long-sentence", f"{n} words", max(off, 0),
                    f"limit {limit}", excerpt=sentence_excerpt(s))

    # staccato runs
    run_len = int(num(cfg, "staccato_run_length", 0))
    short = int(num(cfg, "staccato_short_words", 8))
    if run_len:
        streak, anchor = 0, None
        for s in sents:
            if len(WORD_RE.findall(s)) < short:
                streak += 1
                anchor = anchor or s
                if streak == run_len:
                    off = prose.find((anchor or s)[:40])
                    add(RATIONED, "staccato", f"{run_len} short sentences",
                        max(off, 0))
            else:
                streak, anchor = 0, None

    # passive ratio
    warn = num(cfg, "passive_ratio_warn", 0)
    if warn and sents:
        n_passive = sum(1 for s in sents if PASSIVE_RE.search(s))
        ratio = n_passive / len(sents)
        report.densities["_passive_ratio"] = round(ratio, 3)
        if ratio > warn:
            add(RATIONED, "passive-voice", f"{ratio:.0%} of sentences", 0,
                f"limit {warn:.0%}")

    # nominalizations
    nwarn = num(cfg, "nominalization_per_1000_warn", 0)
    if nwarn and report.words:
        hits = list(NOMINALIZATION_RE.finditer(prose))
        rate = len(hits) / (report.words / unit)
        report.densities["_nominalizations"] = round(rate, 2)
        if rate > nwarn:
            add(RATIONED, "nominalization", f"{rate:.1f}/{unit}w",
                hits[0].start(), f"limit {nwarn}")

    # emoji
    mode = mode_of(cfg, "emoji")
    if mode != "off":
        for m in EMOJI_RE.finditer(prose):
            add(BANNED if mode == "banned" else RATIONED, "emoji",
                m.group(0), m.start())

    # bare horizontal rules
    mode = mode_of(cfg, "hr_divider")
    if mode != "off":
        for m in re.finditer(r"^\s*(?:---+|\*\*\*+|___+)\s*$", prose,
                             re.MULTILINE):
            add(BANNED if mode == "banned" else RATIONED, "hr-divider",
                "bare --- divider", m.start())

    # Conclusion header
    mode = mode_of(cfg, "conclusion_header")
    if mode != "off":
        for m in re.finditer(r"^#{1,6}\s*conclusion\s*$", prose,
                             re.MULTILINE | re.IGNORECASE):
            add(BANNED if mode == "banned" else RATIONED, "conclusion-header",
                "Conclusion heading", m.start(),
                "second-worst measured engagement correlation")

    # Title Case headings
    mode = mode_of(cfg, "title_case_headings")
    if mode != "off":
        for m in re.finditer(r"^#{1,6}\s+(.+)$", prose, re.MULTILINE):
            words = [w for w in m.group(1).split() if w.isalpha() and len(w) > 3]
            if len(words) >= 3 and all(w[0].isupper() for w in words):
                add(RATIONED, "title-case-heading", m.group(1)[:40], m.start())


# --------------------------------------------------------------------------- #
# driver
# --------------------------------------------------------------------------- #
FILE_DIRECTIVE_RE = re.compile(r"<!--\s*lint-config:\s*([^>]+?)\s*-->")


def file_overrides(text: str, cfg: dict) -> dict:
    """
    Apply a per-file directive, if present:

        <!-- lint-config: emoji=off, skip_tables=on -->

    A document that teaches style by quoting bad examples needs this --
    `plugin/skills/prfaq/references/plain-style.md` sets `mode=off` because
    its own "Bad:" examples contain the em dashes and banned vocabulary the
    guide tells the author never to write.
    """
    m = FILE_DIRECTIVE_RE.search(text)
    if not m:
        return cfg
    local = dict(cfg)
    local["settings"] = dict(cfg.get("settings", {}))
    pairs = {}
    for pair in m.group(1).split(","):
        if "=" not in pair:
            continue
        key, _, val = pair.partition("=")
        pairs[key.strip()] = _coerce(val)

    # a named profile is applied first, so explicit keys still win
    prof = pairs.pop("profile", None)
    if prof:
        local = apply_profile(local, str(prof))
        local["settings"] = dict(local["settings"])
    local["settings"].update(pairs)
    return local


def apply_profile(cfg: dict, name: str) -> dict:
    """
    Overlay a [profile.<name>] section onto [settings].

    Registers differ in ways that are not errors. A journal article runs a
    median sentence of 28 words and about a third of its verbs in the
    passive; a memo that did the same would be unreadable. One global
    threshold cannot serve both, so thresholds are per profile.
    """
    profiles = cfg.get("profiles", {})
    if name not in profiles:
        fatal(f"prose_lint: unknown profile '{name}'. "
              f"available: {', '.join(sorted(profiles)) or 'none'}")
    local = dict(cfg)
    local["settings"] = {**cfg.get("settings", {}), **profiles[name]}
    return local


def lint(path: Path, cfg: dict) -> Report:
    text = path.read_text(encoding="utf-8")
    cfg = file_overrides(text, cfg)
    report = Report(path=str(path))

    # A catalogue of banned terms has to be able to list them. `mode=off`
    # in the file directive skips the document entirely.
    if mode_of(cfg, "mode") == "off" and "mode" in cfg.get("settings", {}):
        report.skipped = True
        return report

    is_latex = path.suffix.lower() == ".tex"
    prose = mask(text, cfg, is_latex=is_latex)
    index = LineIndex(text)
    marker = str(setting(cfg, "suppression_marker", "lint-ok"))
    sup = suppressions(index, marker)

    report.words = len(WORD_RE.findall(prose))
    exempted = mask_exemptions(prose, cfg.get("exempt", {}).get("phrases", []))

    check_terms(prose, exempted, index, sup, cfg, report)
    check_structure(prose, index, sup, cfg, report)
    return report


def render(report: Report, baseline: bool) -> str:
    out: list[str] = []
    out.append(f"\n{report.path}")
    if report.skipped:
        out.append("  skipped (lint-config: mode=off)")
        return "\n".join(out) + "\n"
    out.append(f"  {report.words} words, {report.sentences} sentences")

    if baseline:
        out.append("\n  densities (per 1000 words)")
        if not report.densities:
            out.append("    none")
        for k, v in sorted(report.densities.items(),
                           key=lambda kv: -kv[1] if isinstance(kv[1], float) else 0):
            out.append(f"    {v:>7}  {k}")
        return "\n".join(out) + "\n"

    hard = report.hard_findings()
    soft = report.soft_findings()

    if hard:
        out.append(f"\n  BANNED ({len(hard)})   zero tolerance")
        for f in sorted(hard, key=lambda f: (f.line, f.col)):
            out.append(f.format())
    if soft:
        out.append(f"\n  OVER RATION ({len(soft)})")
        for f in sorted(soft, key=lambda f: (f.line, f.col)):
            out.append(f.format())
    if report.review:
        out.append(f"\n  REVIEW ({len(report.review)})   adjudicate by eye")
        for f in sorted(report.review, key=lambda f: (f.line, f.col)):
            out.append(f.format())
    if report.suppressed:
        out.append(f"\n  {report.suppressed} finding(s) suppressed inline")
    if not (hard or soft or report.review):
        out.append("\n  clean")

    verdict = {EXIT_CLEAN: "PASS", EXIT_RATIONED: "WARN",
               EXIT_BANNED: "FAIL"}[report.exit_code]
    out.append(f"\n  {verdict}")
    return "\n".join(out) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="prose_lint",
        description="Measure LLM-speak density. All term lists live in banlist.conf.",
    )
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--config", type=Path, default=None,
                    help="default: banlist.conf beside this script")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--baseline", action="store_true",
                    help="report densities only; always exits 0 (for calibration)")
    ap.add_argument("--quiet", action="store_true",
                    help="suppress output; use the exit code only")
    ap.add_argument("--profile", default=None,
                    help="threshold profile from banlist.conf, "
                         "e.g. business or academic")
    args = ap.parse_args(argv)

    cfg_path = args.config or default_config()
    cfg = load_config(cfg_path)
    if args.profile:
        cfg = apply_profile(cfg, args.profile)

    reports: list[Report] = []
    for path in args.files:
        if not path.is_file():
            print(f"prose_lint: not a file: {path}", file=sys.stderr)
            return EXIT_ERROR
        reports.append(lint(path, cfg))

    if args.json:
        print(json.dumps(
            {"config": str(cfg_path),
             "reports": [asdict(r) | {"exit_code": r.exit_code} for r in reports]},
            indent=2))
    elif not args.quiet:
        for r in reports:
            print(render(r, args.baseline))

    if args.baseline:
        return EXIT_CLEAN
    return max((r.exit_code for r in reports), default=EXIT_CLEAN)


if __name__ == "__main__":
    sys.exit(main())
