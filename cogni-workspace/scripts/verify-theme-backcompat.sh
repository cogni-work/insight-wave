#!/usr/bin/env bash
# verify-theme-backcompat.sh — End-to-end backwards-compat harness for the
# Theme System v2 contract: discover-themes.py + every known consumer plugin
# must keep working for both tier-0 (manifest-less) and tiered themes.
#
# This is the umbrella check the Theme System v2 epic (#132) gates on. Per-child
# evals each verify their own slice; this script verifies the integration —
# fields added by one child must still be readable by every consumer, and any
# tier-0 theme must keep producing legacy-shaped output.
#
# Usage:
#   bash cogni-workspace/scripts/verify-theme-backcompat.sh [--help] [-v|--verbose] [--regenerate-baseline]
#
# Exit code 0 on success, 1 on the first failure encountered. Failures print a
# triage line indicating which child of the v2 epic likely broke. Run
# `--help` for the full triage table.
#
# This harness also runs in CI, via the thin wrapper suite
# cogni-workspace/tests/test-theme-backcompat.sh that run-plugin-tests.py
# discovers. Keep it runnable with no arguments and no network access.
#
# RESULT-LINE CONTRACT. Every result line is plain, colon-terminated and
# id-first: `PASS: <case-id> <label>` / `FAIL: <case-id> <label>`. The case id is
# what the shared mutation harness addresses, and it matches whole-token —
# `^[ \t]*FAIL:[ \t]+<case>(?:[ \t]|$)` — so no colour, no leading whitespace
# and no colon may sit between the label and the id, or between the id and the
# text. Plainness is NOT gated on a capability probe (`[ -t 1 ]`, `$TERM`): that
# would make parsability depend on where the harness runs, and the colour would
# come back under a pty.
#
# A check's PASS branch and its FAIL branch carry the SAME id, deliberately.
# The mutation harness returns `guard_verified` only when the mutant is red AND
# the restore is green under one `--case`, so a check whose two branches carry
# different ids can never be verified — it degrades to `case_not_found`, which
# reads as a missing case rather than going red. Several `fail` arms may share
# one id (the TIERS_PROBE case does): `fail()` exits on the first failure, so at
# most one FAIL line is ever emitted per run.
#
# `c_skip` and `c_info` are deliberately NOT result lines and keep their colour —
# they must never begin with `PASS:` or `FAIL:`.
#
# This file lives under scripts/, one path segment outside
# scripts/check-result-line-plainness.py's two non-recursive globs
# (`tests/*.sh`, `*/tests/*.sh`), so that guard does not cover it — before or
# after this contract was adopted. The plainness above rests on this file, not
# on CI. Do not "fix" that by moving the harness under tests/: the surviving
# c_skip/c_info escape literals would then be discovered and turn the guard's
# hard clean zero red.
#
# Mutation recipe — verified, replayable. The wrapper is the only runnable entry
# point (this harness takes no per-case selector), and because fail() exits on
# the first failure the mutated file must redden the chosen id before any
# earlier phase can fail.
#
#   M1 -> tbc10-tier0-baseline-match       (verdict: guard_verified)
#     bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#       --root . \
#       --file cogni-workspace/scripts/baselines/_template-tier0-output.json \
#       --expr 's#"source": "standard"#"source": "mutated"#' \
#       --test 'bash cogni-workspace/tests/test-theme-backcompat.sh' \
#       --case tbc10-tier0-baseline-match
#
#   Before this contract existed the harness emitted zero addressable lines, so
#   every invocation of the form above returned case_not_found and no check here
#   could contribute mutation evidence at all.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
DISCOVER_SCRIPT="$PLUGIN_ROOT/scripts/discover-themes.py"
VALIDATOR_SCRIPT="$PLUGIN_ROOT/scripts/validate-theme-manifest.py"
TIER0_BASELINE="$SCRIPT_DIR/baselines/_template-tier0-output.json"
FIXTURE_SLUG="<NORMALIZED_SLUG>"

VERBOSE=0
REGENERATE=0
TMPDIR=""

