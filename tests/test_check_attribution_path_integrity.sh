#!/usr/bin/env bash
# Suite for scripts/check-attribution-path-integrity.py.
#
# Every fixture is built in its own `mktemp -d` tree and `git init`ed there, so
# the guard's tracked-index resolution is exercised hermetically. The real
# tracked NOTICE is never mutated in place — a suite that edited it would leave
# the working tree dirty and would be checking a moving target.
#
# Assertions are on exit status and on the JSON this repo's own guard emits,
# never on the wording of a foreign tool's message.
#
# Mutation recipe — the tracked-membership test:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-attribution-path-integrity.py \
#     --expr 's/claim_path not in tracked/claim_path in ()/m' \
#     --test 'bash tests/test_check_attribution_path_integrity.sh' --case D1
#
# The mutation makes the membership test constantly false, so the guarded
# branch is never entered and resolves() returns True for every claim — no
# claim can ever be reported unresolved. D1, the dirty fixture whose Location:
# names a path that is not tracked, then goes RED, and GREEN again on restore.
# The /m modifier is load-bearing: --expr is fed to `perl -0pi`, which slurps
# the whole file, so without it the anchors never bind. The substitution is
# non-global and safe because `claim_path not in tracked` occurs exactly once
# in the guard and is never echoed in a comment, so the rewrite yields valid
# Python (`if claim_path in ():`) rather than a SyntaxError that would red every
# case and grade nothing.
#
# Mutation recipe — the markdown-link-target carrier:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-attribution-path-integrity.py \
#     --expr 's/LINK_TARGET_RE\.finditer\(line\)/[]/m' \
#     --test 'bash tests/test_check_attribution_path_integrity.sh' --case T1
#
# Mutation recipe — the code-span carrier:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-attribution-path-integrity.py \
#     --expr 's/CODE_SPAN_RE\.finditer\(line\)/[]/m' \
#     --test 'bash tests/test_check_attribution_path_integrity.sh' --case S1
#
# Mutation recipe — the deepest (per-skill) location pattern:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-attribution-path-integrity.py \
#     --expr 's/\n    os\.path\.join\("\*", "skills", "\*", "references", "\*", ""\),//m' \
#     --test 'bash tests/test_check_attribution_path_integrity.sh' --case K1
#
# The mutation drops the fourth SURFACE_LOCATIONS entry, so no glob reaches a
# surface at the per-skill references/ depth. K1's fixture surface is then never
# discovered and K1 goes RED, GREEN again on restore. Before K1 existed this
# mutation reded nothing at all — the suite reported `0 failed` with the pattern
# deleted, which is precisely the vacuity this recipe now forecloses.
#
# Mutation recipe — zero-discovery is an error, not a clean zero:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . \
#     --file scripts/check-attribution-path-integrity.py \
#     --expr 's/if not surfaces:/if False:/m' \
#     --test 'bash tests/test_check_attribution_path_integrity.sh' --case Z1

set -eu

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$REPO_ROOT/scripts/check-attribution-path-integrity.py"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0

# One level of helper indirection: the case id arrives as "$1" at the call site
# and both arms are emitted from it, so every FAIL id has a reachable same-id
# green twin. Emitters write their argument verbatim — no escape sequences.
check_eq() { # check_eq <id + description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '%s\n' "PASS: $1"
  else
    printf '%s\n' "FAIL: $1 (expected '$2', got '$3')"
    failures=$((failures + 1))
  fi
}

# Build a git-backed fixture tree. Files are staged but never committed —
# `git ls-files` reads the index, which staging is enough to populate.
mk_repo() { # mk_repo <dir>
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email t@example.invalid
  git -C "$1" config user.name t
}

stage() { # stage <dir>
  git -C "$1" add -A
}

# Sets LAST_RC and LAST_JSON as globals. Deliberately NOT called through a
# command substitution: that runs the function in a subshell, so the JSON it
# captured would be discarded and every assertion reading it would compare
# against an empty string — green or red for a reason unrelated to the guard.
run_guard() { # run_guard <root>
  set +e
  LAST_JSON="$(python3 "$GUARD" --root "$1" 2>/dev/null)"
  LAST_RC=$?
  set -e
}

json_expr() { # json_expr <json> <python expression over d>
  printf '%s' "$1" | python3 -c "import json,sys; d=json.load(sys.stdin); print($2)"
}

