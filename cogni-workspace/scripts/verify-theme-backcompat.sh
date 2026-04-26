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

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/.." && pwd)"
DISCOVER_SCRIPT="$PLUGIN_ROOT/skills/pick-theme/scripts/discover-themes.py"
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

c_pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
c_fail() { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }
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
  B. workspace-internal consumers (pick-theme, manage-themes)
  C. visual consumers contract checks
     - cogni-visual: render-html-slides, enrich-report, story-to-* siblings
     - cogni-portfolio: portfolio-dashboard
     - cogni-website: website-build, website-setup
  D. voice consumers (soft) — narrative, sales, research, copywriting

If everything passes, prints "OK: theme backcompat verified" and exits 0.
On the first failure, prints a triage line and exits 1.

Failure-mode triage table

  - "tier-0 baseline mismatch" or "tier-0 fixture discover failed":
      Likely #126 (cogni-workspace: discover-themes.py reads manifest.json
      with tier-0 fallback). The contract is "no manifest.json => byte-
      identical legacy output"; if discover added a field, this fires.

  - "cogni-work missing tiers.tokens" or "tokens.css absent":
      Likely #127 (cogni-workspace: migrate cogni-work theme to tiered
      directory structure as Phase 2 reference implementation) or #128
      (manifest schema). Either the migration regressed or the schema
      stopped accepting the existing manifest.

  - "validate-theme-manifest.py rejects cogni-work":
      Likely #128 (manifest schema definition) or #138 (manage-themes deep
      authoring) — schema and authoring surfaces drifted.

  - "render-html-slides theme contract missing":
      Likely #129 (cogni-visual: refactor render-html-slides to consume
      tier-1 tokens and tier-3 component primitives from cogni-work).

  - "migration guide reference missing":
      Likely #130 (cogni-workspace: write Theme System v2 migration guide).

  - "consumer SKILL.md reference missing":
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
  fail "pre-flight" "python3 not found on PATH; the harness needs python3 to run discover-themes.py and to normalize JSON."
fi
c_pass "python3 available"

if [[ ! -f "$DISCOVER_SCRIPT" ]]; then
  fail "pre-flight" "discover-themes.py not at $DISCOVER_SCRIPT (expected under skills/pick-theme/scripts/). Likely #126 moved the script — update DISCOVER_SCRIPT here to match."
fi
c_pass "discover-themes.py present"

if [[ ! -f "$VALIDATOR_SCRIPT" ]]; then
  fail "pre-flight" "validate-theme-manifest.py not at $VALIDATOR_SCRIPT. Likely #128 moved the validator."
fi
c_pass "validate-theme-manifest.py present"

if [[ ! -d "$PLUGIN_ROOT/themes/_template" ]]; then
  fail "pre-flight" "themes/_template/ not present in $PLUGIN_ROOT — the tier-0 reference theme is missing."
fi
c_pass "themes/_template/ present"

if [[ ! -d "$PLUGIN_ROOT/themes/cogni-work" ]]; then
  fail "pre-flight" "themes/cogni-work/ not present in $PLUGIN_ROOT — the tiered reference theme is missing."
fi
c_pass "themes/cogni-work/ present"

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
  || fail "tier-0 fixture discover failed" "discover-themes.py exited non-zero against the tier-0 fixture. Likely #126 broke the fallback path."

NORMALIZED="$(printf "%s" "$TIER0_OUTPUT" | normalize_for_baseline)" \
  || fail "tier-0 normalize failed" "JSON normalization failed — output of discover-themes is not valid JSON."

if [[ "$REGENERATE" -eq 1 ]]; then
  printf "%s\n" "$NORMALIZED" > "$TIER0_BASELINE"
  c_info "Regenerated baseline: $TIER0_BASELINE"
  c_pass "tier-0 baseline regeneration"