cleanup() {
  if [[ -n "$TMPDIR" && -d "$TMPDIR" ]]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT

# --------------------------------------------------------------------------
# Output helpers
# --------------------------------------------------------------------------

c_pass() { printf 'PASS: %s\n' "$1"; }
c_fail() { printf 'FAIL: %s\n' "$1"; }
c_skip() { printf "  \033[33mSKIP\033[0m  %s\n" "$1"; }
c_info() { printf "  \033[36mINFO\033[0m  %s\n" "$1"; }

phase() { printf "\n=== %s ===\n" "$1"; }

fail() {
  # Args: <consumer/check> <triage hint>
  c_fail "$1"
  printf "        %s\n" "$2"
  exit 1
}

verbose() {
  [[ "$VERBOSE" -eq 1 ]] && printf "  ....  %s\n" "$1"
  return 0
}

# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

usage() {
  cat <<'EOF'
verify-theme-backcompat.sh — End-to-end backcompat harness for Theme System v2.

Usage:
  verify-theme-backcompat.sh [-v|--verbose] [--regenerate-baseline] [-h|--help]

Phases:
  A. discover-themes invariants
     - tier-0 baseline diff (fixture → discover-themes → normalize → diff)
     - tiered cogni-work surfaces tiers.tokens with tokens.css
  B. workspace-internal consumers (manage-themes)
  C. visual consumers contract checks
     - cogni-workspace: render-html-slides, enrich-report
     - cogni-portfolio: portfolio-dashboard
     - cogni-website: website-build, website-setup
  D. voice consumers (soft) — narrative, sales, research, copywriting

If everything passes, prints "OK: theme backcompat verified" and exits 0.
On the first failure, prints a triage line and exits 1.

Failure-mode triage table

  - tbc10-tier0-baseline-match ("tier-0 baseline mismatch") or
    tbc06-tier0-fixture-discover ("tier-0 fixture discover failed"):
      Likely #126 (cogni-workspace: discover-themes.py reads manifest.json
      with tier-0 fallback). The contract is "no manifest.json => byte-
      identical legacy output"; if discover added a field, this fires.

  - tbc13-cogni-work-tiers-tokens ("cogni-work missing tiers.tokens" or
    "tokens.css absent"):
      Likely #127 (cogni-workspace: migrate cogni-work theme to tiered
      directory structure as Phase 2 reference implementation) or #128
      (manifest schema). Either the migration regressed or the schema
      stopped accepting the existing manifest.

  - tbc14-validator-accepts-cogni-work ("validate-theme-manifest.py rejects
    cogni-work"):
      Likely #128 (manifest schema definition) or #138 (manage-themes deep
      authoring) — schema and authoring surfaces drifted.

  - tbc20-consumer-theme-ref-<plugin>-<skill> ("render-html-slides theme
    contract missing"):
      Likely #129 (the cogni-visual refactor of render-html-slides to consume
      tier-1 tokens and tier-3 component primitives from cogni-work).

  - tbc18-migration-guide-present ("migration guide reference missing"):
      Likely #130 (cogni-workspace: write Theme System v2 migration guide).

  - tbc20-consumer-theme-ref-<plugin>-<skill> ("consumer SKILL.md reference
    missing"):
      Cross-cutting drift; could be a SKILL.md regeneration that lost the
      theme reference. File against the affected plugin.

Regenerating the tier-0 baseline

Only when an intentional schema change ships (reviewed and signed off):

    bash cogni-workspace/scripts/verify-theme-backcompat.sh --regenerate-baseline

The flag rewrites scripts/baselines/_template-tier0-output.json with the
current discover output (path + mtime + slug normalized to placeholders).
Commit the result alongside the schema change.

EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    --regenerate-baseline) REGENERATE=1; shift ;;
    *) printf "ERROR: unknown argument: %s\n" "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# --------------------------------------------------------------------------
# Pre-flight
# --------------------------------------------------------------------------

phase "Pre-flight"

if ! command -v python3 >/dev/null 2>&1; then
  fail "tbc01-python3-available python3 not found on PATH; the harness needs python3 to run discover-themes.py and to normalize JSON."
fi
c_pass "tbc01-python3-available python3 available"

if [[ ! -f "$DISCOVER_SCRIPT" ]]; then
  fail "tbc02-discover-script-present discover-themes.py not at $DISCOVER_SCRIPT (expected under the plugin's own scripts/, beside validate-theme-manifest.py). If the script moved again, update DISCOVER_SCRIPT here to match."
fi
c_pass "tbc02-discover-script-present discover-themes.py present"

if [[ ! -f "$VALIDATOR_SCRIPT" ]]; then
  fail "tbc03-validator-present validate-theme-manifest.py not at $VALIDATOR_SCRIPT. Likely #128 moved the validator."
