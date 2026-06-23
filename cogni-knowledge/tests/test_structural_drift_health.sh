#!/usr/bin/env bash
# test_structural_drift_health.sh — functional test for the vendored health.py
# structural / schema drift detection (#863): a read-only, fail-soft warning
# class distinct from the numeric count-drift checks, on a curated
# (schema_version >= 0.0.8) base.
#
# Covers:
#   AC1a. A degraded curated base (schema 0.0.9) whose index.md OVERVIEW-NARRATIVE
#         block is still the bootstrap placeholder fires a structural_drift
#         warning; the verdict is no longer bare OK (warnings > 0) and errors stay 0.
#   AC1b. A degraded base whose ROOT-LINKS span carries only the empty-state
#         sentinel fires structural_drift.
#   AC2.  A correctly-finalized base (schema 0.0.9, real overview narrative +
#         populated root-links) fires NEITHER structural_drift NOR
#         schema_version_lag.
#   lag.  A curated base recorded at 0.0.8 (behind the engine's 0.0.9) fires a
#         schema_version_lag warning — in warnings[], NOT errors[] (errors stay 0).
#   AC3.  A pre-0.0.8 base (schema 0.0.7) with placeholder regions fires NOTHING
#         (the structural-drift assertions are schema-gated, same as the
#         curated-layout checks).
#   REL.  render_engine_lag (#947): a curated base whose stamped
#         last_rendered_engine_version is absent OR trails the installed
#         ENGINE_RENDER_VERSION fires render_engine_lag (warning, errors 0);
#         a current or newer stamp is silent; a pre-0.0.8 base never fires.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HEALTH="$PLUGIN_ROOT/scripts/vendor/cogni-wiki/skills/wiki-health/scripts/health.py"

# The installed engine version the render_engine_lag check compares against —
# read from the live ENGINE_RENDER_VERSION constant so this test never goes
# stale on a plugin version bump. build_curated stamps fixtures with it so the
# pre-#947 curated fixtures stay genuinely clean (no spurious render_engine_lag).
ENGINE_RENDER_VERSION="$(python3 -c "import re,sys; m=re.search(r'^ENGINE_RENDER_VERSION = \"([^\"]+)\"', open('$HEALTH').read(), re.M); sys.stdout.write(m.group(1) if m else '')")"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# The exact literals the detector strip-compares against (pinned to the live
# knowledge-setup seed and root_index.py empty-state sentinel).
OVERVIEW_PLACEHOLDER='_Overview pending — authored on the first knowledge-finalize run._'
ROOT_LINKS_EMPTY='_(no pages yet)_'

# Build a curated-layout fixture wiki with a configurable index.md carrying the
# OVERVIEW-NARRATIVE + ROOT-LINKS machine-owned blocks.
#   $1 = root dir, $2 = schema_version, $3 = overview inner, $4 = root-links inner
build_curated() {
  rm -rf "$1"
  mkdir -p "$1/wiki/sources" "$1/wiki/meta" "$1/.cogni-wiki"
  cat > "$1/.cogni-wiki/config.json" <<EOF
{"wiki_slug": "fixture", "title": "Fixture Base", "entries_count": 1, "schema_version": "$2", "last_rendered_engine_version": "$ENGINE_RENDER_VERSION"}
EOF
  cat > "$1/wiki/index.md" <<EOF
# Fixture Base

<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->
$3
<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->

## Regulierung

<!-- MACHINE-OWNED:ROOT-LINKS:START -->
$4
<!-- MACHINE-OWNED:ROOT-LINKS:END -->
EOF
  printf '_The overview narrative now lives in [index.md](index.md)._\n\n## Recent syntheses\n\n- none yet\n' > "$1/wiki/overview.md"
  printf '# Log\n' > "$1/wiki/meta/log.md"
  printf '# Context brief\n' > "$1/wiki/meta/context_brief.md"
  printf '# Open questions\n' > "$1/wiki/meta/open_questions.md"
  cat > "$1/wiki/sources/eu-ai-act-scope.md" <<'EOF'
---
id: eu-ai-act-scope
title: "Scope of the EU AI Act"
type: source
created: 2026-01-01
updated: 2026-01-01
sources:
  - https://example.org/ai-act
---

# Scope of the EU AI Act

Body text long enough to clear the stub-page threshold comfortably.
EOF
  printf '# Sources\n\n- [[eu-ai-act-scope]] — Scope of the EU AI Act.\n' > "$1/wiki/sources/index.md"
}

