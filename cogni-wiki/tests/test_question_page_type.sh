#!/usr/bin/env bash
# test_question_page_type.sh — assert the v0.0.50 (#407) `type: question`
# allowlist extension holds: a minimal `wiki/questions/<slug>.md` page with
# `type: question` frontmatter must NOT raise `invalid_type` or
# `type_directory_mismatch` from `wiki-health` (or `wiki-lint`, defensively).
#
# This unblocks cogni-knowledge #407 (`knowledge-ingest` Step 4.5), which
# writes one `type: question` research-question node per sub-question, each
# backlinking the source findings that answer it.
#
# Frontmatter-only fixture — no `theme_label:` / `sub_question_id:` or other
# cogni-knowledge-specific fields, per the same requirement test_source_page_type.sh
# follows: the test carries no cogni-knowledge dependency.
#
# This test covers the NEGATIVE case (no false positive on `type: question`).
# The POSITIVE case (`invalid_type` still fires on a bogus type after the
# allowlist extension) is covered by `test_lint_health_partition.sh`, which
# plants `type: bogus-type` and asserts health reports it.
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

assert_success_json() {
  local label="$1" out="$2" ok
  ok=$(printf '%s' "$out" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print("yes" if d.get("success") else "no")' 2>/dev/null || echo "parse-error")
  if [ "$ok" != "yes" ]; then
    red "FAIL ($label): expected success:true"
    printf '%s\n' "$out"
    exit 1
  fi
}

# ---------- prepare a migrated 0.0.5 fixture wiki ----------
cp -R "$FIXTURES/legacy-wiki" "$WIKI"
python3 "$PLUGIN_ROOT/skills/wiki-setup/scripts/migrate_layout.py" \
  --wiki-root "$WIKI" --apply >/dev/null

green "fixture migrated to per-type-dirs layout (0.0.5)"

# ---------- plant a minimal `type: question` page ----------
TODAY=$(date +%Y-%m-%d)
mkdir -p "$WIKI/wiki/questions"
cat > "$WIKI/wiki/questions/example-question.md" <<EOF
---
id: example-question
title: Example research question
type: question
created: $TODAY
updated: $TODAY
---

This is a minimal research-question node planted by test_question_page_type.sh
to verify that wiki-health and wiki-lint accept the additive type-question
allowlist extension shipped in v0.0.50. The body is intentionally above the
50-char stub threshold so the page does not trigger a stub_page warning.
EOF

green "planted wiki/questions/example-question.md with type: question frontmatter"

# ---------- 1) health.py must NOT raise invalid_type / type_directory_mismatch ----------
HEALTH_OUT=$(python3 "$HEALTH" --wiki-root "$WIKI")
assert_success_json "health.py" "$HEALTH_OUT"
green "health.py: success"

HEALTH_CLASSES=$(printf '%s' "$HEALTH_OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())["data"]
seen = set()
for bucket in ("errors", "warnings"):
    for ent in d.get(bucket, []) or []:
        c = ent.get("class")
        p = ent.get("page")
        if c and p == "example-question":
            seen.add(c)
print("\n".join(sorted(seen)))
')

for c in invalid_type type_directory_mismatch; do
  if printf '%s\n' "$HEALTH_CLASSES" | grep -qx "$c"; then
    red "FAIL: health.py raised '$c' on the planted type:question page"
    red "Health classes for example-question:"
    printf '%s\n' "$HEALTH_CLASSES"
    exit 1
  fi
done
green "health.py emits no invalid_type / type_directory_mismatch for type:question"

# ---------- 2) lint_wiki.py must do the same (defensive — v0.0.31 moved structural classes to health) ----------
LINT_OUT=$(python3 "$LINT" --wiki-root "$WIKI")
assert_success_json "lint_wiki.py" "$LINT_OUT"
green "lint_wiki.py: success"

LINT_CLASSES=$(printf '%s' "$LINT_OUT" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())["data"]
seen = set()
for bucket in ("errors", "warnings"):
    for ent in d.get(bucket, []) or []:
        c = ent.get("class")
        p = ent.get("page")
        if c and p == "example-question":
            seen.add(c)
print("\n".join(sorted(seen)))
')

for c in invalid_type type_directory_mismatch; do
  if printf '%s\n' "$LINT_CLASSES" | grep -qx "$c"; then
    red "FAIL: lint_wiki.py raised '$c' on the planted type:question page"
    red "Lint classes for example-question:"
    printf '%s\n' "$LINT_CLASSES"
    exit 1
  fi
done
green "lint_wiki.py emits no invalid_type / type_directory_mismatch for type:question"

# ---------- 3) defensive: the page was actually audited ----------
PAGES_AUDITED=$(printf '%s' "$HEALTH_OUT" | python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["data"]["stats"].get("pages_audited", 0))')
if [ "$PAGES_AUDITED" -lt 1 ]; then
  fail "health.py reported pages_audited=$PAGES_AUDITED (expected ≥ 1 — did iter_pages skip wiki/questions/?)"
fi
green "health.py audited $PAGES_AUDITED page(s) including wiki/questions/"

green "ALL TESTS PASS"