fi
c_pass "tbc03-validator-present validate-theme-manifest.py present"

if [[ ! -d "$PLUGIN_ROOT/themes/_template" ]]; then
  fail "tbc04-template-theme-present themes/_template/ not present in $PLUGIN_ROOT — the tier-0 reference theme is missing."
fi
c_pass "tbc04-template-theme-present themes/_template/ present"

if [[ ! -d "$PLUGIN_ROOT/themes/cogni-work" ]]; then
  fail "tbc05-cogni-work-theme-present themes/cogni-work/ not present in $PLUGIN_ROOT — the tiered reference theme is missing."
fi
c_pass "tbc05-cogni-work-theme-present themes/cogni-work/ present"

# --------------------------------------------------------------------------
# Helpers — run discover-themes / normalize JSON
# --------------------------------------------------------------------------

# Run discover-themes.py with no auto-discovery (tests must be hermetic).
# Args: <plugin-root> [extra args...]
discover() {
  local proot="$1"; shift
  COGNI_WORKSPACE_ROOT="" python3 "$DISCOVER_SCRIPT" \
    --plugin-root "$proot" --no-discover --pretty "$@"
}

# Normalize discover output for snapshot comparison: rewrite path/mtime/slug
# to fixed placeholders so the baseline is reproducible across machines.
# Reads JSON on stdin, writes JSON on stdout.
#
# Note: we use `python3 -c '...'` rather than `python3 - <<EOF ... EOF` because
# heredoc redirection on `python3 -` overrides stdin and the pipe input is
# silently consumed by the heredoc instead.
normalize_for_baseline() {
  python3 -c '
import json, sys
data = json.load(sys.stdin)
for theme in data:
    if "path" in theme:
        theme["path"] = "<THEME_PATH>"
    if "mtime" in theme:
        theme["mtime"] = 0
    if "slug" in theme:
        theme["slug"] = "<NORMALIZED_SLUG>"
print(json.dumps(data, indent=2, ensure_ascii=False))
'
}

# Build a tier-0 fixture by copying themes/_template/theme.md into a non-
# underscore directory under TMPDIR/themes/<slug>/. Writes the slug to stdout.
build_tier0_fixture() {
  TMPDIR="$(mktemp -d)"
  local slug="template-fixture"
  mkdir -p "$TMPDIR/themes/$slug"
  cp "$PLUGIN_ROOT/themes/_template/theme.md" "$TMPDIR/themes/$slug/theme.md"
  printf "%s\n" "$slug"
}

# --------------------------------------------------------------------------
# Phase A: discover-themes invariants
# --------------------------------------------------------------------------

phase "Phase A — discover-themes invariants"

# A1. Tier-0 baseline.
verbose "Building tier-0 fixture"
build_tier0_fixture >/dev/null
TIER0_OUTPUT="$(discover "$TMPDIR" --no-include-tiers 2>/dev/null)" \
  || fail "tbc06-tier0-fixture-discover tier-0 fixture discover failed" "discover-themes.py exited non-zero against the tier-0 fixture. Likely #126 broke the fallback path."

NORMALIZED="$(printf "%s" "$TIER0_OUTPUT" | normalize_for_baseline)" \
  || fail "tbc07-tier0-normalize tier-0 normalize failed" "JSON normalization failed — output of discover-themes is not valid JSON."

if [[ "$REGENERATE" -eq 1 ]]; then
  printf "%s\n" "$NORMALIZED" > "$TIER0_BASELINE"
  c_info "Regenerated baseline: $TIER0_BASELINE"
  c_pass "tbc08-tier0-baseline-regenerated tier-0 baseline regeneration"
else
  EXPECTED="$(cat "$TIER0_BASELINE")" \
    || fail "tbc09-tier0-baseline-read tier-0 baseline read failed" "Cannot read $TIER0_BASELINE. Run with --regenerate-baseline to recreate it."

  if [[ "$NORMALIZED" != "$EXPECTED" ]]; then
    if [[ "$VERBOSE" -eq 1 ]]; then
      printf "  --- expected\n%s\n  --- actual\n%s\n" "$EXPECTED" "$NORMALIZED" >&2
    fi
    fail "tbc10-tier0-baseline-match tier-0 baseline mismatch" "discover-themes.py output for the tier-0 fixture diverged from $TIER0_BASELINE. Run with -v to see the diff. If the change is intentional, regenerate with --regenerate-baseline."
  fi
  c_pass "tbc10-tier0-baseline-match tier-0 baseline matches snapshot"
