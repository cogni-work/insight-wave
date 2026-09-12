#!/usr/bin/env bash
# test-bundled-presets.sh — the bundled theme catalog is offerable, not just present.
#
# Operation 5 of manage-themes offers `cogni-work` plus four archetype presets
# out of `cogni-workspace/themes/`. "Offerable" is four separate properties, and
# a preset can satisfy three and still be useless:
#
#   1. it ships both `theme.md` and `manifest.json`;
#   2. `validate-theme-manifest.py` accepts it, so Operation 7 can deepen it later;
#   3. its default colour pairs clear WCAG AA, so the audit Operation 5 runs
#      before reporting success does not immediately reject what was just offered;
#   4. it carries `## Voice & Copy Guidelines`, the Phase D structural contract
#      every voice consumer relies on.
#
# Properties 1, 2 and 4 are also asserted from the umbrella harness
# (`scripts/verify-theme-backcompat.sh`, cases tbc24/tbc25/tbc21). This suite is
# not a duplicate of them: that harness stops at the FIRST failure, so a broken
# `boardroom` hides everything about `signal`. Here each preset owns independent
# result lines and the run continues, which is what makes a catalog-wide verdict
# readable. Property 3 lives only here.
#
# CASE IDS. Every result line is addressed by a unique first token in the
# repo's `<suite-slug>-<NN>-<discriminator>` shape, and the discriminator is the
# preset slug interpolated from the loop — a fixed id inside a per-preset loop
# emits one token once per iteration, leaving every later preset unaddressable
# by `--case`. Each fail arm has a same-id green twin.
#
# PALETTE EXTRACTION. `check-contrast.py` wants a flat `{"role": "#rrggbb"}`
# map, and a tier-0 preset keeps its colours only as `theme.md` prose. Three
# properties of the extractor below are load-bearing:
#
#   * the `## ` prefix reset scopes the scan to the `## Color Palette` block
#     INCLUDING its `### Status Colors` subsection, and stops at `## Typography`;
#   * the backticked-hex requirement is what rejects the `- **Headers**:` and
#     `- **0**:` bullets, which share the label shape but carry no colour;
#   * the whitespace-to-hyphen substitution is what keeps `Text Muted` out of
#     `data.unclassified` — `check-contrast.py` normalises with `strip().lower()`
#     only, so `text muted` is an unknown role, forms no pair, and would leave a
#     silently vacuous audit reporting `evaluated: 0` as if it were clean.
#
# The contrast case is deliberately scoped to `THEMES` — the four archetypes and
# `_template`-excluded `cogni-work` are NOT interchangeable here. `cogni-work`
# carries `border`, `surface-dark` and `text-light`, and the all-pairs cross
# product legitimately puts `text` on `surface-dark`; generalising the case to
# every directory under `themes/` would redden a shipped theme by design.
#
# MUTATION RECIPES — run with the harness in the managed-service repo:
#   cogni-service/scripts/mutation-check.sh
#
# The expressions below are deliberately UNANCHORED. That harness applies the
# expression with `perl -0pi`, which slurps the whole file, so `^` and `$` bind
# to the start and end of the file rather than of a line; an anchored form is
# rejected as `expr_no_op` and verifies nothing.
#
#   1. Contrast case discriminates per preset:
#      --file cogni-workspace/themes/signal/theme.md \
#      --expr 's/\*\*Text\*\*: `#0F172A`/**Text**: `#FFFFFF`/' \
#      --test 'bash cogni-workspace/tests/test-bundled-presets.sh' \
#      --case bp-03-contrast-signal
#      Expect RED on that id only; boardroom, clean-slate and editorial stay green.
#
#   2. The `## Color Palette` scope reset is load-bearing:
#      --file cogni-workspace/themes/boardroom/theme.md \
#      --expr 's/## Color Palette/## Colour Palette/' \
#      --test 'bash cogni-workspace/tests/test-bundled-presets.sh' \
#      --case bp-03-contrast-boardroom
#      Expect RED — with no palette block matched the extractor yields nothing,
#      which the case reports rather than passing on an empty audit.
#
#   3. The token scan fails closed when git cannot run:
#      --file cogni-workspace/tests/test-bundled-presets.sh \
#      --expr 's/git -C "\$PLUGIN_ROOT\/\.\." grep/git -C \/nonexistent-root grep/' \
#      --test 'bash cogni-workspace/tests/test-bundled-presets.sh' \
#      --case bp-06-no-external-preset-skill
#      Expect RED — a git exiting 128 must not read as "no token found".
#
# All three were run at authoring time and returned `guard_verified`.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
THEMES_DIR="$PLUGIN_ROOT/themes"