else
  EXPECTED="$(cat "$TIER0_BASELINE")" \
    || fail "tier-0 baseline read failed" "Cannot read $TIER0_BASELINE. Run with --regenerate-baseline to recreate it."

  if [[ "$NORMALIZED" != "$EXPECTED" ]]; then
    if [[ "$VERBOSE" -eq 1 ]]; then
      printf "  --- expected\n%s\n  --- actual\n%s\n" "$EXPECTED" "$NORMALIZED" >&2
    fi
    fail "tier-0 baseline mismatch" "discover-themes.py output for the tier-0 fixture diverged from $TIER0_BASELINE. Run with -v to see the diff. If the change is intentional, regenerate with --regenerate-baseline."
  fi
  c_pass "tier-0 baseline matches snapshot"
fi

# A2. Tiered cogni-work surfaces tiers.tokens.
verbose "Running discover against $PLUGIN_ROOT"
TIERED_OUTPUT="$(discover "$PLUGIN_ROOT" 2>/dev/null)" \
  || fail "tiered discover failed" "discover-themes.py exited non-zero against the real plugin root."

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
')" || fail "tiered probe failed" "JSON parse failed reading discover output."

case "$TIERS_PROBE" in
  OK) c_pass "cogni-work surfaces tiers.tokens with tokens.css" ;;
  MISSING_THEME) fail "cogni-work missing from discover" "discover-themes.py did not return cogni-work. Likely #127 regressed the migration." ;;
  MISSING_TIERS) fail "cogni-work missing tiers.tokens" "discover output for cogni-work has no 'tiers' key. Likely #126 (manifest fallback) or #128 (schema). Check $PLUGIN_ROOT/themes/cogni-work/manifest.json." ;;
  MISSING_TOKENS_KEY) fail "cogni-work tiers.tokens absent" "manifest.json declares no tokens tier. Likely #127/#128 — manifest does not match the v2 schema." ;;
  TOKENS_DIR_ABSENT:*) fail "cogni-work tokens dir absent" "tiers.tokens resolves to a path that does not exist: ${TIERS_PROBE#TOKENS_DIR_ABSENT:}. Likely #127 dropped the tokens/ dir." ;;
  TOKENS_CSS_ABSENT:*) fail "cogni-work tokens.css absent" "tokens dir exists but tokens.css is missing: ${TIERS_PROBE#TOKENS_CSS_ABSENT:}. Likely #136 (tier-1 tokens.css) regressed." ;;
  *) fail "tiered probe unknown response" "Unexpected probe output: $TIERS_PROBE" ;;
esac

# --------------------------------------------------------------------------
# Phase B: workspace-internal consumers
# --------------------------------------------------------------------------

phase "Phase B — pick-theme, manage-themes"

# B1. validate-theme-manifest accepts cogni-work.
if python3 "$VALIDATOR_SCRIPT" "$PLUGIN_ROOT/themes/cogni-work" >/dev/null 2>&1; then
  c_pass "validate-theme-manifest accepts cogni-work"
else
  fail "validate-theme-manifest rejects cogni-work" "Run \`python3 $VALIDATOR_SCRIPT $PLUGIN_ROOT/themes/cogni-work\` for the error. Likely #128 (schema) or #138 (manage-themes authoring drift)."
fi

# B2. discover-themes returns cogni-work in default invocation (tier-aware).
if printf "%s" "$TIERED_OUTPUT" | python3 -c 'import json,sys; sys.exit(0 if any(t.get("slug")=="cogni-work" for t in json.load(sys.stdin)) else 1)'; then
  c_pass "discover returns cogni-work"
else
  fail "discover does not return cogni-work" "Already failed Phase A; pick-theme would not surface the theme to the user."
fi

# B3. pick-theme SKILL.md still references discover-themes.py.
PICK_SKILL="$PLUGIN_ROOT/skills/pick-theme/SKILL.md"
if [[ -f "$PICK_SKILL" ]] && grep -q "discover-themes" "$PICK_SKILL"; then
  c_pass "pick-theme SKILL.md references discover-themes"