fi

# A2. Tiered cogni-work surfaces tiers.tokens.
verbose "Running discover against $PLUGIN_ROOT"
TIERED_OUTPUT="$(discover "$PLUGIN_ROOT" 2>/dev/null)" \
  || fail "tbc11-tiered-discover tiered discover failed" "discover-themes.py exited non-zero against the real plugin root."

TIERS_PROBE="$(printf "%s" "$TIERED_OUTPUT" | python3 -c '
import json, os, sys
data = json.load(sys.stdin)
work = next((t for t in data if t.get("slug") == "cogni-work"), None)
if work is None:
    print("MISSING_THEME"); sys.exit(0)
tiers = work.get("tiers")
if not isinstance(tiers, dict):
    print("MISSING_TIERS"); sys.exit(0)
tokens = tiers.get("tokens")
if not tokens:
    print("MISSING_TOKENS_KEY"); sys.exit(0)
if not os.path.isdir(tokens):
    print(f"TOKENS_DIR_ABSENT:{tokens}"); sys.exit(0)
css = os.path.join(tokens, "tokens.css")
if not os.path.isfile(css):
    print(f"TOKENS_CSS_ABSENT:{css}"); sys.exit(0)
print("OK")
')" || fail "tbc12-tiered-probe tiered probe failed" "JSON parse failed reading discover output."

case "$TIERS_PROBE" in
  OK) c_pass "tbc13-cogni-work-tiers-tokens cogni-work surfaces tiers.tokens with tokens.css" ;;
  MISSING_THEME) fail "tbc13-cogni-work-tiers-tokens cogni-work missing from discover" "discover-themes.py did not return cogni-work. Likely #127 regressed the migration." ;;
  MISSING_TIERS) fail "tbc13-cogni-work-tiers-tokens cogni-work missing tiers.tokens" "discover output for cogni-work has no 'tiers' key. Likely #126 (manifest fallback) or #128 (schema). Check $PLUGIN_ROOT/themes/cogni-work/manifest.json." ;;
  MISSING_TOKENS_KEY) fail "tbc13-cogni-work-tiers-tokens cogni-work tiers.tokens absent" "manifest.json declares no tokens tier. Likely #127/#128 — manifest does not match the v2 schema." ;;
  TOKENS_DIR_ABSENT:*) fail "tbc13-cogni-work-tiers-tokens cogni-work tokens dir absent" "tiers.tokens resolves to a path that does not exist: ${TIERS_PROBE#TOKENS_DIR_ABSENT:}. Likely #127 dropped the tokens/ dir." ;;
  TOKENS_CSS_ABSENT:*) fail "tbc13-cogni-work-tiers-tokens cogni-work tokens.css absent" "tokens dir exists but tokens.css is missing: ${TIERS_PROBE#TOKENS_CSS_ABSENT:}. Likely #136 (tier-1 tokens.css) regressed." ;;
  *) fail "tbc13-cogni-work-tiers-tokens tiered probe unknown response" "Unexpected probe output: $TIERS_PROBE" ;;
esac

