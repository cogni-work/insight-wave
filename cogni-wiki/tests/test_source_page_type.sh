#!/usr/bin/env bash
# test_source_page_type.sh — assert the v0.0.44 (#270) `type: source`
# allowlist extension holds: a minimal `wiki/sources/<slug>.md` page with
# `type: source` frontmatter must NOT raise `invalid_type` or
# `type_directory_mismatch` from `wiki-health` (or `wiki-lint`, defensively).
#
# This unblocks cogni-knowledge PR #269 milestone 6 (`knowledge-ingest`),
# which writes one `type: source` page per ingested source body.
#
# Frontmatter-only fixture — no `pre_extracted_claims:` or other
# cogni-knowledge-specific fields, per the issue requirement that the
# test carries no cogni-knowledge dependency.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
HEALTH="$PLUGIN_ROOT/skills/wiki-health/scripts/health.py"
LINT="$PLUGIN_ROOT/skills/wiki-lint/scripts/lint_wiki.py"
WORKDIR="$(mktemp -d)"
WIKI="$WORKDIR/test-wiki"

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

red() { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { red "FAIL: $1"; exit 1; }

# ---------- prepare a migrated 0.0.5 fixture wiki ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null

green "fixture migrated to per-type-dirs layout (0.0.5)"

# ---------- plant a minimal `type: source` page ----------
TODAY=$(date +%Y-%m-%d)
mkdir -p "$WIKI/wiki/sources"
cat > "$WIKI/wiki/sources/example-source.md" <<EOF
---
id: example-source
title: Example ingested source
type: source
created: $TODAY
updated: $TODAY
---

This is a minimal source body planted by test_source_page_type.sh to verify
that wiki-health and wiki-lint accept the additive type-source allowlist
extension shipped in v0.0.44. The body is intentionally above the 50-char
stub threshold so the page does not trigger a stub_page warning.
EOF

green "planted wiki/sources/example-source.md with type: source frontmatter"

# ---------- 1) health.py must NOT raise invalid_type / type_directory_mismatch ----------
HEALTH_OUT=$(python3 "$HEALTH" --wiki-root "$WIKI")
HEALTH_OK=$(printf '%s' "$HEALTH_OUT" | python3 -c 'import json, sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")')
[ "$HEALTH_OK" = "yes" ] || fail "health.py did not return success:true"
green "health.py: success"

HEALTH_CLASSES=$(printf '%s' "$HEALTH_OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())["data"]
seen = set()
for bucket in ("errors", "warnings"):
    for ent in d.get(bucket, []) or []:
        c = ent.get("class")
        p = ent.get("page")
        if c and p == "example-source":
            seen.add(c)
print("\n".join(sorted(seen)))
')

for c in invalid_type type_directory_mismatch; do
  if printf '%s\n' "$HEALTH_CLASSES" | grep -qx "$c"; then
    red "FAIL: health.py raised '$c' on the planted type:source page"
    red "Health classes for example-source: $HEALTH_CLASSES"
    exit 1
  fi
done
green "health.py emits no invalid_type / type_directory_mismatch for type:source"

# ---------- 2) lint_wiki.py must do the same (defensive — v0.0.31 moved structural classes to health) ----------
LINT_OUT=$(python3 "$LINT" --wiki-root "$WIKI")
LINT_OK=$(printf '%s' "$LINT_OUT" | python3 -c 'import json, sys; print("yes" if json.loads(sys.stdin.read()).get("success") else "no")')
[ "$LINT_OK" = "yes" ] || fail "lint_wiki.py did not return success:true"
green "lint_wiki.py: success"

LINT_CLASSES=$(printf '%s' "$LINT_OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())["data"]
seen = set()
for bucket in ("errors", "warnings"):
    for ent in d.get(bucket, []) or []:
        c = ent.get("class")
        p = ent.get("page")
        if c and p == "example-source":
            seen.add(c)
print("\n".join(sorted(seen)))
')

for c in invalid_type type_directory_mismatch; do
  if printf '%s\n' "$LINT_CLASSES" | grep -qx "$c"; then
    red "FAIL: lint_wiki.py raised '$c' on the planted type:source page"
    red "Lint classes for example-source: $LINT_CLASSES"
    exit 1
  fi
done
green "lint_wiki.py emits no invalid_type / type_directory_mismatch for type:source"

# ---------- 3) defensive: the page was actually audited ----------
PAGES_AUDITED=$(printf '%s' "$HEALTH_OUT" | python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["data"]["stats"].get("pages_audited", 0))')
if [ "$PAGES_AUDITED" -lt 1 ]; then
  fail "health.py reported pages_audited=$PAGES_AUDITED (expected ≥ 1 — did iter_pages skip wiki/sources/?)"
fi
green "health.py audited $PAGES_AUDITED page(s) including wiki/sources/"

green "ALL TESTS PASS"
