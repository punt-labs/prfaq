.PHONY: help prfaq test test-perms check clean-tex

# Directories holding a compiled .tex. Artifact globs and TEX_FILES both derive
# from this list, so adding a document in a new directory needs one edit.
TEX_DIRS = . plugin/assets docs

# LaTeX intermediate files to remove after compilation
LATEX_ARTIFACTS = $(foreach d,$(TEX_DIRS),\
                    $(addprefix $(d)/,*.aux *.log *.out *.bbl *.bcf *.blg \
                                      *.run.xml *.fls *.fdb_latexmk \
                                      *.synctex.gz *.toc))

# Every tracked .tex compiles. The two templates under plugin/assets/ ship to
# users, so a template that stopped compiling would be a shipped defect, and
# each of these has a committed .pdf that only stays honest if it is rebuilt.
TEX_FILES = prfaq.tex \
            press-release-v1.0.0.tex \
            plugin/assets/prfaq-template.tex \
            plugin/assets/press-release-template.tex \
            docs/prfaq-overview.tex

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

prfaq: ## Compile .tex to .pdf and clean artifacts
	@for f in $(TEX_FILES); do \
	  echo "Compiling $$f ..."; \
	  dir=$$(dirname "$$f"); base=$$(basename "$$f" .tex); \
	  pdflatex -interaction=nonstopmode -output-directory="$$dir" "$$f" > /dev/null 2>&1; \
	  if [ -f "$$dir/$$base.bib" ] && command -v biber > /dev/null 2>&1; then \
	    (cd "$$dir" && biber "$$base") > /dev/null 2>&1 || true; \
	    pdflatex -interaction=nonstopmode -output-directory="$$dir" "$$f" > /dev/null 2>&1; \
	  fi; \
	  pdflatex -interaction=nonstopmode -output-directory="$$dir" "$$f" > /dev/null 2>&1; \
	  if [ -f "$$dir/$$base.pdf" ]; then \
	    echo "  $$dir/$$base.pdf"; \
	  else \
	    echo "Error: $$f failed to compile" >&2; exit 1; \
	  fi; \
	done
	@rm -f $(LATEX_ARTIFACTS)

test: prfaq ## Verify all documents compile

test-perms: ## Verify the permission scripts (needs jq)
	@sh tests/test_permissions.sh

check: test test-perms ## Run all quality gates

clean-tex: ## Remove LaTeX intermediate files
	@rm -f $(LATEX_ARTIFACTS)