# A3. Every bundled theme except _template validates and is discoverable.
# _template is excluded because discover-themes.py filters underscore-prefixed
# directories by design; it is covered by the tier-0 fixture above instead.
# The slug is the per-case discriminator, so a theme added to the catalog gets
# its own addressable result line rather than sharing one.
for theme_dir in "$PLUGIN_ROOT"/themes/*/; do
  theme="$(basename "$theme_dir")"
  case "$theme" in _*) continue ;; esac

  if python3 "$VALIDATOR_SCRIPT" "$theme_dir" >/dev/null 2>&1; then
    c_pass "tbc24-bundled-theme-valid-$theme validate-theme-manifest accepts themes/$theme"
  else
    fail "tbc24-bundled-theme-valid-$theme validate-theme-manifest rejects themes/$theme" "Run \`python3 $VALIDATOR_SCRIPT $theme_dir\` for the error. A bundled theme must be schema-valid before it is offered as a preset."
  fi

  if printf "%s" "$TIERED_OUTPUT" | python3 -c '
import json, sys
want = sys.argv[1]
sys.exit(0 if any(t.get("slug") == want for t in json.load(sys.stdin)) else 1)
' "$theme"; then
    c_pass "tbc25-bundled-theme-discovered-$theme discover returns themes/$theme"
  else
    fail "tbc25-bundled-theme-discovered-$theme discover does not return themes/$theme" "The directory exists but discover-themes.py did not surface it, so Operation 11 would never offer it."
  fi
done

# --------------------------------------------------------------------------
# Phase B: workspace-internal consumers
# --------------------------------------------------------------------------

phase "Phase B — manage-themes"

# B1. validate-theme-manifest accepts cogni-work.
if python3 "$VALIDATOR_SCRIPT" "$PLUGIN_ROOT/themes/cogni-work" >/dev/null 2>&1; then
  c_pass "tbc14-validator-accepts-cogni-work validate-theme-manifest accepts cogni-work"
else
  fail "tbc14-validator-accepts-cogni-work validate-theme-manifest rejects cogni-work" "Run \`python3 $VALIDATOR_SCRIPT $PLUGIN_ROOT/themes/cogni-work\` for the error. Likely #128 (schema) or #138 (manage-themes authoring drift)."
fi

# B2. discover-themes returns cogni-work in default invocation (tier-aware).
if printf "%s" "$TIERED_OUTPUT" | python3 -c 'import json,sys; sys.exit(0 if any(t.get("slug")=="cogni-work" for t in json.load(sys.stdin)) else 1)'; then
  c_pass "tbc15-discover-returns-cogni-work discover returns cogni-work"
else
  fail "tbc15-discover-returns-cogni-work discover does not return cogni-work" "Already failed Phase A; manage-themes Operation 11 would not surface the theme to the user."
fi

# B3. manage-themes SKILL.md still references discover-themes.py. The picker
# folded into manage-themes as Operation 11, so this is the surviving surface
# that has to name the enumerator it drives.
MANAGE_SKILL="$PLUGIN_ROOT/skills/manage-themes/SKILL.md"
if [[ -f "$MANAGE_SKILL" ]] && grep -q "discover-themes" "$MANAGE_SKILL"; then
  c_pass "tbc16-manage-themes-references-discover manage-themes SKILL.md references discover-themes"
else
  fail "tbc16-manage-themes-references-discover manage-themes SKILL.md theme reference missing" "$MANAGE_SKILL no longer mentions discover-themes. Likely a SKILL.md drift."
fi

# B4. manage-themes SKILL.md still references manifest.json.
MANAGE_SKILL="$PLUGIN_ROOT/skills/manage-themes/SKILL.md"
if [[ -f "$MANAGE_SKILL" ]] && grep -q "manifest\.json" "$MANAGE_SKILL"; then
  c_pass "tbc17-manage-themes-references-manifest manage-themes SKILL.md references manifest.json"
else
  fail "tbc17-manage-themes-references-manifest manage-themes SKILL.md manifest reference missing" "$MANAGE_SKILL no longer mentions manifest.json. Likely #138 regressed the deep-authoring documentation."
fi

# B5. Migration guide present.
MIGRATION_GUIDE="$PLUGIN_ROOT/docs/theme-system-v2-migration.md"
if [[ -f "$MIGRATION_GUIDE" ]]; then
  c_pass "tbc18-migration-guide-present theme-system-v2 migration guide present"
else
  fail "tbc18-migration-guide-present migration guide reference missing" "$MIGRATION_GUIDE not found. Likely #130 was reverted or the path moved."
fi

# --------------------------------------------------------------------------
# Phase C: visual consumers (contract-shape only — not full render)
# --------------------------------------------------------------------------

phase "Phase C — visual consumers"

# Each entry: <plugin-name>:<skill-name>
# The harness asserts the skill's SKILL.md still contains *some* theme-contract
# reference (theme.md, theme_slug, or themes/). The retired picker's own name
# was a fourth alternative here until it folded into manage-themes; a retired
# skill name can only ever produce a false green, so it is not a needle. It
# does NOT run
# the full pipeline — those are each consumer's own evals.
VISUAL_CONSUMERS=(
  "cogni-workspace:render-html-slides"
  "cogni-workspace:enrich-report"
  # The three story-to-* brief producers were consumers here until they retired
  # in favour of text-to-narrative, which hands a design brief to Claude Design
  # and reads no theme; the renderers above are the surviving theme readers.
  "cogni-portfolio:portfolio-dashboard"
  "cogni-website:website-build"
  "cogni-website:website-setup"
)

for entry in "${VISUAL_CONSUMERS[@]}"; do
  plugin="${entry%%:*}"
  skill="${entry#*:}"
  # Case ids carry a per-iteration slug or every consumer would share one token.
  # Parameter expansion, not `tr` — and the colon has to go: the shared mutation
  # harness needs whitespace or end-of-line straight after the case token.
  entry_slug="${entry//:/-}"
  skill_md="$REPO_ROOT/$plugin/skills/$skill/SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    fail "tbc19-consumer-skill-present-$entry_slug SKILL.md not present at expected path" "$skill_md is missing. A listed visual consumer lost its SKILL.md — either the skill was renamed or removed (update VISUAL_CONSUMERS) or a regeneration dropped the file."
  fi
  if grep -qE 'theme\.md|theme_slug|themes/' "$skill_md"; then
    c_pass "tbc20-consumer-theme-ref-$entry_slug references the theme contract"
  else
    fail "tbc20-consumer-theme-ref-$entry_slug SKILL.md theme reference missing" "$skill_md no longer mentions the theme contract. Likely a SKILL.md regeneration dropped the reference."
  fi
done

# --------------------------------------------------------------------------
# Phase D: voice consumers (soft check — theme.md voice section parseable)
# --------------------------------------------------------------------------

phase "Phase D — voice consumers (soft)"

# These plugins read the voice section of theme.md indirectly (via prompt
# templates or copywriting guidance), not via discover-themes. The smoke test
# is: theme.md (both tier-0 and tiered references) must contain a parseable
# "Voice & Copy Guidelines" section so any prompt that includes it does not
# choke on a missing block.
# cogni-narrative, cogni-copywriting and cogni-research were retired; their voice
# consumers are now this plugin's own narrative and copywriter skills, which the
# theme.md contract covers directly. Listing retired names here made the loop below
# skip silently forever rather than verify anything.
VOICE_PLUGINS=(cogni-sales)
VOICE_HEADER='## Voice & Copy Guidelines'

# Enumerated rather than hardcoded: a theme added to themes/ used to get no case
# at all, so the catalog could grow past the checks silently. The slug is the
# per-case discriminator, so each theme owns its own addressable result line.
for theme_dir in "$PLUGIN_ROOT"/themes/*/; do
  theme="$(basename "$theme_dir")"
  theme_file="$PLUGIN_ROOT/themes/$theme/theme.md"
  if grep -qF "$VOICE_HEADER" "$theme_file"; then
    c_pass "tbc21-voice-section-$theme themes/$theme/theme.md has Voice & Copy Guidelines section"
  else
    fail "tbc21-voice-section-$theme voice section missing in themes/$theme/theme.md" "Voice consumers (${VOICE_PLUGINS[*]}) include this section in prompts; without it, copy generation drifts. Likely #127 (cogni-work migration) or a tier-0 template regression."
  fi
