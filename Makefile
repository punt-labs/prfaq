.PHONY: help prfaq test test-perms test-prose lint-prose check verify clean-tex

# Directories holding a compiled .tex. Both TEX_FILES and the artifact globs
# derive from this list, so a new document in one of these directories is
# gated with no edit here at all, and a new directory needs exactly one.
TEX_DIRS = . plugin/assets docs

# LaTeX intermediate files to remove after compilation
LATEX_ARTIFACTS = $(foreach d,$(TEX_DIRS),\
                    $(addprefix $(d)/,*.aux *.log *.out *.bbl *.bcf *.blg \
                                      *.run.xml *.fls *.fdb_latexmk \
                                      *.synctex.gz *.toc))

# Every .tex in those directories compiles. The two templates under
# plugin/assets/ ship to users, so a template that stopped compiling would be a
# shipped defect, and each document here has a committed .pdf that only stays
# honest if it is rebuilt. This is a wildcard over what is *present*, not over
# what is tracked: an untracked .tex left in one of these directories joins the
# gate and will fail it loudly, which is the reason scratch work belongs in
# .tmp/ (not a TEX_DIR) rather than at the repo root.
TEX_FILES = $(foreach d,$(TEX_DIRS),$(wildcard $(d)/*.tex))

# Where `prfaq` writes each PDF. Empty (the default) rebuilds the committed PDF
# next to its source. Set, it compiles into $(TEX_OUT)/<dir>/ instead, which is
# how `verify` proves every document still compiles without rewriting a
# tracked file.
TEX_OUT =
TEX_CHECK_DIR = .tmp/tex-check

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

prfaq: ## Compile .tex to .pdf and clean artifacts
	@test -n "$(strip $(TEX_FILES))" || { \
	  echo "Error: TEX_FILES is empty — no .tex found in TEX_DIRS ($(TEX_DIRS))." >&2; \
	  echo "       A gate that compiles nothing passes for the wrong reason." >&2; \
	  exit 1; \
	}
	@for f in $(TEX_FILES); do \
	  echo "Compiling $$f ..."; \
	  dir=$$(dirname "$$f"); base=$$(basename "$$f" .tex); \
	  out="$(if $(TEX_OUT),$(TEX_OUT)/$$dir,$$dir)"; mkdir -p "$$out"; \
	  rm -f "$$out/$$base.pdf"; \
	  pdflatex -interaction=nonstopmode -output-directory="$$out" "$$f" > /dev/null 2>&1; \
	  if [ -f "$$dir/$$base.bib" ] && command -v biber > /dev/null 2>&1; then \
	    (cd "$$out" && biber --input-directory="$(CURDIR)/$$dir" "$$base") > /dev/null 2>&1 || true; \
	    pdflatex -interaction=nonstopmode -output-directory="$$out" "$$f" > /dev/null 2>&1; \
	  fi; \
	  pdflatex -interaction=nonstopmode -output-directory="$$out" "$$f" > /dev/null 2>&1; \
	  if [ -f "$$out/$$base.pdf" ]; then \
	    echo "  $$out/$$base.pdf"; \
	  else \
	    echo "Error: $$f failed to compile" >&2; \
	    if [ -f "$$out/$$base.log" ]; then \
	      echo "--- first errors from $$out/$$base.log ---" >&2; \
	      grep -A3 '^!' "$$out/$$base.log" | head -40 >&2; \
	      echo "--- tail of $$out/$$base.log ---" >&2; \
	      tail -25 "$$out/$$base.log" >&2; \
	    fi; \
	    exit 1; \
	  fi; \
	done
	@rm -f $(LATEX_ARTIFACTS)

test: prfaq ## Verify all documents compile

test-perms: ## Verify the permission scripts (needs jq)
	@sh tests/test_permissions.sh

test-prose: ## Run the prose_lint unit and hook-scope tests
	@python3 tests/test_prose_lint.py

check: test test-perms test-prose ## Run all quality gates

# The same gates as `check`, but the compile writes into $(TEX_CHECK_DIR) so
# no committed PDF changes. The ethos handoff check runs this: a gate an agent
# runs before handing work back must not leave a dirty tree behind it.
verify: ## Run all quality gates without rewriting committed PDFs
	@rm -rf $(TEX_CHECK_DIR)
	@$(MAKE) --no-print-directory prfaq TEX_OUT=$(TEX_CHECK_DIR)
	@$(MAKE) --no-print-directory test-perms test-prose

# Informational only, deliberately not a `check` prerequisite: the shipped
# hook only ever sees .tex files carrying \prfaqversion/\prfaqstage and
# meetings/meeting-*summary-*.md (see plugin/hooks/prose_lint_hook.py). This
# target dogfoods prose_lint.py against the dogfood doc and reference guides
# too, on the same terms an author would want, without making an existing
# prose finding a build break.
lint-prose: ## Dogfood prose_lint.py against prfaq.tex and the reference guides (non-blocking)
	@python3 plugin/scripts/prose_lint.py --config plugin/banlist.conf \
	  prfaq.tex plugin/skills/prfaq/references/*.md || true

clean-tex: ## Remove LaTeX intermediate files
	@rm -f $(LATEX_ARTIFACTS)