POPULATED_LINKS='**Explore:** [Sources (1)](sources/index.md#regulierung)'
REAL_OVERVIEW='This base surveys EU AI Act scope and obligations for SMEs.'

# ---------------------------------------------------------------------------
# AC1a. Degraded base (0.0.9): OVERVIEW-NARRATIVE on the bootstrap placeholder
# ---------------------------------------------------------------------------
WIKI="$WORK/overview-placeholder"
build_curated "$WIKI" "0.0.9" "$OVERVIEW_PLACEHOLDER" "$POPULATED_LINKS"
OUT="$WORK/overview-placeholder.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
assert_grep '"success": true' "$OUT" "AC1a: health succeeds on degraded base"
assert_grep 'structural_drift' "$OUT" \
  "AC1a: placeholder OVERVIEW-NARRATIVE fires structural_drift"
assert_grep '"errors": 0' "$OUT" "AC1a: structural drift is a warning, errors stay 0"
if grep -q 'schema_version_lag' "$OUT"; then
  red "FAIL: AC1a 0.0.9 base wrongly fired schema_version_lag"
  errors=$((errors + 1))
else
  green "PASS: AC1a current-schema base fires no schema_version_lag"
fi
# verdict no longer bare OK: at least one warning present
if grep -q '"warnings": 0' "$OUT"; then
  red "FAIL: AC1a degraded base reported zero warnings (verdict still bare OK)"
  errors=$((errors + 1))
else
  green "PASS: AC1a degraded base reports warnings (verdict no longer bare OK)"
fi

# ---------------------------------------------------------------------------
# AC1b. Degraded base (0.0.9): ROOT-LINKS span carries only the empty sentinel
# ---------------------------------------------------------------------------
WIKI="$WORK/rootlinks-empty"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$ROOT_LINKS_EMPTY"
OUT="$WORK/rootlinks-empty.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
assert_grep 'structural_drift' "$OUT" \
  "AC1b: empty ROOT-LINKS span fires structural_drift"
assert_grep '"errors": 0' "$OUT" "AC1b: structural drift is a warning, errors stay 0"

# ---------------------------------------------------------------------------
# AC2. Correctly-finalized base (0.0.9): real overview + populated root-links
# ---------------------------------------------------------------------------
WIKI="$WORK/clean-finalized"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$POPULATED_LINKS"
OUT="$WORK/clean-finalized.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
if grep -q 'structural_drift' "$OUT"; then
  red "FAIL: AC2 finalized base wrongly fired structural_drift"
  errors=$((errors + 1))
else
  green "PASS: AC2 finalized base fires no structural_drift"
fi
if grep -q 'schema_version_lag' "$OUT"; then
  red "FAIL: AC2 current-schema base wrongly fired schema_version_lag"
  errors=$((errors + 1))
else
  green "PASS: AC2 current-schema base fires no schema_version_lag"
fi
assert_grep '"errors": 0' "$OUT" "AC2: finalized base has zero errors"

# ---------------------------------------------------------------------------
# lag. Curated base at 0.0.8 (behind engine 0.0.9) fires schema_version_lag
# ---------------------------------------------------------------------------
WIKI="$WORK/schema-lag"
build_curated "$WIKI" "0.0.8" "$REAL_OVERVIEW" "$POPULATED_LINKS"
OUT="$WORK/schema-lag.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
assert_grep 'schema_version_lag' "$OUT" \
  "lag: a 0.0.8 base behind the engine fires schema_version_lag"
assert_grep '"errors": 0' "$OUT" "lag: schema_version_lag is a warning, errors stay 0"