done

for plugin in "${VOICE_PLUGINS[@]}"; do
  if [[ ! -d "$REPO_ROOT/$plugin" ]]; then
    c_skip "$plugin — plugin directory not present in $REPO_ROOT"
    continue
  fi
  c_pass "tbc22-voice-plugin-present-$plugin $plugin present (voice section verified above is the contract for this plugin)"
done

# --------------------------------------------------------------------------
# Phase E: external consumers (informational)
# --------------------------------------------------------------------------

phase "Phase E — external consumers (informational)"

# document-skills is a sibling skill collection that lives outside this repo.
# We can only assert that *if* it is present in the repo root, its theme
# contract still resolves; otherwise we note it for the runner.
for ext in "document-skills:pptx" "document-skills:docx"; do
  plugin="${ext%%:*}"
  skill="${ext#*:}"
  ext_slug="${ext//:/-}"
  skill_md="$REPO_ROOT/$plugin/skills/$skill/SKILL.md"
  if [[ -f "$skill_md" ]]; then
    if grep -qE 'theme\.md|theme_slug|themes/' "$skill_md"; then
      c_pass "tbc23-external-theme-ref-$ext_slug $ext references the theme contract"
    else
      c_info "$ext present but does not reference the theme contract — informational only"
    fi
  else
    c_info "$ext not present in this checkout (external skill collection); harness cannot verify."
  fi
done

# --------------------------------------------------------------------------
# Done
# --------------------------------------------------------------------------

phase "Result"
printf "OK: theme backcompat verified across %d phases\n" 5
exit 0
