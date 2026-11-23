#!/bin/sh
# usage: check_pdf_fresh.sh <changed path>...
# Fails when a changed .tex has a tracked PDF beside it that is not also in
# the changed set: the gates compile into scratch space, so nothing else
# notices a committed PDF that no longer matches its source.
stale=""
for f in "$@"; do
  case "$f" in *.tex) ;; *) continue ;; esac
  [ -f "$f" ] || continue
  pdf="${f%.tex}.pdf"
  git ls-files --error-unmatch -- "$pdf" > /dev/null 2>&1 || continue
  found=0
  for g in "$@"; do [ "$g" = "$pdf" ] && found=1 && break; done
  [ "$found" = 1 ] || stale="$stale $pdf"
done
[ -z "$stale" ] && exit 0
echo "Error: these PDFs are stale; their .tex changed without them:" >&2
for p in $stale; do echo "  $p" >&2; done
echo "Rebuild with 'make prfaq' and commit the PDFs with the .tex." >&2
exit 1