# Plain emitters. A colour escape before the label defeats the mutation
# harness's whole-token `FAIL: <case>` match, so a genuinely red case would
# report case_not_found instead.
pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

failures=0

# The archetype presets Operation 5 advertises. Listed rather than globbed:
# the point of the case is that each advertised archetype EXISTS, so a glob
# would pass by finding nothing.
THEMES="boardroom clean-slate signal editorial"

EXTRACT="$(mktemp)"
CLEANUP_FILES="$EXTRACT"
cleanup() { rm -f $CLEANUP_FILES; }
trap cleanup EXIT

cat > "$EXTRACT" <<'PYEOF'
import json, re, sys

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
in_palette = False
out = {}
row = re.compile(r"^- \*\*([A-Za-z][A-Za-z ]*?)\*\*:\s*`(#[0-9A-Fa-f]{6})`")
for ln in lines:
    if ln.startswith("## "):
        in_palette = ln.strip() == "## Color Palette"
        continue
    if not in_palette:
        continue
    m = row.match(ln)
    if m:
        out[re.sub(r"\s+", "-", m.group(1).strip().lower())] = m.group(2)
json.dump(out, sys.stdout)
PYEOF

# --------------------------------------------------------------------------
# bp-01 / bp-02 / bp-03 / bp-04 — per preset
# --------------------------------------------------------------------------

for theme in $THEMES; do
  dir="$THEMES_DIR/$theme"

  # bp-01: both files present.
  if [ -f "$dir/theme.md" ] && [ -f "$dir/manifest.json" ]; then
    pass "bp-01-files-$theme themes/$theme ships theme.md and manifest.json"
  else
    fail "bp-01-files-$theme themes/$theme is missing theme.md or manifest.json"
    continue
  fi

  # bp-02: the manifest validates.
  if python3 "$PLUGIN_ROOT/scripts/validate-theme-manifest.py" "$dir" >/dev/null 2>&1; then
    pass "bp-02-manifest-$theme themes/$theme passes validate-theme-manifest"
  else
    fail "bp-02-manifest-$theme themes/$theme fails validate-theme-manifest"
  fi

  # bp-03: every default contrast pair clears AA, and nothing is left ungraded.
  palette="$(mktemp)"
  CLEANUP_FILES="$CLEANUP_FILES $palette"
  if ! python3 "$EXTRACT" "$dir/theme.md" > "$palette" 2>/dev/null; then
    fail "bp-03-contrast-$theme could not extract a palette from themes/$theme/theme.md"
  else
    verdict="$(python3 "$PLUGIN_ROOT/scripts/check-contrast.py" "$palette" 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)["data"]
except Exception:
    print("UNREADABLE"); raise SystemExit(0)
if d["evaluated"] == 0:
    print("NO_PAIRS"); raise SystemExit(0)
if d["failures"]:
    print("BELOW_AA:" + ", ".join(d["failures"])); raise SystemExit(0)
if d["unclassified"]:
    print("UNCLASSIFIED:" + ", ".join(d["unclassified"])); raise SystemExit(0)
if d["unparsed"]:
    print("UNPARSED:" + ", ".join(sorted(d["unparsed"]))); raise SystemExit(0)
