#!/usr/bin/env python3
"""
Tests for prose_lint and its PreToolUse hook. Standard library unittest,
no dependencies.

Run:  python3 tests/test_prose_lint.py
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "plugin" / "scripts"))
sys.path.insert(0, str(REPO_ROOT / "plugin" / "hooks"))

import prose_lint as pl  # noqa: E402 -- path must be extended first
import prose_lint_hook as hook  # noqa: E402 -- path must be extended first

# Resolved the same way the linter resolves it, so the suite passes both
# standalone and in the plugin layout where the config sits one level up.
CONFIG = pl.default_config()


def lint_text(text: str, cfg=None) -> pl.Report:
    cfg = cfg or pl.load_config(CONFIG)
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False,
                                     encoding="utf-8") as fh:
        fh.write(text)
        path = Path(fh.name)
    try:
        return pl.lint(path, cfg)
    finally:
        path.unlink()


def lint_tex(text: str, cfg=None) -> pl.Report:
    """Same as lint_text, but with a .tex suffix so LaTeX-aware masking runs."""
    cfg = cfg or pl.load_config(CONFIG)
    with tempfile.NamedTemporaryFile("w", suffix=".tex", delete=False,
                                     encoding="utf-8") as fh:
        fh.write(text)
        path = Path(fh.name)
    try:
        return pl.lint(path, cfg)
    finally:
        path.unlink()


def terms(findings) -> set[str]:
    return {f.term for f in findings}


class TestBannedTier(unittest.TestCase):
    def test_banned_term_fails_regardless_of_length(self):
        short = lint_text("The torpedo alert is here.")
        long = lint_text("Filler sentence. " * 400 + "The torpedo alert is here.")
        self.assertEqual(short.exit_code, pl.EXIT_BANNED)
        self.assertEqual(long.exit_code, pl.EXIT_BANNED)

    def test_single_occurrence_is_enough(self):
        r = lint_text("This assumption is load-bearing.")
        self.assertIn("load-bearing", terms(r.banned))
        self.assertEqual(r.exit_code, pl.EXIT_BANNED)

    def test_hyphen_and_space_variants_both_caught(self):
        hyphen = lint_text("The plan is load-bearing for the whole team.")
        self.assertIn("load-bearing", terms(hyphen.banned))
        spaced = lint_text("that is load bearing here")
        self.assertIn("load-bearing", terms(spaced.banned))

    def test_case_insensitive(self):
        r = lint_text("Load-Bearing and DELVE and Torpedo Alert.")
        self.assertGreaterEqual(len(r.banned), 3)

    def test_reports_line_and_column(self):
        r = lint_text("clean line\nanother clean line\nthis one delves in\n")
        f = next(f for f in r.banned if f.term == "delves")
        self.assertEqual(f.line, 3)
        self.assertEqual(f.col, 10)


class TestExemptions(unittest.TestCase):
    """The false-positive cases. These matter more than the true positives."""

    def test_literal_load_bearing_wall_is_allowed(self):
        r = lint_text("We removed a load-bearing wall during the renovation.")
        self.assertNotIn("load-bearing", terms(r.banned))
        self.assertEqual(r.exit_code, pl.EXIT_CLEAN)

    def test_metaphorical_use_still_caught_in_same_document(self):
        r = lint_text(
            "We removed a load-bearing wall.\n"
            "That assumption is load-bearing for the argument.\n"
        )
        hits = [f for f in r.banned if f.term == "load-bearing"]
        self.assertEqual(len(hits), 1)
        self.assertEqual(hits[0].line, 2)

    def test_literal_out_loud_allowed(self):
        r = lint_text("She read the passage out loud to the class.")
        self.assertNotIn("out loud", terms(r.banned))

    def test_move_the_file_is_allowed(self):
        r = lint_text("Move the file into the archive directory.")
        self.assertNotIn("move", terms(r.banned))


class TestMasking(unittest.TestCase):
    def test_code_fence_is_not_linted(self):
        r = lint_text("Clean prose here.\n\n```\nload-bearing delve seam\n```\n")
        self.assertEqual(r.banned, [])
        self.assertEqual(r.exit_code, pl.EXIT_CLEAN)

    def test_inline_code_is_not_linted(self):
        r = lint_text("Call the `load-bearing` helper function.")
        self.assertEqual(r.banned, [])

    def test_urls_are_not_linted(self):
        r = lint_text("See https://example.com/delve-into-things for detail.")
        self.assertEqual(r.banned, [])

    def test_masking_preserves_line_numbers(self):
        r = lint_text("```\ncode\n```\nthis delves deep\n")
        f = next(f for f in r.banned if f.term == "delves")
        self.assertEqual(f.line, 4)


class TestSuppression(unittest.TestCase):
    def test_bare_marker_suppresses_whole_line(self):
        r = lint_text("This is load-bearing. <!-- lint-ok -->")
        self.assertEqual(r.banned, [])
        self.assertEqual(r.suppressed, 1)

    def test_targeted_marker_suppresses_only_that_term(self):
        r = lint_text("This load-bearing thing delves deep. "
                      "<!-- lint-ok: load-bearing -->")
        self.assertNotIn("load-bearing", terms(r.banned))
        self.assertIn("delves", terms(r.banned))

    def test_marker_on_preceding_line_applies(self):
        r = lint_text("<!-- lint-ok: load-bearing -->\nThis is load-bearing.\n")
        self.assertEqual(r.banned, [])

    def test_pattern_suppressed_by_id(self):
        r = lint_text("It's not a bug, it's a feature. <!-- lint-ok: not-x-but-y -->")
        self.assertNotIn("not-x-but-y", terms(r.banned))


class TestPatterns(unittest.TestCase):
    def test_negative_parallelism(self):
        r = lint_text("It's not a tool, it's a platform.")
        self.assertIn("not-x-but-y", terms(r.banned))

    def test_negative_parallelism_with_full_subject_clause(self):
        """
        A real agent under real cognitive load produced this exact shape
        during verification: the pronoun-led pattern above only matches
        "it's/this/that is not X, it's Y" and missed the semantically
        identical pivot with a full noun-phrase subject standing in for
        the pronoun.
        """
        r = lint_text(
            "Six months post-launch with zero structured trials is not "
            '"medium risk," it\'s six months of runway spent on a bet '
            "nobody stress-tested.")
        self.assertIn("not-x-but-y-subject", terms(r.banned))

    def test_not_x_but_y_subject_does_not_catch_ordinary_sentence(self):
        """
        A widened version of this pattern, added earlier, matched ordinary
        correct English whenever "is not" was later followed anywhere by an
        "it's/it is" clause -- including across a subordinating conjunction
        like "so". Tightened to require the pivot land directly on the far
        side of the nearest comma.
        """
        r = lint_text(
            "The install path is not documented anywhere, so it is hard "
            "to say what happens.")
        self.assertNotIn("not-x-but-y-subject", terms(r.banned))
        r2 = lint_text(
            "The output format is not specified, because it is left to "
            "the caller to decide.")
        self.assertNotIn("not-x-but-y-subject", terms(r2.banned))

    def test_not_only_but_also_is_not_a_hard_ban(self):
        """
        Demoted from tier 1 by the calibration run. The baseline paper uses
        the construction legitimately to coordinate two objects, and no
        regex separates that from the rhetorical pivot. Reported, not failed.
        """
        r = lint_text("It not only saves time but also reduces errors.")
        self.assertEqual(r.banned, [])
        self.assertNotEqual(r.exit_code, pl.EXIT_BANNED)

    def test_legitimate_coordination_does_not_fail(self):
        r = lint_text(
            "Prosocial individuals consider not only their own gains "
            "but also the gains of others.")
        self.assertEqual(r.banned, [])
        self.assertNotEqual(r.exit_code, pl.EXIT_BANNED)

    def test_em_dash(self):
        r = lint_text("The result — surprisingly — held up.")
        self.assertIn("em-dash", terms(r.banned))

    def test_latex_source_em_dash(self):
        """
        A rendered PDF shows the character; the source shows ---. Linting
        only the character means a LaTeX draft passes and the PDF fails.
        """
        r = lint_text("The result---surprisingly---held up.")
        self.assertIn("em-dash-source", terms(r.banned))

    def test_latex_macro_em_dash(self):
        r = lint_text(r"The claim\textemdash{}that it works\textemdash{}is untested.")
        self.assertIn("em-dash-macro", terms(r.banned))

    def test_latex_source_em_dash_spaced_form(self):
        """
        prfaq.tex itself uses only the spaced ` --- ` convention, never the
        tight word---word form -- a rule that only recognizes the tight form
        never fires on this project's actual documents.
        """
        r = lint_text("Our assumption --- consistent with the evidence --- holds.")
        self.assertIn("em-dash-source", terms(r.banned))

    def test_latex_en_dash(self):
        r = lint_text("A range of word--word items.")
        self.assertIn("en-dash-source", terms(r.banned))

    def test_latex_en_dash_numeric_range_is_not_a_finding(self):
        """
        LaTeX's own convention for a numeric range (100--200, \\$1.5--2
        trillion) uses two hyphens. That is not a broken en dash; the rule
        only fires when both sides are letters.
        """
        r = lint_text("Enterprises carry \\$1.5--2 trillion in debt, "
                      "recruiting 10--20 target users across 100--200K rows.")
        self.assertNotIn("en-dash-source", terms(r.banned))

    def test_ordinary_hyphen_is_not_a_dash(self):
        r = lint_text("A command-line tool with well-formed hyphens is fine.")
        self.assertEqual(r.banned, [])

    def test_markdown_table_delimiter_is_not_an_em_dash(self):
        r = lint_text("| Term | Meaning |\n|---|---|\n| alpha | beta |\n")
        self.assertEqual(r.banned, [])

    def test_aligned_table_delimiter_is_not_an_em_dash(self):
        r = lint_text("| A | B |\n|:---|---:|\n| x | y |\n")
        self.assertEqual(r.banned, [])

    def test_yaml_frontmatter_fence_is_not_an_em_dash(self):
        r = lint_text("---\nname: thing\ndescription: a thing\n---\n\nPlain prose.\n")
        self.assertEqual(r.banned, [])

    def test_cli_flag_is_not_an_en_dash(self):
        r = lint_text("Run the tool with --profile business to select limits.")
        self.assertEqual(r.banned, [])

    def test_markdown_divider_is_not_an_em_dash(self):
        r = lint_text("text here\n\n---\n\nmore text\n")
        self.assertNotIn("em-dash-source", terms(r.banned))
        self.assertTrue(any(f.rule == "hr-divider" for f in r.structure))

    def test_whole_x_construction_with_novel_noun(self):
        r = lint_text("That is the whole lesson of the exercise.")
        self.assertIn("whole-x", terms(r.banned))

    def test_whole_world_is_exempted_from_pattern(self):
        r = lint_text("It changed the whole world.")
        self.assertNotIn("whole-x", terms(r.banned))


class TestMetaExplainsConvention(unittest.TestCase):
    """The pattern added for this port: metacommentary that narrates the
    document's own status to the reader instead of just being the document."""

    def test_is_aspirational_is_banned(self):
        r = lint_text("This document is aspirational in places.")
        self.assertIn("meta-explains-convention", terms(r.banned))

    def test_marks_aspirational_is_banned(self):
        r = lint_text("This section marks aspirational goals for the team.")
        self.assertIn("meta-explains-convention", terms(r.banned))

    def test_written_from_today_is_banned(self):
        r = lint_text("This section is written from today.")
        self.assertIn("meta-explains-convention", terms(r.banned))

    def test_reports_retrospectively_is_banned(self):
        r = lint_text("The team reports retrospectively on outcomes here.")
        self.assertIn("meta-explains-convention", terms(r.banned))

    def test_reader_should_note_is_banned(self):
        r = lint_text("The reader should note that plans changed.")
        self.assertIn("meta-explains-convention", terms(r.banned))

    def test_ordinary_prose_is_not_flagged(self):
        r = lint_text("The plan changed after launch, based on real usage.")
        self.assertNotIn("meta-explains-convention", terms(r.banned))