# --- D1: a non-resolving assertion-field claim is a violation ----------------
# This is the acceptance criterion's "break the mechanism" case and the
# mutation-recipe target.
D1="$WORK/d1"
mk_repo "$D1"
mkdir -p "$D1/cogni-thing/references"
printf '%s\n' 'placeholder' > "$D1/cogni-thing/references/real.json"
cat > "$D1/NOTICE" <<'FIXTURE'
insight-wave fixture

* Some bundled asset
  Location: cogni-thing/references/absent.json
FIXTURE
stage "$D1"
run_guard "$D1"
check_eq "D1 a non-resolving Location claim exits 1" "1" "$LAST_RC"
check_eq "D1b the violation names the offending surface and line" "NOTICE:4" \
  "$(json_expr "$LAST_JSON" "d['data']['violations'][0]['file'] + ':' + str(d['data']['violations'][0]['line'])")"
check_eq "D1c the violation is attributed to the assertion_field arm" "assertion_field" \
  "$(json_expr "$LAST_JSON" "d['data']['violations'][0]['arm']")"

# --- N1: the real NOTICE shape — assertion field at the live nesting depth ---
# D1 proves the assertion_field carrier, but at a shallower path than the claims
# that actually went stale. NOTICE:18/:23 are Location:/See: values pointing two
# levels deep (plugin/references/<asset-dir>/file). This pins that exact
# carrier-and-depth pairing, so the guard is shown watching the shape of the
# defect it was written for rather than a convenient approximation of it.
N1="$WORK/n1"
mk_repo "$N1"
mkdir -p "$N1/cogni-thing/references/cartographic-data"
printf '%s\n' 'x' > "$N1/cogni-thing/references/cartographic-data/present.geo.json"
cat > "$N1/NOTICE" <<'FIXTURE'
insight-wave fixture

* Cartographic country-outline data
  Location: cogni-thing/references/cartographic-data/absent.geo.json
  See: cogni-thing/references/cartographic-data/LICENSE.md
FIXTURE
stage "$N1"
run_guard "$N1"
check_eq "N1 a deep references/ assertion claim that does not resolve is a violation" "1" "$LAST_RC"
check_eq "N1b both deep assertion claims are reported, not just the first" "2" \
  "$(json_expr "$LAST_JSON" "d['data']['summary']['total']")"
check_eq "N1c both are attributed to the assertion_field arm" "True" \
  "$(json_expr "$LAST_JSON" "all(v['arm'] == 'assertion_field' for v in d['data']['violations'])")"

# --- D2: a claim differing only in CASE is still a violation -----------------
# Pins tracked-index resolution against os.path.exists, which passes on a
# case-insensitive filesystem and would make this case green for the wrong
# reason on a contributor's macOS clone.
D2="$WORK/d2"
mk_repo "$D2"
mkdir -p "$D2/cogni-thing/agents"
printf '%s\n' 'x' > "$D2/cogni-thing/agents/thing.md"
cat > "$D2/NOTICE" <<'FIXTURE'
insight-wave fixture

* Some bundled asset
  See: cogni-thing/agents/Thing.md
FIXTURE
stage "$D2"
run_guard "$D2"
check_eq "D2 a case-only mismatch is a violation" "1" "$LAST_RC"

# --- C1 / L1 / R1 all read ONE real-tree run --------------------------------
# REPO_ROOT is never mutated (every fixture lives under $WORK), so three
# separate runs would be the same derivation stated three times. Captured into
# dedicated variables because the fixture cases below clobber LAST_JSON.
run_guard "$REPO_ROOT"
REAL_RC="$LAST_RC"
REAL_JSON="$LAST_JSON"

check_eq "C1 the real repository tree exits 0" "0" "$REAL_RC"
check_eq "C1b the real tree reports no violations" "0" \
  "$(json_expr "$REAL_JSON" "d['data']['summary']['total']")"

# --- L1: liveness floors ----------------------------------------------------
# Inequalities strictly below the live values, so a legitimate change never
# reds the suite while a collapsed scan population does.
check_eq "L1 the real tree discovers a live surface population" "True" \
  "$(json_expr "$REAL_JSON" "d['data']['summary']['surfaces_discovered'] >= 8")"
