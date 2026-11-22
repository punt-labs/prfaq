#!/bin/sh
# Tests for tests/check_pdf_fresh.sh against this repo's tracked files.
cd "$(dirname "$0")/.." || exit 1
fail=0
expect() {
  want=$1; shift
  sh tests/check_pdf_fresh.sh "$@" > /dev/null 2>&1; got=$?
  if [ "$got" -ne "$want" ]; then echo "FAIL: exit $got, want $want: $*"; fail=1; fi
}
expect 0
expect 0 README.md
expect 1 plugin/assets/prfaq-template.tex
expect 0 plugin/assets/prfaq-template.tex plugin/assets/prfaq-template.pdf
expect 1 prfaq.tex docs/prfaq-overview.tex docs/prfaq-overview.pdf
expect 0 prfaq.pdf
expect 0 no/such/file.tex
[ "$fail" = 0 ] && echo "test_pdf_fresh: all passed"
exit "$fail"