class TestRationedTier(unittest.TestCase):
    def test_low_density_passes(self):
        text = "Filler words here. " * 200 + "A robust solution."
        r = lint_text(text)
        self.assertEqual([f.term for f in r.rationed], [])

    def test_high_density_warns_not_fails(self):
        text = "The robust robust robust robust system works."
        r = lint_text(text)
        self.assertIn("robust", terms(r.rationed))
        self.assertEqual(r.exit_code, pl.EXIT_RATIONED)

    def test_density_is_normalised_by_length(self):
        one = lint_text("The realm of it. " + "filler " * 50)
        self.assertIn("realm", r_terms := terms(one.rationed))
        self.assertTrue(r_terms)

    def test_rationed_never_returns_banned_code(self):
        r = lint_text("underscore " * 20)
        self.assertNotEqual(r.exit_code, pl.EXIT_BANNED)


class TestReviewTier(unittest.TestCase):
    def test_review_terms_never_fail(self):
        r = lint_text("The risk lives in the handoff and the tell is quiet.")
        self.assertTrue(r.review)
        self.assertEqual(r.exit_code, pl.EXIT_CLEAN)

    def test_review_terms_are_reported(self):
        r = lint_text("We should surface the insight.")
        self.assertIn("surface", terms(r.review))


class TestStructure(unittest.TestCase):
    def test_long_sentence_warns(self):
        long = "This sentence " + "keeps going and going " * 8 + "forever."
        r = lint_text(long)
        self.assertTrue(any(f.rule == "long-sentence" for f in r.structure))

    def test_short_sentences_pass(self):
        r = lint_text("Short. Also short. Fine here.")
        self.assertFalse(any(f.rule == "long-sentence" for f in r.structure))

    def test_hr_divider_detected(self):
        r = lint_text("Some prose.\n\n---\n\nMore prose.\n")
        self.assertTrue(any(f.rule == "hr-divider" for f in r.structure))

    def test_conclusion_header_detected(self):
        r = lint_text("# Title\n\ntext\n\n## Conclusion\n\nmore\n")
        self.assertTrue(any(f.rule == "conclusion-header" for f in r.structure))

    def test_emoji_detected(self):
        r = lint_text("This works \U0001F600 well.")
        self.assertTrue(any(f.rule == "emoji" for f in r.structure))

    def test_word_count_excludes_code(self):
        r = lint_text("one two three\n\n```\nfour five six seven eight\n```\n")
        self.assertEqual(r.words, 3)


