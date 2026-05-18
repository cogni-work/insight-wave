#!/usr/bin/env bash
# verify-claude-design-importer.sh — End-to-end harness for the Claude Design
# bundle importer (RFC #132 Phase 3). Builds synthetic fixtures inline,
# exercises the success path, strict-abort path, idempotency, overwrite
# gate, and dry-run; asserts the materialised structure matches the
# mapping contract.
#
# Run alongside verify-theme-backcompat.sh before any PR that touches
# scripts/import-claude-design-bundle.py or references/claude-design-bundle-mapping.md.
#
# Usage:
#   bash cogni-workspace/scripts/verify-claude-design-importer.sh [-v|--verbose] [-h|--help]
#
# Exit 0 on success, 1 on the first failure with a triage line.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMPORTER="$SCRIPT_DIR/import-claude-design-bundle.py"

VERBOSE=0
TMPDIR=""

cleanup() {
  if [[ -n "$TMPDIR" && -d "$TMPDIR" ]]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT

c_pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
c_fail() { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }
c_info() { printf "  \033[36mINFO\033[0m  %s\n" "$1"; }

phase() { printf "\n=== %s ===\n" "$1"; }

fail() {
  # Args: <check> <triage hint>
  c_fail "$1"
  printf "        %s\n" "$2"
  exit 1
}

verbose() {
  [[ "$VERBOSE" -eq 1 ]] && printf "  ....  %s\n" "$1"
  return 0
}

usage() {
  cat <<'EOF'
verify-claude-design-importer.sh — Harness for import-claude-design-bundle.py.

Phases:
  A. Pre-flight (importer present, python3 available)
  B. Success path — synthetic compliant bundle materialises cleanly (voice section from bundle)
  C. Auto-inject — bundle missing ## Voice & Copy Guidelines still succeeds with stub
  D. Idempotency — re-running with same input is a sha256-matched no-op
  E. Overwrite gate — non-empty target refused without --allow-overwrite
  F. Dry-run — extracts and reports but writes nothing

If everything passes, prints "OK: claude-design importer verified" and exits 0.

Failure-mode triage

  - "success path: importer failed":
      Either the importer regressed or the synthetic fixture diverged from
      the bundle contract. Check the JSON 'error' field in the harness
      output for the abort reason. Likely a mapping change in
      references/claude-design-bundle-mapping.md that the importer has not
      caught up with.

  - "success path: voice section copied incorrectly":
      The bundle's voice section did not survive the copy. Likely a copy
      bug in run() — theme.md materialisation step skipped or wrong source
      path; or materialise_theme_md() lost upstream content.

  - "auto-inject: importer did not stub the voice section":
      The importer regressed the auto-inject policy. Either materialise_theme_md()
      stopped detecting the missing header or the VOICE_STUB constant is empty.
      Without the stub, Phase D of verify-theme-backcompat.sh will fail.

  - "auto-inject: voice_section flag wrong":
      The success envelope's voice_section field disagrees with what
      ended up in the file. Verify materialise_theme_md() returns the
      same string it materialised.

  - "idempotency: re-run was not a no-op":
      The sha256 short-circuit in run() regressed. Re-imports will churn
      the theme directory unnecessarily.

  - "overwrite gate: non-empty target was overwritten without --allow-overwrite":
      Safety regression. The gate exists so users don't accidentally
      destroy local hand-edits.

  - "dry-run: --dry-run still wrote files":
      Side-effect leak in run(). Verify the dry_run guard returns before
      mkdir/copy.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    *) printf "ERROR: unknown argument: %s\n" "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# --------------------------------------------------------------------------
# Pre-flight
# --------------------------------------------------------------------------

phase "Phase A — pre-flight"

if ! command -v python3 >/dev/null 2>&1; then
  fail "pre-flight" "python3 not found on PATH."
fi
c_pass "python3 available"

if [[ ! -f "$IMPORTER" ]]; then
  fail "pre-flight" "importer not found at $IMPORTER."
fi
c_pass "importer present"

TMPDIR="$(mktemp -d)"
verbose "scratch dir: $TMPDIR"

# --------------------------------------------------------------------------
# Fixture builders
# --------------------------------------------------------------------------

build_compliant_bundle() {
  # Args: <slug> <bundle-out-path>
  local slug="$1" out="$2" dir
  dir="$TMPDIR/${slug}-build"
  mkdir -p "$dir/${slug}-design-system/project/preview"
  cat > "$dir/${slug}-design-system/project/${slug}-theme.md" <<EOF
# ${slug}

A synthetic theme for the importer harness.

## Color Palette
- **Primary**: \`#000000\`
- **Accent**: \`#FF00FF\`

## Voice & Copy Guidelines

Voice is direct.

- Address: "you" to the reader.
- No emoji.

## Source
- **Origin**: synthetic fixture
EOF
  # NB: --fs-h2/--lh-h2/--ls-h2 are packed on one line on purpose — this is
  # the multi-decl-per-line shape real Claude Design bundles use for the
  # typography scale, and the importer's regex must capture every decl on
  # such lines (regression test for the bug fixed alongside this harness).
  cat > "$dir/${slug}-design-system/project/colors_and_type.css" <<'EOF'
:root {
  --cw-primary: #000000;
  --cw-accent: #FF00FF;
  --cw-bg: #FFFFFF;
  --fs-h1: 42px;
  --lh-h1: 1.1;
  --fs-h2:      32px;   --lh-h2:      1.15;  --ls-h2:      -0.02em;
  --font-sans: 'DM Sans', system-ui, sans-serif;
  --sp-3: 12px;
  --r-md: 8px;
  --sh-sm: 0 1px 3px rgba(0,0,0,0.04);
  --ease-standard: cubic-bezier(0.2, 0, 0, 1);
  --dur-fast: 150ms;
}
EOF
  printf '<div class="card">test</div>\n' > "$dir/${slug}-design-system/project/preview/components-cards.html"
  printf '<div>specimen</div>\n' > "$dir/${slug}-design-system/project/preview/colors-core.html"
  (cd "$dir" && tar -czf "$out" "${slug}-design-system")
}

build_novoice_bundle() {
  # Args: <slug> <bundle-out-path>
  local slug="$1" out="$2" dir
  dir="$TMPDIR/${slug}-build"
  mkdir -p "$dir/${slug}-design-system/project"
  cat > "$dir/${slug}-design-system/project/${slug}-theme.md" <<EOF
# ${slug}

## Color Palette
- Primary: #000

## Source
- Origin: synthetic fixture
EOF
  cat > "$dir/${slug}-design-system/project/colors_and_type.css" <<'EOF'
:root { --cw-primary: #000000; }
EOF
  (cd "$dir" && tar -czf "$out" "${slug}-design-system")
}

# Pull a JSON field out of importer output.
json_field() {
  # Args: <json-string> <python expression on `d`>
  python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print($2)" <<< "$1"
}

# --------------------------------------------------------------------------
# Phase B — success path
# --------------------------------------------------------------------------

phase "Phase B — success path on compliant fixture"

COMPLIANT_BUNDLE="$TMPDIR/compliant.tar.gz"
COMPLIANT_TARGET="$TMPDIR/compliant-target"
build_compliant_bundle "harness-good" "$COMPLIANT_BUNDLE"
verbose "built compliant fixture at $COMPLIANT_BUNDLE"

SUCCESS_OUTPUT="$(python3 "$IMPORTER" --bundle "$COMPLIANT_BUNDLE" --target "$COMPLIANT_TARGET" 2>/dev/null)" \
  || fail "success path: importer failed" "Compliant fixture should import cleanly. Output: $SUCCESS_OUTPUT"

SUCCESS="$(json_field "$SUCCESS_OUTPUT" "d['success']")"
[[ "$SUCCESS" == "True" ]] \
  || fail "success path: importer reported failure" "Compliant fixture should produce success:true. Output: $SUCCESS_OUTPUT"
c_pass "compliant fixture imports successfully"

VOICE_FLAG="$(json_field "$SUCCESS_OUTPUT" "d['data'].get('voice_section')")"
[[ "$VOICE_FLAG" == "bundled" ]] \
  || fail "success path: voice_section flag wrong" "Compliant fixture ships voice section in bundle; expected voice_section='bundled', got '$VOICE_FLAG'."
c_pass "voice_section reports 'bundled' when section is in the bundle"

# Materialised structure assertions.
for required in theme.md manifest.json tokens/tokens.css tokens/colors.json .claude-design-source components/web/cards.html; do
  if [[ ! -e "$COMPLIANT_TARGET/$required" ]]; then
    fail "success path: missing materialised file" "Expected $COMPLIANT_TARGET/$required after import."
  fi
done
c_pass "all required tier files materialised"

# Voice section actually copied.
if ! grep -qF "## Voice & Copy Guidelines" "$COMPLIANT_TARGET/theme.md"; then
  fail "success path: voice section copied incorrectly" "theme.md in target lacks the voice header even though the importer reported success."
fi
c_pass "voice section preserved in materialised theme.md"

# Specimen skipped.
if [[ -e "$COMPLIANT_TARGET/components/web/colors-core.html" ]]; then
  fail "success path: specimen leaked into components" "colors-core.html is a specimen and should be skipped per the allowlist."
fi
c_pass "specimen correctly skipped"

# Sidecar fields present.
for field in url sha256 imported_at bundle_root importer_version; do
  if ! grep -q "\"$field\"" "$COMPLIANT_TARGET/.claude-design-source"; then
    fail "success path: sidecar missing field" "Sidecar lacks $field — re-sync semantics depend on it."
  fi
done
c_pass "sidecar contains all required fields"

# Multi-decl-per-line regression: the fixture's CSS packs --fs-h2, --lh-h2,
# and --ls-h2 onto a single line. All three must land in typography.json.
# If any are missing, the regex anchor regression has come back.
for key in size-h2 line-height-h2 tracking-h2; do
  if ! grep -q "\"$key\"" "$COMPLIANT_TARGET/tokens/typography.json"; then
    fail "success path: multi-decl typography key dropped" "typography.json is missing '$key' — the importer's _DECL regex is anchoring on line start/end again, silently dropping every multi-decl line. Real bundles pack the typography scale this way, so the regression breaks every materialised theme."
  fi
done
c_pass "multi-decl-per-line CSS declarations all captured"

# --------------------------------------------------------------------------
# Phase C — auto-inject on missing voice section
# --------------------------------------------------------------------------

phase "Phase C — auto-inject voice stub when bundle omits the section"

NOVOICE_BUNDLE="$TMPDIR/novoice.tar.gz"
NOVOICE_TARGET="$TMPDIR/novoice-target"
build_novoice_bundle "harness-novoice" "$NOVOICE_BUNDLE"

NOVOICE_OUTPUT="$(python3 "$IMPORTER" --bundle "$NOVOICE_BUNDLE" --target "$NOVOICE_TARGET" 2>/dev/null)"
NOVOICE_SUCCESS="$(json_field "$NOVOICE_OUTPUT" "d['success']")"
[[ "$NOVOICE_SUCCESS" == "True" ]] \
  || fail "auto-inject: importer did not stub the voice section" "No-voice bundle should import successfully with stub. Output: $NOVOICE_OUTPUT"
c_pass "no-voice bundle imports successfully"

NOVOICE_FLAG="$(json_field "$NOVOICE_OUTPUT" "d['data'].get('voice_section')")"
[[ "$NOVOICE_FLAG" == "auto-injected-stub" ]] \
  || fail "auto-inject: voice_section flag wrong" "Expected voice_section='auto-injected-stub', got '$NOVOICE_FLAG'."
c_pass "voice_section reports 'auto-injected-stub' when bundle omits the section"

# The materialised theme.md must contain the canonical header.
if ! grep -qF "## Voice & Copy Guidelines" "$NOVOICE_TARGET/theme.md"; then
  fail "auto-inject: header missing from materialised theme.md" "verify-theme-backcompat.sh Phase D would fail — the stub did not land."
fi
c_pass "materialised theme.md contains the voice header"

# Stub text must self-identify so future readers can tell it apart from real content.
if ! grep -qF "auto-inserted" "$NOVOICE_TARGET/theme.md"; then
  fail "auto-inject: stub not self-identifying" "Stub should call itself out (e.g. 'auto-inserted by import-claude-design-bundle.py') so it doesn't masquerade as authored voice content."
fi
c_pass "stub self-identifies as machine-generated"

# Order must be preserved: voice section before Source.
VOICE_LINE="$(grep -n '^## Voice & Copy Guidelines' "$NOVOICE_TARGET/theme.md" | head -1 | cut -d: -f1)"
SOURCE_LINE="$(grep -n '^## Source' "$NOVOICE_TARGET/theme.md" | head -1 | cut -d: -f1)"
if [[ -n "$VOICE_LINE" && -n "$SOURCE_LINE" && "$VOICE_LINE" -ge "$SOURCE_LINE" ]]; then
  fail "auto-inject: section order wrong" "Voice section (line $VOICE_LINE) must precede Source section (line $SOURCE_LINE) to preserve canonical order."
fi
c_pass "voice section inserted before Source section"

# --------------------------------------------------------------------------
# Phase D — idempotency
# --------------------------------------------------------------------------

phase "Phase D — idempotency"

IDEMPOTENT_OUTPUT="$(python3 "$IMPORTER" --bundle "$COMPLIANT_BUNDLE" --target "$COMPLIANT_TARGET" 2>/dev/null)"
NOOP="$(json_field "$IDEMPOTENT_OUTPUT" "d['data'].get('noop', False)")"
[[ "$NOOP" == "True" ]] \
  || fail "idempotency: re-run was not a no-op" "Second import with same URL should short-circuit on sha256 match. Output: $IDEMPOTENT_OUTPUT"
c_pass "re-run with identical bundle is a no-op"

# --------------------------------------------------------------------------
# Phase E — overwrite gate
# --------------------------------------------------------------------------

phase "Phase E — overwrite gate"

# Defeat idempotency by mutating sidecar sha256 so the gate is exercised.
python3 -c "
import json, pathlib
p = pathlib.Path('$COMPLIANT_TARGET/.claude-design-source')
d = json.loads(p.read_text())
d['sha256'] = 'deadbeef'
p.write_text(json.dumps(d, indent=2) + '\n')
"

GATE_OUTPUT="$(python3 "$IMPORTER" --bundle "$COMPLIANT_BUNDLE" --target "$COMPLIANT_TARGET" 2>/dev/null)"
GATE_SUCCESS="$(json_field "$GATE_OUTPUT" "d['success']")"
[[ "$GATE_SUCCESS" == "False" ]] \
  || fail "overwrite gate: non-empty target was overwritten without --allow-overwrite" "Gate must refuse. Output: $GATE_OUTPUT"
c_pass "non-empty target refused without --allow-overwrite"

# With --allow-overwrite it should proceed.
ALLOW_OUTPUT="$(python3 "$IMPORTER" --bundle "$COMPLIANT_BUNDLE" --target "$COMPLIANT_TARGET" --allow-overwrite 2>/dev/null)"
ALLOW_SUCCESS="$(json_field "$ALLOW_OUTPUT" "d['success']")"
[[ "$ALLOW_SUCCESS" == "True" ]] \
  || fail "overwrite gate: --allow-overwrite did not proceed" "Output: $ALLOW_OUTPUT"
c_pass "--allow-overwrite proceeds"

# --------------------------------------------------------------------------
# Phase F — dry-run
# --------------------------------------------------------------------------

phase "Phase F — dry-run"

DRY_TARGET="$TMPDIR/dry-target"
DRY_OUTPUT="$(python3 "$IMPORTER" --bundle "$COMPLIANT_BUNDLE" --target "$DRY_TARGET" --dry-run 2>/dev/null)"
DRY_SUCCESS="$(json_field "$DRY_OUTPUT" "d['success']")"
[[ "$DRY_SUCCESS" == "True" ]] \
  || fail "dry-run: importer failed in dry-run mode" "Output: $DRY_OUTPUT"

DRY_FLAG="$(json_field "$DRY_OUTPUT" "d['data'].get('dry_run', False)")"
[[ "$DRY_FLAG" == "True" ]] \
  || fail "dry-run: dry_run flag not set in output" "Output: $DRY_OUTPUT"

if [[ -d "$DRY_TARGET" ]]; then
  fail "dry-run: --dry-run still wrote files" "$DRY_TARGET should not exist after dry-run."
fi
c_pass "dry-run reports without side effects"

# --------------------------------------------------------------------------
# Done
# --------------------------------------------------------------------------

phase "Result"
printf "OK: claude-design importer verified across 6 phases\n"
exit 0