# ---------------------------------------------------------------------------
# AC3. Pre-0.0.8 base (0.0.7): structural-drift assertions stay silent
# ---------------------------------------------------------------------------
WIKI="$WORK/legacy"
build_curated "$WIKI" "0.0.7" "$OVERVIEW_PLACEHOLDER" "$ROOT_LINKS_EMPTY"
OUT="$WORK/legacy.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
if grep -q 'structural_drift\|schema_version_lag' "$OUT"; then
  red "FAIL: AC3 pre-0.0.8 base fired structural/schema drift (gate broken)"
  errors=$((errors + 1))
else
  green "PASS: AC3 pre-0.0.8 base fires no structural/schema drift"
fi

# ---------------------------------------------------------------------------
# REL. render_engine_lag (#947) — set the stamp per-case via python.
# ---------------------------------------------------------------------------
set_stamp() {  # $1 = config.json path, $2 = value ("" deletes the key)
  python3 - "$1" "$2" <<'PY'
import json, sys
p, v = sys.argv[1], sys.argv[2]
c = json.load(open(p, encoding="utf-8"))
if v == "":
    c.pop("last_rendered_engine_version", None)
else:
    c["last_rendered_engine_version"] = v
json.dump(c, open(p, "w", encoding="utf-8"))
PY
}

# REL1. Curated base, NO stamp → render_engine_lag (absent), warning not error.
WIKI="$WORK/rel-absent"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$POPULATED_LINKS"
set_stamp "$WIKI/.cogni-wiki/config.json" ""
OUT="$WORK/rel-absent.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
assert_grep 'render_engine_lag' "$OUT" "REL1: absent stamp fires render_engine_lag"
assert_grep '"errors": 0' "$OUT" "REL1: render_engine_lag is a warning, errors stay 0"

# REL2. Stamp trails the installed engine → render_engine_lag (lag).
WIKI="$WORK/rel-trails"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$POPULATED_LINKS"
set_stamp "$WIKI/.cogni-wiki/config.json" "1.0.40"
OUT="$WORK/rel-trails.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
assert_grep 'render_engine_lag' "$OUT" "REL2: trailing stamp fires render_engine_lag"
assert_grep '"errors": 0' "$OUT" "REL2: render_engine_lag is a warning, errors stay 0"

# REL3. Stamp == installed engine → silent.
WIKI="$WORK/rel-current"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$POPULATED_LINKS"
OUT="$WORK/rel-current.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
if grep -q 'render_engine_lag' "$OUT"; then
  red "FAIL: REL3 current-stamp base wrongly fired render_engine_lag"
  errors=$((errors + 1))
else
  green "PASS: REL3 current-stamp base fires no render_engine_lag"
fi

# REL4. Stamp NEWER than the installed engine → silent (forward-compatible).
WIKI="$WORK/rel-newer"
build_curated "$WIKI" "0.0.9" "$REAL_OVERVIEW" "$POPULATED_LINKS"
set_stamp "$WIKI/.cogni-wiki/config.json" "99.0.0"
OUT="$WORK/rel-newer.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
if grep -q 'render_engine_lag' "$OUT"; then
  red "FAIL: REL4 newer-stamp base wrongly fired render_engine_lag"
  errors=$((errors + 1))
else
  green "PASS: REL4 newer-stamp base fires no render_engine_lag"
fi

# REL5. Pre-0.0.8 base with no stamp → silent (schema-gated, same as AC3).
WIKI="$WORK/rel-legacy"
build_curated "$WIKI" "0.0.7" "$REAL_OVERVIEW" "$POPULATED_LINKS"
set_stamp "$WIKI/.cogni-wiki/config.json" ""
OUT="$WORK/rel-legacy.json"
python3 "$HEALTH" --wiki-root "$WIKI" > "$OUT"
if grep -q 'render_engine_lag' "$OUT"; then
  red "FAIL: REL5 pre-0.0.8 base fired render_engine_lag (gate broken)"
  errors=$((errors + 1))
else
  green "PASS: REL5 pre-0.0.8 base fires no render_engine_lag"
fi

# ---------------------------------------------------------------------------
if [ "$errors" -gt 0 ]; then
  red "$errors assertion(s) failed"
  exit 1
fi
green "all structural/schema drift health assertions passed"