class TestExitCodes(unittest.TestCase):
    def test_clean_is_zero(self):
        self.assertEqual(lint_text("A plain sentence about nothing.").exit_code, 0)

    def test_banned_beats_rationed(self):
        r = lint_text("A robust robust robust delve into things.")
        self.assertEqual(r.exit_code, pl.EXIT_BANNED)

    def test_main_returns_worst_code_across_files(self):
        with tempfile.TemporaryDirectory() as d:
            clean = Path(d) / "clean.md"
            dirty = Path(d) / "dirty.md"
            clean.write_text("A plain sentence.", encoding="utf-8")
            dirty.write_text("A torpedo alert here.", encoding="utf-8")
            code = pl.main(["--quiet", "--config", str(CONFIG),
                            str(clean), str(dirty)])
        self.assertEqual(code, pl.EXIT_BANNED)

    def test_baseline_always_exits_zero(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "dirty.md"
            f.write_text("A torpedo alert and a delve.", encoding="utf-8")
            code = pl.main(["--baseline", "--quiet", "--config", str(CONFIG),
                            str(f)])
        self.assertEqual(code, pl.EXIT_CLEAN)


class TestMarkdownFurniture(unittest.TestCase):
    """Headings and list items are not sentences."""

    def test_headings_not_counted_as_sentences(self):
        r = lint_text("# One\n\n## Two\n\n### Three\n\n#### Four\n")
        self.assertEqual(r.sentences, 0)

    def test_heading_run_is_not_staccato(self):
        r = lint_text("## Part I\n\n## Part II\n\n## Part III\n\n## Part IV\n")
        self.assertFalse(any(f.rule == "staccato" for f in r.structure))

    def test_headings_are_still_linted_for_terms(self):
        r = lint_text("## The load-bearing section\n")
        self.assertIn("load-bearing", terms(r.banned))

    def test_list_items_not_counted_as_sentences(self):
        r = lint_text("- alpha beta gamma\n- delta epsilon zeta\n")
        self.assertEqual(r.sentences, 0)


class TestSentenceSplitting(unittest.TestCase):
    """Found by a real review: two sentences were being counted as one."""

    def test_camelcase_proper_noun_starts_a_new_sentence(self):
        r = lint_text("Load rises during surges. eCommerce systems are slow.")
        self.assertEqual(r.sentences, 2)

    def test_camelcase_variants(self):
        for word in ("iPhone", "eBay", "macOS", "gRPC"):
            r = lint_text(f"The first claim holds. {word} behaves differently.")
            self.assertEqual(r.sentences, 2, f"failed on {word}")

    def test_ordinary_lowercase_does_not_split(self):
        # A decimal or an abbreviation must not create a phantom sentence.
        r = lint_text("The rate was 3.5 percent across every measured cohort.")
        self.assertEqual(r.sentences, 1)

    def test_merged_sentences_no_longer_inflate_length(self):
        text = ("Caching protects the backend during traffic surges. "
                "eCommerce search systems run expensive operations underneath "
                "a simple query box for every single incoming request.")
        r = lint_text(text)
        longest = [f for f in r.structure if f.rule == "long-sentence"]
        self.assertEqual(longest, [], "merged pair reported as one long sentence")


class TestFindingExcerpts(unittest.TestCase):
    def test_long_sentence_excerpt_is_the_sentence_not_the_line(self):
        long = "Alpha beta " + "gamma delta epsilon zeta eta theta " * 6 + "end."
        text = "Short opener here. " + long
        r = lint_text(text)
        f = next(x for x in r.structure if x.rule == "long-sentence")
        self.assertTrue(f.excerpt.startswith("Alpha beta"),
                        f"excerpt began mid-sentence: {f.excerpt[:60]!r}")
        self.assertNotIn("Short opener", f.excerpt)


class TestFileDirective(unittest.TestCase):
    """A guide that teaches style must be able to quote bad examples."""

    def test_emoji_can_be_disabled_per_file(self):
        with_directive = lint_text(
            "<!-- lint-config: emoji=off -->\nGood \U0001F600 example.")
        without = lint_text("Good \U0001F600 example.")
        self.assertFalse(any(f.rule == "emoji" for f in with_directive.structure))
        self.assertTrue(any(f.rule == "emoji" for f in without.structure))

    def test_mode_off_skips_document_entirely(self):
        r = lint_text("<!-- lint-config: mode=off -->\n"
                      "A torpedo alert and a delve and an em dash — here.")
        self.assertTrue(r.skipped)
        self.assertEqual(r.banned, [])
        self.assertEqual(r.exit_code, pl.EXIT_CLEAN)

    def test_directive_does_not_leak_to_other_files(self):
        cfg = pl.load_config(CONFIG)
        skipped = lint_text("<!-- lint-config: mode=off -->\nA delve.", cfg=cfg)
        normal = lint_text("A delve.", cfg=cfg)
        self.assertTrue(skipped.skipped)
        self.assertFalse(normal.skipped)
        self.assertIn("delve", terms(normal.banned))

    def test_multiple_overrides_parsed(self):
        r = lint_text("<!-- lint-config: emoji=off, hr_divider=off -->\n"
                      "text \U0001F600\n\n---\n\nmore text\n")
        rules = {f.rule for f in r.structure}
        self.assertNotIn("emoji", rules)
        self.assertNotIn("hr-divider", rules)


class TestSingleSourcing(unittest.TestCase):
    """The design requirement: no term list may be hardcoded in the script."""

    def test_adding_a_ban_requires_only_config(self):
        cfg = pl.load_config(CONFIG)
        cfg["banned"]["terms"].append("flibbertigibbet")
        r = lint_text("A flibbertigibbet appeared.", cfg=cfg)
        self.assertIn("flibbertigibbet", terms(r.banned))

    def test_no_prose_terms_in_source(self):
        src = Path(pl.__file__).read_text(encoding="utf-8").lower()
        for term in ("torpedo", "load-bearing", "delve", "tapestry", "meticulous"):
            self.assertNotIn(term, src, f"{term!r} is hardcoded in prose_lint.py")

    def test_promoting_between_tiers_changes_severity(self):
        cfg = pl.load_config(CONFIG)
        cfg["review"]["terms"].remove("surface")
        cfg["banned"]["terms"].append("surface")
        r = lint_text("We will surface the finding.", cfg=cfg)
        self.assertEqual(r.exit_code, pl.EXIT_BANNED)


class TestLatexCommentMasking(unittest.TestCase):
    def test_comment_masks_rest_of_line(self):
        tex = ("First line is fine. % this delve should be hidden\n"
               "Second line has a delve.\n")
        r = lint_tex(tex)
        hits = [f for f in r.banned if f.term == "delve"]
        self.assertEqual(len(hits), 1)
        self.assertEqual(hits[0].line, 2)

    def test_escaped_percent_is_not_a_comment(self):
        tex = "The rate is 50\\% and this delve stays visible.\n"
        r = lint_tex(tex)
        self.assertIn("delve", terms(r.banned))


class TestLatexMathMasking(unittest.TestCase):
    def test_inline_math_is_masked(self):
        tex = "Clean prose here. $delve_x + 2$ more clean prose.\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))

    def test_display_math_is_masked(self):
        tex = "Clean prose.\n\\[\n\\text{delve} = 1\n\\]\nMore clean prose.\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))


class TestLatexOpaqueCommands(unittest.TestCase):
    def test_cite_label_ref_are_blanked(self):
        tex = "See \\cite{delve2020} and \\label{sec:delve} and \\ref{sec:delve}.\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))

    def test_faqref_and_featureref_are_blanked(self):
        tex = "See \\faqref{delve} and \\featureref{delve}.\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))

    def test_prfaqversion_and_prfaqstage_are_blanked(self):
        tex = "\\prfaqversion{delve}{delve} \\prfaqstage{delve}\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))

    def test_includegraphics_with_bracket_arg_is_blanked(self):
        tex = "\\includegraphics[width=3in]{delve-figure.png}\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))


class TestLatexTextFormattingCommands(unittest.TestCase):
    """Wrapper stripped, inner text kept as prose -- no exemption for
    quoted or emphasized text."""

    def test_textbf_wrapper_stripped_inner_text_kept(self):
        tex = "This is \\textbf{a delve} in bold.\n"
        r = lint_tex(tex)
        self.assertIn("delve", terms(r.banned))

    def test_texttt_textit_emph_wrappers_all_keep_inner_text(self):
        for cmd in ("texttt", "textit", "emph"):
            tex = f"Wrapped: \\{cmd}{{a delve}} here.\n"
            r = lint_tex(tex)
            self.assertIn("delve", terms(r.banned), f"failed for {cmd}")


class TestLatexItemMarkers(unittest.TestCase):
    def test_item_content_is_linted_for_terms(self):
        tex = "\\item This is a delve in a list item.\n"
        r = lint_tex(tex)
        self.assertIn("delve", terms(r.banned))

    def test_item_marker_is_blanked_from_sentence_count(self):
        tex = "\\item This is a clean short sentence about widgets.\n"
        r = lint_tex(tex)
        self.assertEqual(r.sentences, 1)

    def test_item_with_optional_label_marker_is_blanked(self):
        tex = "\\item[(a)] Another clean sentence here with a delve inside.\n"
        r = lint_tex(tex)
        self.assertIn("delve", terms(r.banned))
        self.assertEqual(r.sentences, 1)


class TestHookScopeGuard(unittest.TestCase):
    """
    The hook's hard scope requirement: only .tex content carrying a prfaq
    marker, and meeting-summary markdown under meetings/, are ever in
    scope. `in_scope()` takes the reconstructed proposed content directly
    -- a PreToolUse hook fires before the write lands, so there is often
    nothing to read from disk yet.
    """

    def test_tex_content_with_prfaqversion_marker_in_scope(self):
        self.assertTrue(hook.in_scope(
            Path("draft.tex"), "\\prfaqversion{1}{0}\nSome prose.\n"))

    def test_tex_content_with_prfaqstage_marker_in_scope(self):
        self.assertTrue(hook.in_scope(
            Path("draft.tex"), "\\prfaqstage{hypothesis}\nSome prose.\n"))

    def test_tex_content_without_marker_out_of_scope(self):
        self.assertFalse(hook.in_scope(
            Path("unrelated.tex"), "Just some LaTeX prose with no markers.\n"))

    def test_tex_with_no_reconstructed_content_out_of_scope(self):
        """resolve_proposed_content() returned None -- an unsupported tool
        shape or a failed on-disk read. This fails OPEN, not closed: with no
        text to check for a marker, the file is treated as out of scope and
        the write passes through unlinted, matching the hook's overall
        never-block-on-infra-failure policy."""
        self.assertFalse(hook.in_scope(Path("draft.tex"), None))

    def test_meeting_summary_md_in_scope_regardless_of_content(self):
        self.assertTrue(hook.in_scope(
            Path("meetings/meeting-summary-2026-01-01.md"), None))

    def test_meeting_hive_summary_md_in_scope(self):
        self.assertTrue(hook.in_scope(
            Path("meetings/meeting-hive-summary-2026-01-01.md"), "Summary.\n"))

    def test_vote_md_in_meetings_dir_out_of_scope(self):
        self.assertFalse(hook.in_scope(
            Path("meetings/vote-2026-01-01.md"), "Vote text.\n"))

    def test_arbitrary_md_elsewhere_out_of_scope(self):
        self.assertFalse(hook.in_scope(Path("README.md"), "Some README.\n"))

    def test_meeting_summary_named_md_outside_meetings_dir_out_of_scope(self):
        self.assertFalse(hook.in_scope(
            Path("meeting-summary-2026-01-01.md"), "Summary text.\n"))


class TestResolveProposedContent(unittest.TestCase):
    """
    Reconstructing what a file will contain once the pending Write/Edit
    lands, without touching disk for a Write and without trusting only the
    edited fragment for an Edit.
    """

    def test_write_uses_content_directly(self):
        got = hook.resolve_proposed_content(
            "Write", {"content": "\\prfaqversion{1}{0}\nProse.\n"},
            Path("new.tex"))
        self.assertEqual(got, "\\prfaqversion{1}{0}\nProse.\n")

    def test_write_missing_content_returns_none(self):
        self.assertIsNone(
            hook.resolve_proposed_content("Write", {}, Path("new.tex")))

    def test_edit_applies_substitution_to_on_disk_content(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "draft.tex"
            f.write_text("\\prfaqversion{1}{0}\nOld line.\nOther line.\n",
                        encoding="utf-8")
            got = hook.resolve_proposed_content(
                "Edit",
                {"old_string": "Old line.", "new_string": "New line."},
                f,
            )
        self.assertEqual(
            got, "\\prfaqversion{1}{0}\nNew line.\nOther line.\n")

    def test_edit_marker_outside_edited_region_still_visible(self):
        """The scope marker lives far from the edited text -- the
        reconstructed content must still carry it, since it was never part
        of old_string/new_string."""
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "draft.tex"
            f.write_text(
                "\\prfaqversion{1}{0}\n"
                "Section one is unrelated filler text.\n"
                "Section two has the sentence we are editing.\n",
                encoding="utf-8",
            )
            got = hook.resolve_proposed_content(
                "Edit",
                {"old_string": "sentence we are editing",
                 "new_string": "sentence we just edited"},
                f,
            )
        self.assertIn("\\prfaqversion{1}{0}", got)
        self.assertIn("sentence we just edited", got)

    def test_edit_replace_all(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "draft.tex"
            f.write_text("x x x\n", encoding="utf-8")
            got = hook.resolve_proposed_content(
                "Edit",
                {"old_string": "x", "new_string": "y", "replace_all": True},
                f,
            )
        self.assertEqual(got, "y y y\n")

    def test_edit_unreadable_file_returns_none(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "locked.tex"
            f.write_text("\\prfaqversion{1}{0}\n", encoding="utf-8")
            f.chmod(0o000)
            try:
                got = hook.resolve_proposed_content(
                    "Edit", {"old_string": "a", "new_string": "b"}, f)
            finally:
                f.chmod(0o644)  # restore so tempdir cleanup can remove it
        self.assertIsNone(got)

    def test_unsupported_tool_returns_none(self):
        self.assertIsNone(
            hook.resolve_proposed_content("NotebookEdit", {}, Path("x.tex")))


class TestHookEndToEnd(unittest.TestCase):
    """
    Drives prose_lint_hook.py exactly as Claude Code would: a real
    PreToolUse payload on stdin, via subprocess -- not just importing the
    module's functions directly -- and asserts on the real
    hookSpecificOutput contract (verified against the official hookify
    plugin's rule_engine.py and README, which documents blocking as a
    PreToolUse-only capability), not an invented PostToolUse `{"block":
    bool}` shape.
    """

    HOOK = REPO_ROOT / "plugin" / "hooks" / "prose_lint_hook.py"

    def run_hook(self, tool_name: str, tool_input: dict,
                env: dict | None = None) -> tuple[dict, str]:
        payload = json.dumps({
            "hook_event_name": "PreToolUse",
            "tool_name": tool_name,
            "tool_input": tool_input,
        })
        proc = subprocess.run(
            [sys.executable, str(self.HOOK)],
            input=payload, capture_output=True, text=True, timeout=30,
            env=env,
        )
        return json.loads(proc.stdout), proc.stderr

    def test_write_with_banned_term_denies_before_it_lands(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "scratch.tex"
            result, _ = self.run_hook("Write", {
                "file_path": str(f),
                "content": (
                    "\\prfaqversion{1}{0}\n"
                    "This document is aspirational and written from today.\n"
                ),
            })
        output = result["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertEqual(output["permissionDecision"], "deny")
        self.assertIn("meta-explains-convention", output["permissionDecisionReason"])
        self.assertNotIn("additionalContext", output)
        self.assertFalse(f.exists(), "the file must never have been written")

    def test_edit_introducing_banned_term_denies(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "draft.tex"
            f.write_text(
                "\\prfaqversion{1}{0}\nA clean sentence about nothing.\n",
                encoding="utf-8",
            )
            result, _ = self.run_hook("Edit", {
                "file_path": str(f),
                "old_string": "A clean sentence about nothing.",
                "new_string": "This is load-bearing to the argument.",
            })
            output = result["hookSpecificOutput"]
            self.assertEqual(output["permissionDecision"], "deny")
            self.assertIn("load-bearing", output["permissionDecisionReason"])
            self.assertEqual(
                f.read_text(encoding="utf-8"),
                "\\prfaqversion{1}{0}\nA clean sentence about nothing.\n",
                "the on-disk file must be untouched by a denied edit",
            )

    def test_edit_marker_outside_edited_region_still_denies(self):
        """The prfaq marker lives outside old_string/new_string entirely --
        the hook must still recognize the file as in scope."""
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "draft.tex"
            f.write_text(
                "\\prfaqversion{1}{0}\n"
                "Section one is unrelated filler text.\n"
                "Section two has the sentence we are editing.\n",
                encoding="utf-8",
            )
            result, _ = self.run_hook("Edit", {
                "file_path": str(f),
                "old_string": "sentence we are editing",
                "new_string": "sentence that is load-bearing here",
            })
        output = result["hookSpecificOutput"]
        self.assertEqual(output["permissionDecision"], "deny")
        self.assertIn("load-bearing", output["permissionDecisionReason"])

    def test_meeting_summary_with_unreconstructable_edit_does_not_crash(self):
        """
        Regression: in_scope()'s meetings/ branch matches on path alone,
        with no content check -- so a meeting-summary path whose Edit
        can't be reconstructed (old_string/new_string missing or not
        strings) used to reach lint_proposed_text() with proposed=None,
        which crashed on fh.write(None) instead of failing open. main()
        now checks for None before in_scope() ever runs, for both file
        classes uniformly.
        """
        with tempfile.TemporaryDirectory() as d:
            meetings_dir = Path(d) / "meetings"
            meetings_dir.mkdir()
            f = meetings_dir / "meeting-summary-2026-01-01.md"
            f.write_text("Existing summary.\n", encoding="utf-8")
            result, stderr = self.run_hook("Edit", {
                "file_path": str(f),
                # old_string missing entirely -- resolve_proposed_content()
                # returns None for this shape.
                "new_string": "New text.",
            })
        self.assertEqual(result, {})
        self.assertNotIn("Traceback", stderr)

    def test_unrelated_md_with_no_prfaq_markers_is_untouched(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "notes.md"
            result, _ = self.run_hook("Write", {
                "file_path": str(f),
                "content": "This document is aspirational and written from today.\n",
            })
        self.assertEqual(result, {})

    def test_rationed_finding_is_advisory_not_blocking(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "scratch.tex"
            result, _ = self.run_hook("Write", {
                "file_path": str(f),
                "content": (
                    "\\prfaqversion{1}{0}\n"
                    "The robust robust robust robust system works well.\n"
                ),
            })
        output = result["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertNotIn("permissionDecision", output)
        self.assertIn("robust", output["additionalContext"])

    def test_clean_write_is_silent(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "scratch.tex"
            result, _ = self.run_hook("Write", {
                "file_path": str(f),
                "content": (
                    "\\prfaqversion{1}{0}\n"
                    "A plain sentence about nothing in particular.\n"
                ),
            })
        self.assertEqual(result, {})

    def test_config_error_surfaces_as_advisory_and_does_not_block(self):
        """The hook's EXIT_ERROR branch: a broken config must not read as
        a content problem with the file, and must never block."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / "plugin_root"
            (root / "scripts").mkdir(parents=True)
            real_script = REPO_ROOT / "plugin" / "scripts" / "prose_lint.py"
            (root / "scripts" / "prose_lint.py").write_text(
                real_script.read_text(encoding="utf-8"), encoding="utf-8")
            (root / "banlist.conf").write_text(
                "[bogus-section]\nx\n", encoding="utf-8")
            env = dict(os.environ)
            env["CLAUDE_PLUGIN_ROOT"] = str(root)
            f = Path(d) / "scratch.tex"
            result, stderr = self.run_hook("Write", {
                "file_path": str(f),
                "content": "\\prfaqversion{1}{0}\nA plain sentence.\n",
            }, env=env)
        output = result["hookSpecificOutput"]
        self.assertNotIn("permissionDecision", output)
        self.assertIn("configuration or usage error",
                      output["additionalContext"])
        self.assertIn("prose-lint hook: linter exited with a config/usage "
                      "error", stderr)


class TestTargetPathsShapes(unittest.TestCase):
    """target_paths() tolerates payload shape variance."""

    def test_snake_case_tool_input_file_path(self):
        paths = hook.target_paths(
            {"tool_input": {"file_path": "/a/b.tex"}})
        self.assertEqual(paths, [Path("/a/b.tex")])

    def test_camel_case_tool_input_fallback(self):
        paths = hook.target_paths(
            {"toolInput": {"filePath": "/a/b.tex"}})
        self.assertEqual(paths, [Path("/a/b.tex")])

    def test_edits_list_contributes_paths(self):
        paths = hook.target_paths({
            "tool_input": {
                "edits": [
                    {"file_path": "/a/one.tex"},
                    {"file_path": "/a/two.tex"},
                ]
            }
        })
        self.assertEqual(paths, [Path("/a/one.tex"), Path("/a/two.tex")])

    def test_no_recognized_field_yields_no_paths(self):
        self.assertEqual(hook.target_paths({"tool_input": {}}), [])


class TestSuppressionHint(unittest.TestCase):
    def test_tex_gets_latex_comment_form(self):
        self.assertEqual(hook.suppression_hint(Path("draft.tex")),
                         "% lint-ok: TERM")

    def test_markdown_gets_html_comment_form(self):
        self.assertEqual(
            hook.suppression_hint(Path("meetings/meeting-summary-x.md")),
            "<!-- lint-ok: TERM -->")


class TestLatexSuppression(unittest.TestCase):
    """The .tex-native suppression directive, matching the hook's own
    suggested fix for a .tex finding."""

    def test_percent_comment_suppresses_line(self):
        r = lint_tex("This is load-bearing. % lint-ok\n")
        self.assertEqual(r.banned, [])
        self.assertEqual(r.suppressed, 1)

    def test_targeted_percent_comment_suppresses_only_that_term(self):
        r = lint_tex("This load-bearing thing delves deep. "
                     "% lint-ok: load-bearing\n")
        self.assertNotIn("load-bearing", terms(r.banned))
        self.assertIn("delves", terms(r.banned))

    def test_escaped_percent_is_not_a_suppression_marker(self):
        r = lint_tex("The rate is 50\\% lint-ok this delve stays visible.\n")
        self.assertIn("delve", terms(r.banned))


class TestConfigErrors(unittest.TestCase):
    """Malformed banlist.conf aborts with EXIT_ERROR, distinct from
    EXIT_RATIONED -- both are 1 under bare sys.exit(str), which is the bug
    fatal() exists to close."""

    def _write(self, tmp_path: Path, body: str) -> Path:
        cfg = tmp_path / "banlist.conf"
        cfg.write_text(body, encoding="utf-8")
        return cfg

    def test_unknown_section_exits_error(self):
        with tempfile.TemporaryDirectory() as d:
            cfg = self._write(Path(d), "[nonsense]\nfoo\n")
            with self.assertRaises(SystemExit) as ctx:
                pl.load_config(cfg)
        self.assertEqual(ctx.exception.code, pl.EXIT_ERROR)

    def test_bad_pattern_regex_exits_error(self):
        with tempfile.TemporaryDirectory() as d:
            cfg = self._write(
                Path(d), "[banned.patterns]\nbad :: label :: ([unclosed\n")
            with self.assertRaises(SystemExit) as ctx:
                pl.load_config(cfg)
        self.assertEqual(ctx.exception.code, pl.EXIT_ERROR)

    def test_non_numeric_rationed_rate_exits_error(self):
        with tempfile.TemporaryDirectory() as d:
            cfg = self._write(Path(d), "[rationed]\nfoo: not-a-number\n")
            with self.assertRaises(SystemExit) as ctx:
                pl.load_config(cfg)
        self.assertEqual(ctx.exception.code, pl.EXIT_ERROR)

    def test_config_not_found_exits_error(self):
        with self.assertRaises(SystemExit) as ctx:
            pl.load_config(Path("/nonexistent/banlist.conf"))
        self.assertEqual(ctx.exception.code, pl.EXIT_ERROR)

    def test_unknown_profile_exits_error(self):
        cfg = pl.load_config(CONFIG)
        with self.assertRaises(SystemExit) as ctx:
            pl.apply_profile(cfg, "no-such-profile")
        self.assertEqual(ctx.exception.code, pl.EXIT_ERROR)

    def test_entry_outside_section_exits_error(self):
        with tempfile.TemporaryDirectory() as d:
            cfg = self._write(Path(d), "loose line\n")
            with self.assertRaises(SystemExit) as ctx:
                pl.load_config(cfg)
        self.assertEqual(ctx.exception.code, pl.EXIT_ERROR)


class TestStructuralPositiveCases(unittest.TestCase):
    """Every structural check so far has only a negative-case test
    (proving it doesn't misfire). Each needs a positive case proving it
    actually fires on the condition it targets."""

    def test_staccato_run_detected(self):
        cfg = pl.load_config(CONFIG)
        r = lint_text(
            "We shipped the feature. We fixed the bug. "
            "We wrote the test. We closed the ticket.",
            cfg=cfg)
        self.assertTrue(any(f.rule == "staccato" for f in r.structure))

    def test_passive_ratio_warns_above_threshold(self):
        cfg = pl.load_config(CONFIG)
        text = " ".join([
            "The file was written by the tool.",
            "The result was seen by the reviewer.",
            "The change was made by the author.",
            "The bug was found by the tester.",
            "The patch was sent by the maintainer.",
        ])
        r = lint_text(text, cfg=cfg)
        self.assertTrue(any(f.rule == "passive-voice" for f in r.structure))

    def test_nominalization_density_warns_above_threshold(self):
        cfg = pl.load_config(CONFIG)
        text = ("We make a determination. We make a recommendation. "
                "We make an observation. We provide a clarification. "
                "We make a declaration.")
        r = lint_text(text, cfg=cfg)
        self.assertTrue(any(f.rule == "nominalization" for f in r.structure))

    def test_title_case_heading_detected_when_enabled(self):
        cfg = pl.load_config(CONFIG)
        cfg["settings"]["title_case_headings"] = "rationed"
        r = lint_text("## This Is A Title Case Heading\n", cfg=cfg)
        self.assertTrue(any(f.rule == "title-case-heading"
                           for f in r.structure))


class TestLatexNestedFormatting(unittest.TestCase):
    """Nested text-formatting commands and starred cite variants are
    realistic in the dogfood document (see prfaq.tex's \\textit{\\texttt{...}}
    and \\cite*{...} usage patterns in academic LaTeX)."""

    def test_nested_textbf_textit_keeps_inner_text_as_prose(self):
        tex = "This is \\textbf{\\textit{a delve}} in bold italic.\n"
        r = lint_tex(tex)
        self.assertIn("delve", terms(r.banned))

    def test_starred_cite_is_blanked(self):
        # A bare "delve" citation key (not "delve2020") so a masking failure
        # would show up as a real word-boundary match, not be hidden by the
        # trailing digits merging into the word under term_regex.
        tex = "See \\cite*{delve} for detail.\n"
        r = lint_tex(tex)
        self.assertNotIn("delve", terms(r.banned))


if __name__ == "__main__":
    unittest.main(verbosity=2)