# The real tree carries NO attribution claim since the cogni-workspace render
# chain retired and took the one vendored asset (the Natural Earth cartographic
# data) with it, so a real-tree floor over claims_examined — or over the
# plugin-level `*/references/*/` location pattern, whose only real-tree surface
# was that asset's LICENSE.md — would be a standing red on a correct tree. Both
# properties are pinned on the L2 fixture instead: a surface at exactly the
# plugin-level references/ depth carrying two resolving claims, so the guard is
# shown discovering that pattern AND examining claims, and a deleted pattern or
# a claim scan that stopped counting reds here rather than being masked by an
# empty real tree. The root NOTICE keeps the fixture out of the zero-discovery
# arm for the same reason K1 carries one.
L2="$WORK/l2"
mk_repo "$L2"
mkdir -p "$L2/cogni-thing/references/asset"
printf '%s\n' 'x' > "$L2/cogni-thing/references/asset/present.geo.json"
printf '%s\n' 'insight-wave fixture' > "$L2/NOTICE"
cat > "$L2/cogni-thing/references/asset/LICENSE.md" <<'FIXTURE'
insight-wave fixture

* Bundled asset licence
  Location: cogni-thing/references/asset/present.geo.json
  See: cogni-thing/references/asset/LICENSE.md
FIXTURE
stage "$L2"
run_guard "$L2"
check_eq "L2 the plugin-level references/ location pattern still reaches its surface" "True" \
  "$(json_expr "$LAST_JSON" "'cogni-thing/references/asset/LICENSE.md' in d['data']['surfaces']")"
check_eq "L2b a live claim population is examined on that surface" "True" \
  "$(json_expr "$LAST_JSON" "d['data']['summary']['claims_examined'] >= 2")"
check_eq "L2c resolving claims at that depth are clean" "0" "$LAST_RC"

# --- K1: the deepest (per-skill) location pattern, on a fixture -------------
# The real tree has no surface at `*/skills/*/references/*/`, so no assertion
# over REAL_JSON can falsify that pattern — deleting it from SURFACE_LOCATIONS
# leaves every real-tree case green. This fixture builds a surface at exactly
# that depth and asserts the guard both DISCOVERS it and SCANS it.
#
# The fixture also carries a root NOTICE, so the tree is never zero-discovery.
# That matters: without it, deleting the pattern would empty the surface set and
# trip the zero-discovery error arm (exit 2), and this case would red for that
# reason rather than for the pattern it is written to pin. With the NOTICE
# present, deleting the pattern leaves a clean exit 0 with the deep surface
# simply unseen — so K1/K1b red on the pattern itself.
K1="$WORK/k1"
mk_repo "$K1"
mkdir -p "$K1/cogni-thing/skills/thing-skill/references/asset"
printf '%s\n' 'x' > "$K1/cogni-thing/skills/thing-skill/references/asset/present.txt"
printf '%s\n' 'insight-wave fixture' > "$K1/NOTICE"
cat > "$K1/cogni-thing/skills/thing-skill/references/asset/LICENSE.md" <<'FIXTURE'
insight-wave fixture

* Bundled asset licence
  Location: cogni-thing/skills/thing-skill/references/asset/absent.txt
FIXTURE
stage "$K1"
run_guard "$K1"
check_eq "K1 a surface at the per-skill references/ depth is discovered" "True" \
  "$(json_expr "$LAST_JSON" "'cogni-thing/skills/thing-skill/references/asset/LICENSE.md' in d['data']['surfaces']")"
check_eq "K1b its non-resolving claim is reported, so the surface is scanned and not merely listed" "1" \
  "$LAST_RC"
check_eq "K1c the violation names that surface" "cogni-thing/skills/thing-skill/references/asset/LICENSE.md" \
  "$(json_expr "$LAST_JSON" "d['data']['violations'][0]['file']")"

# --- X1/X2/X3: non-subjects are excluded by class, not by literal -----------
X="$WORK/x"
mk_repo "$X"
cat > "$X/NOTICE" <<'FIXTURE'
insight-wave fixture

* Some bundled asset
  Packaging: some-upstream/project-slug (MIT License)
  Underlying data: another-upstream/data-set
  See: https://example.invalid/not/a/local/path
FIXTURE
cat > "$X/LICENSE" <<'FIXTURE'
See: LICENSE
FIXTURE
stage "$X"
run_guard "$X"
check_eq "X1 a provenance-field value that resolves nowhere is not a violation" "0" "$LAST_RC"
check_eq "X2 no claim is extracted from a URL or a bare filename" "0" \
  "$(json_expr "$LAST_JSON" "d['data']['summary']['claims_examined']")"

