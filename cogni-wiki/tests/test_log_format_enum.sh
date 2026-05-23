#!/usr/bin/env bash
# test_log_format_enum.sh — assert the v0.0.45 log-format enum extension
# holds: SCHEMA.md.template's "Log format" block must list the three
# write-side cogni-knowledge prefixes (`compose`, `verify`, `finalize`)
# alongside the pre-existing operations.
#
# Background: cogni-knowledge's knowledge-compose / knowledge-verify /
# knowledge-finalize skills have written `## [DATE] {compose|verify|finalize}`
# lines to `wiki/log.md` since v0.0.22–24, but the operation enum that
# catalogs `wiki/log.md` never listed them. This is the overdue, additive
# cleanup (no schema_version bump — same posture as the `queue` prefix).
#
# Contract-level grep test — the template is a static seed copied into each
# wiki at setup time, so the regression class this catches is a prefix
# silently dropping out of the enum line or the description paragraph.
#
# bash 3.2 + grep only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$PLUGIN_ROOT/skills/wiki-setup/references/SCHEMA.md.template"

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

errors=0

if [ ! -f "$SCHEMA" ]; then
  red "FAIL: SCHEMA.md.template not found at $SCHEMA"
  exit 1
fi

# The enum line — `## [YYYY-MM-DD] {ingest|query|...} | one-line note`.
ENUM_LINE=$(grep -E '^## \[YYYY-MM-DD\] \{' "$SCHEMA" || true)
if [ -z "$ENUM_LINE" ]; then
  red "FAIL: could not locate the Log format enum line in SCHEMA.md.template"
  exit 1
fi

# 1) Each new prefix must appear as a pipe-delimited token in the enum line.
for prefix in compose verify finalize; do
  if printf '%s' "$ENUM_LINE" | grep -qE "[{|]${prefix}[|}]"; then
    green "PASS: enum line lists '${prefix}'"
  else
    red "FAIL: enum line missing '${prefix}' token"
    red "  got: $ENUM_LINE"
    errors=$((errors + 1))
  fi
done

# 2) Regression guard: pre-existing prefixes must survive the edit.
for prefix in ingest query queue; do
  if printf '%s' "$ENUM_LINE" | grep -qE "[{|]${prefix}[|}]"; then
    green "PASS: enum line still lists '${prefix}' (regression guard)"
  else
    red "FAIL: enum line dropped pre-existing '${prefix}' token"
    red "  got: $ENUM_LINE"
    errors=$((errors + 1))
  fi
done

# 3) The description paragraph must document the three new prefixes and the
#    additive-without-bump posture.
for prefix in compose verify finalize; do
  if grep -qE "\`${prefix}\`" "$SCHEMA"; then
    green "PASS: description references \`${prefix}\`"
  else
    red "FAIL: description does not reference \`${prefix}\`"
    errors=$((errors + 1))
  fi
done

if grep -qE 'v0\.0\.45' "$SCHEMA" && grep -qiE 'additive' "$SCHEMA"; then
  green "PASS: description carries the v0.0.45 additive-extension note"
else
  red "FAIL: description missing the v0.0.45 additive-extension note"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  green ""
  green "ALL TESTS PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi
