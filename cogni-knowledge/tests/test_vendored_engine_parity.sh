#!/usr/bin/env bash
# test_vendored_engine_parity.sh - byte-identity guard for the vendored wiki engine.
#
# Phase 7 vendors the cogni-wiki runtime engine into
# cogni-knowledge/scripts/vendor/cogni-wiki/ as a VERBATIM mirror so the plugin
# is self-contained while cogni-wiki remains the source of truth. The mirror is
# only safe if it never silently drifts from its origin: this test asserts every
# vendored file is byte-identical (cmp) to the cogni-wiki file it was copied from.
#
# When cogni-wiki is absent (a partial checkout, or post-archive), each origin
# comparison is SKIPPED with a notice rather than failed — the vendored copy is
# the source of truth at that point. With cogni-wiki present (the monorepo / CI),
# every file must match or the test fails.
#
# bash 3.2 + stdlib only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_ROOT="$PLUGIN_ROOT/scripts/vendor/cogni-wiki"
REPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
WIKI_ROOT="$REPO_ROOT/cogni-wiki"

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$1"; }

errors=0
checked=0
skipped=0

if [ ! -d "$VENDOR_ROOT" ]; then
  red "FAIL: vendored engine dir not found: $VENDOR_ROOT"
  exit 1
fi

# Walk every vendored file and compare it to its cogni-wiki origin. The vendor
# tree mirrors cogni-wiki's structure exactly (skills/<skill>/scripts/... and
# foundations/...), so the origin path is the vendor path with the vendor prefix
# swapped for the cogni-wiki root.
while IFS= read -r vfile; do
  rel="${vfile#"$VENDOR_ROOT"/}"
  origin="$WIKI_ROOT/$rel"
  if [ ! -e "$origin" ]; then
    if [ -d "$WIKI_ROOT" ]; then
      red "FAIL: vendored file has no cogni-wiki origin: $rel"
      errors=$((errors + 1))
    else
      skipped=$((skipped + 1))
    fi
    continue
  fi
  if cmp -s "$vfile" "$origin"; then
    checked=$((checked + 1))
  else
    red "FAIL: vendored copy drifted from origin: $rel"
    errors=$((errors + 1))
  fi
done < <(find "$VENDOR_ROOT" -type f ! -name 'README.md' -not -path '*/__pycache__/*' | sort)

# Provenance README is cogni-knowledge-authored (not a mirror) — assert presence,
# not byte-identity.
if [ -f "$PLUGIN_ROOT/scripts/vendor/README.md" ]; then
  green "PASS: vendor provenance README present"
  # The README carries a durable `Vendored-from: <sha> (date)` line recording the
  # cogni-wiki origin commit the vendored copy was taken from — the post-archive
  # provenance anchor. Guard it from silent removal: require a Vendored-from line
  # with an exactly-40-hex-char SHA, anchored at line start.
  if grep -Eq '^Vendored-from: [0-9a-f]{40}\b' "$PLUGIN_ROOT/scripts/vendor/README.md"; then
    green "PASS: vendor provenance Vendored-from SHA marker present"
  else
    red "FAIL: scripts/vendor/README.md missing a 'Vendored-from: <40-hex-sha>' provenance marker"
    errors=$((errors + 1))
  fi
else
  red "FAIL: scripts/vendor/README.md provenance note missing"
  errors=$((errors + 1))
fi

if [ ! -d "$WIKI_ROOT" ]; then
  yellow "NOTE: cogni-wiki not present — $skipped origin comparison(s) skipped (vendored copy is source of truth)."
fi

if [ $errors -gt 0 ]; then
  red "$errors file(s) failed byte-identity."
  exit 1
fi

green ""
green "Vendored engine parity: $checked file(s) byte-identical to cogni-wiki origin${skipped:+, $skipped skipped}."