# --- S1/S2: the code-span carrier, both directions --------------------------
S1="$WORK/s1"
mk_repo "$S1"
mkdir -p "$S1/cogni-plug/references/asset"
cat > "$S1/cogni-plug/references/asset/LICENSE.md" <<'FIXTURE'
# Asset licence

Why it is here: the `cogni-plug/agents/absent-agent.md` worker uses this file.
FIXTURE
stage "$S1"
run_guard "$S1"
check_eq "S1 a non-resolving path inside a code span is a violation" "1" "$LAST_RC"
check_eq "S1b the violation is attributed to the code_span arm" "code_span" \
  "$(json_expr "$LAST_JSON" "d['data']['violations'][0]['arm']")"

S2="$WORK/s2"
mk_repo "$S2"
mkdir -p "$S2/cogni-plug/references/asset"
cat > "$S2/cogni-plug/references/asset/LICENSE.md" <<'FIXTURE'
# Asset licence

Why it is here: the cogni-plug/agents/absent-agent.md worker uses this file.
FIXTURE
stage "$S2"
run_guard "$S2"
check_eq "S2 the same path outside any carrier is not a violation" "0" "$LAST_RC"

# --- R1/R1a: the docs exclusion is structural -------------------------------
check_eq "R1 no discovered surface on the real tree lives under docs/" "True" \
  "$(json_expr "$REAL_JSON" "not any(s.startswith('docs/') for s in d['data']['surfaces'])")"

# R1 alone is green at base for a reason unrelated to the rule — no docs/ path
# can match the globs today, so it would stay green even if the exclusion
# reasoning were wrong. R1a is its required positive twin: the SAME offending
# body at two paths, and only the in-class one may be reported.
R1A="$WORK/r1a"
mk_repo "$R1A"
mkdir -p "$R1A/docs/relicensing"
printf '%s\n' '  Location: cogni-thing/references/absent.json' > "$R1A/docs/relicensing/frozen.md"
printf '%s\n' '  Location: cogni-thing/references/absent.json' > "$R1A/NOTICE"
stage "$R1A"
run_guard "$R1A"
check_eq "R1a an identical claim is reported in NOTICE and ignored under docs/" "1" \
  "$(json_expr "$LAST_JSON" "d['data']['summary']['total']")"
check_eq "R1b the single reported violation is the in-class surface" "NOTICE" \
  "$(json_expr "$LAST_JSON" "d['data']['violations'][0]['file']")"

# --- T1/T2: the markdown-link-target carrier, both directions ---------------
# Without a fixture this carrier would be an unfalsifiable third arm: it fires
# on no real surface today, so nothing else in this suite can hold it honest.
T1="$WORK/t1"
mk_repo "$T1"
cat > "$T1/NOTICE" <<'FIXTURE'
insight-wave fixture

See the [asset licence](cogni-thing/references/absent/LICENSE.md) for terms.
FIXTURE
stage "$T1"
run_guard "$T1"
check_eq "T1 a non-resolving markdown link target is a violation" "1" "$LAST_RC"
check_eq "T1b the violation is attributed to the link_target arm" "link_target" \
  "$(json_expr "$LAST_JSON" "d['data']['violations'][0]['arm']")"

T2="$WORK/t2"
mk_repo "$T2"
mkdir -p "$T2/cogni-thing/references/present"
printf '%s\n' 'x' > "$T2/cogni-thing/references/present/LICENSE.md"
cat > "$T2/NOTICE" <<'FIXTURE'
insight-wave fixture

See the [asset licence](cogni-thing/references/present/LICENSE.md) for terms.
FIXTURE
stage "$T2"
run_guard "$T2"
check_eq "T2 a resolving markdown link target is not a violation" "0" "$LAST_RC"

# --- Z1: zero discovered surfaces is an error, never a clean zero -----------
Z1="$WORK/z1"
mk_repo "$Z1"
stage "$Z1"
run_guard "$Z1"
check_eq "Z1 an empty tree exits 2 rather than reporting a clean zero" "2" "$LAST_RC"

# --- E1: a non-git root is an error, never a silent pass --------------------
E1="$WORK/e1"
mkdir -p "$E1"
printf '%s\n' '  Location: cogni-thing/references/absent.json' > "$E1/NOTICE"
run_guard "$E1"
check_eq "E1 a root that is not a git repository exits 2" "2" "$LAST_RC"

printf '%s\n' "$failures failed"
[ "$failures" -eq 0 ] || exit 1