else
  fail "pick-theme SKILL.md theme reference missing" "$PICK_SKILL no longer mentions discover-themes. Likely a SKILL.md drift."
fi

# B4. manage-themes SKILL.md still references manifest.json.
MANAGE_SKILL="$PLUGIN_ROOT/skills/manage-themes/SKILL.md"
if [[ -f "$MANAGE_SKILL" ]] && grep -q "manifest\.json" "$MANAGE_SKILL"; then
  c_pass "manage-themes SKILL.md references manifest.json"
else
  fail "manage-themes SKILL.md manifest reference missing" "$MANAGE_SKILL no longer mentions manifest.json. Likely #138 regressed the deep-authoring documentation."
fi

# B5. Migration guide present.
MIGRATION_GUIDE="$PLUGIN_ROOT/docs/theme-system-v2-migration.md"
if [[ -f "$MIGRATION_GUIDE" ]]; then
  c_pass "theme-system-v2 migration guide present"
else
  fail "migration guide reference missing" "$MIGRATION_GUIDE not found. Likely #130 was reverted or the path moved."
fi

# --------------------------------------------------------------------------
# Phase C: visual consumers (contract-shape only — not full render)
# --------------------------------------------------------------------------

phase "Phase C — visual consumers"

# Each entry: <plugin-name>:<skill-name>
# The harness asserts the skill's SKILL.md still contains *some* theme-contract
# reference (theme.md, theme_slug, pick-theme, or themes/). It does NOT run
# the full pipeline — those are each consumer's own evals.
VISUAL_CONSUMERS=(
  "cogni-visual:render-html-slides"
  "cogni-visual:enrich-report"
  "cogni-visual:story-to-infographic"
  "cogni-visual:story-to-slides"
  "cogni-visual:story-to-storyboard"
  "cogni-visual:story-to-web"
  "cogni-portfolio:portfolio-dashboard"
  "cogni-website:website-build"
  "cogni-website:website-setup"
)

for entry in "${VISUAL_CONSUMERS[@]}"; do
  plugin="${entry%%:*}"
  skill="${entry#*:}"
  skill_md="$REPO_ROOT/$plugin/skills/$skill/SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    c_skip "$entry — SKILL.md not present at expected path"
    continue
  fi
  if grep -qE 'theme\.md|theme_slug|pick-theme|themes/' "$skill_md"; then
    c_pass "$entry references the theme contract"
  else
    fail "$entry SKILL.md theme reference missing" "$skill_md no longer mentions the theme contract. Likely a SKILL.md regeneration dropped the reference."
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
VOICE_PLUGINS=(cogni-narrative cogni-sales cogni-research cogni-copywriting)
VOICE_HEADER='## Voice & Copy Guidelines'

for theme in _template cogni-work; do
  theme_file="$PLUGIN_ROOT/themes/$theme/theme.md"
  if grep -qF "$VOICE_HEADER" "$theme_file"; then
    c_pass "themes/$theme/theme.md has Voice & Copy Guidelines section"
  else
    fail "voice section missing in themes/$theme/theme.md" "Voice consumers (${VOICE_PLUGINS[*]}) include this section in prompts; without it, copy generation drifts. Likely #127 (cogni-work migration) or a tier-0 template regression."
  fi
done

for plugin in "${VOICE_PLUGINS[@]}"; do
  if [[ ! -d "$REPO_ROOT/$plugin" ]]; then
    c_skip "$plugin — plugin directory not present in $REPO_ROOT"
    continue
  fi
  c_pass "$plugin present (voice section verified above is the contract for this plugin)"
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
  skill_md="$REPO_ROOT/$plugin/skills/$skill/SKILL.md"
  if [[ -f "$skill_md" ]]; then
    if grep -qE 'theme\.md|theme_slug|pick-theme|themes/' "$skill_md"; then
      c_pass "$ext references the theme contract"
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