print("OK")
')"
    case "$verdict" in
      OK) pass "bp-03-contrast-$theme themes/$theme clears AA on every default pair" ;;
      NO_PAIRS) fail "bp-03-contrast-$theme themes/$theme produced no gradeable pairs — an empty audit is not a clean one" ;;
      BELOW_AA:*) fail "bp-03-contrast-$theme themes/$theme has pairs below AA: ${verdict#BELOW_AA:}" ;;
      UNCLASSIFIED:*) fail "bp-03-contrast-$theme themes/$theme leaves roles ungraded: ${verdict#UNCLASSIFIED:}" ;;
      UNPARSED:*) fail "bp-03-contrast-$theme themes/$theme has unparseable colour roles: ${verdict#UNPARSED:}" ;;
      *) fail "bp-03-contrast-$theme themes/$theme contrast probe returned an unexpected response: $verdict" ;;
    esac
  fi

  # bp-04: the Phase D voice contract.
  if grep -qF '## Voice & Copy Guidelines' "$dir/theme.md"; then
    pass "bp-04-voice-$theme themes/$theme carries the Voice & Copy Guidelines section"
  else
    fail "bp-04-voice-$theme themes/$theme is missing the Voice & Copy Guidelines section"
  fi
done

# --------------------------------------------------------------------------
# bp-05 — cogni-work leads the catalog
# --------------------------------------------------------------------------

SKILL_MD="$PLUGIN_ROOT/skills/manage-themes/SKILL.md"
op5="$(awk '/^### 5\./{f=1} f&&/^### /&&!/^### 5\./{exit} f' "$SKILL_MD" 2>/dev/null)"
if printf '%s' "$op5" | grep -q 'cogni-work'; then
  pass "bp-05-cogni-work-leads Operation 5 names cogni-work as a candidate"
else
  fail "bp-05-cogni-work-leads Operation 5 does not name cogni-work — the reference theme every consumer exercises must lead the catalog"
fi

# --------------------------------------------------------------------------
# bp-06 — Operation 5 dispatches no external skill
# --------------------------------------------------------------------------
# Scoped to skills/ and agents/, which is where a dispatch can actually happen —
# NOT to all of cogni-workspace, because this file would then match itself: the
# retired token is this guard's own matching data. That is the same exemption
# `tests/test-relocated-skill-hygiene.sh` takes for its spec table, and the
# reason CLAUDE.md records for it — a directory-level spec would fail on the
# files where the literal is the needle rather than the offence.

#
# The exit status is read explicitly rather than through `if git grep`, because
# git grep exits 1 both for "no match" and for a pathspec that names nothing,
# and 128 when it cannot run at all — so a bare `if` reads a vanished directory
# or a crashed git as "no token found". Both scanned directories are asserted
# present first, and only a real exit 1 over present directories is the green
# arm; anything above 1 is a failure to scan, never a clean scan.

if [ ! -d "$PLUGIN_ROOT/skills" ] || [ ! -d "$PLUGIN_ROOT/agents" ]; then
  fail "bp-06-no-external-preset-skill a scanned directory is missing under cogni-workspace, so the theme-factory token scan could not run"
else
  git -C "$PLUGIN_ROOT/.." grep -qI 'theme-factory' -- cogni-workspace/skills cogni-workspace/agents 2>/dev/null
  rc=$?
  case "$rc" in
    0) fail "bp-06-no-external-preset-skill a theme-factory token survives under cogni-workspace skills or agents" ;;
    1) pass "bp-06-no-external-preset-skill no theme-factory token under cogni-workspace skills or agents" ;;
    *) fail "bp-06-no-external-preset-skill git grep could not run (exit $rc), so no verdict was produced" ;;
  esac
fi

# --------------------------------------------------------------------------
# bp-07 — anti-vacuity floor
# --------------------------------------------------------------------------
# Without this a THEMES list emptied by a bad edit would emit zero per-preset
# lines and the suite would exit 0 having asserted nothing.

scanned=0
for theme in $THEMES; do scanned=$((scanned + 1)); done
if [ "$scanned" -ge 4 ]; then
  pass "bp-07-catalog-floor $scanned archetype presets scanned"
else
  fail "bp-07-catalog-floor only $scanned archetype preset(s) scanned; the catalog advertises four"
fi

if [ "$failures" -gt 0 ]; then
  printf '%s\n' "$failures bundled-preset check(s) failed."
  exit 1
fi
printf '%s\n' "All bundled-preset checks passed."
exit 0
