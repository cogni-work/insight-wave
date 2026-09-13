#!/usr/bin/env bash
# test-semantic-tokens.sh — the token compiler, the manifest validator and the
# Claude Design importer keep semantic aliases, fail bad graphs loudly, and
# re-import predictably.
#
# The canonical tokens/*.json files are a theme's one authoritative
# representation; tokens.css and tokens.resolved.json are projections of them.
# This suite pins that chain end to end:
#
#   * every bundled theme still compiles to its committed tokens.css (flat themes
#     are byte-identical to the flat-map generator the compiler replaced);
#   * a chained foreground/background bundle keeps each role as a reference to
#     its immediate target, in storage, in CSS and in the resolved projection;
#   * a cycle, an unresolved reference, a composite value and a malformed alias
#     each exit 1 with a finding-only envelope from the compiler, the validator
#     and the importer, and write nothing;
#   * repeat imports are equivalent, the overwrite gate holds, stale managed
#     files leave, and files the user added keep their bytes;
#   * a local bundle imports with networking refused outright.
#
# CASE IDS are `stok-NN-<discriminator>`, allocated once and never renumbered;
# loop-generated cases slugify the looped value into the id. Every FAIL arm has a
# same-id PASS twin, both emitted through one argument.
#
# MUTATION RECIPE — alias retention has teeth. `retains_alias` must keep its
# exact one-line body, or the recorded --expr stops matching:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/import-claude-design-bundle.py --expr 's/return ALIAS_VAR\.fullmatch\(value\) is not None/return False/' --test 'bash cogni-publishing/tests/test-semantic-tokens.sh' --case stok-04-alias-retained
#
# Under the mutant every `var(--x)` declaration is treated as lossy, so
# semantic.json is never written and stok-04 goes RED; restoring the line turns
# it GREEN.
#
# Contract: `bash <path>` from any cwd, no arguments, no network, exits non-zero
# on any failure. Scratch work lives in mktemp; no tracked file is written.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PUB="$(cd "$HERE/.." && pwd)"
FIX="$HERE/fixtures"
GEN="$PUB/scripts/generate-tokens-css.py"
VAL="$PUB/scripts/validate-theme-manifest.py"
IMP="$PUB/scripts/import-claude-design-bundle.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check() { if [ "$1" -eq 0 ]; then pass "$2"; else fail "$2"; fi; }

# jtrue <json-file> <python expression over d> — exit 0 when the expression holds.
jtrue() {
  python3 - "$1" "$2" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(1)
sys.exit(0 if eval(sys.argv[2], {"d": d}) else 1)
PY
}

# tree_digest <dir> — one line per file: relative path and sha256.
tree_digest() {
  python3 - "$1" <<'PY'
import hashlib, os, sys
root = sys.argv[1]
for base, _, files in sorted(os.walk(root)):
    for name in sorted(files):
        p = os.path.join(base, name)
        print(os.path.relpath(p, root), hashlib.sha256(open(p, "rb").read()).hexdigest())
PY
}

# sha <file> — hex sha256 of one file.
sha() { python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1"; }

# pack <fixture-name> -> path of a gzipped tar of that bundle fixture.
pack() {
  local src="$FIX/bundles/$1" out="$TMP/$1.tar.gz"
  [ -f "$out" ] || (cd "$src" && tar -czf "$out" *-design-system)
  printf '%s' "$out"
}

import_bundle() { python3 "$IMP" --bundle "$1" --target "$2" "${@:3}" > "$TMP/last.json" 2>/dev/null; }

# ---------------------------------------------------------------------------
# stok-01 — every bundled theme's tokens compile to its committed tokens.css
# ---------------------------------------------------------------------------
seen_tiered=0
for tokens_dir in "$PUB"/themes/*/tokens; do
  [ -d "$tokens_dir" ] || continue
  theme="$(basename "$(dirname "$tokens_dir")")"
  seen_tiered=$((seen_tiered + 1))
  python3 "$GEN" --tokens-dir "$tokens_dir" > "$TMP/regen.css" 2>/dev/null \
    && cmp -s "$TMP/regen.css" "$tokens_dir/tokens.css"
  check $? "stok-01-legacy-parity-$theme bundled $theme compiles byte-identically to its committed tokens.css"
done
[ "$seen_tiered" -gt 0 ]
check $? "stok-01-legacy-parity-floor at least one bundled tiered theme was compared"

# ---------------------------------------------------------------------------
# stok-02 — a flat fixture needs no upgrade: literals only, no alias, no var()
# ---------------------------------------------------------------------------
python3 "$GEN" --tokens-dir "$FIX/tokens/flat" --format resolved-json > "$TMP/flat.json" 2>/dev/null
jtrue "$TMP/flat.json" 'd["success"] and d["data"]["aliases"] == {} and d["data"]["tokens"]["colors"] == {"ink": "#111111", "paper": "#FAFAF8"} and d["data"]["tokens"]["spacing"]["base"] == 16'
rc=$?
python3 "$GEN" --tokens-dir "$FIX/tokens/flat" 2>/dev/null | grep -q 'var('
novar=$?
[ $rc -eq 0 ] && [ $novar -ne 0 ]
check $? "stok-02-flat-no-upgrade a flat token fixture resolves to its own literals with no alias and no var()"

# ---------------------------------------------------------------------------
# stok-03..05 — chained foreground/background aliases through the importer
# ---------------------------------------------------------------------------
CHAIN="$(pack alias-chain)"
T1="$TMP/chain"
import_bundle "$CHAIN" "$T1"
chain_rc=$?

css="$T1/tokens/tokens.css"
[ $chain_rc -eq 0 ] \
  && grep -qF -- '--semantic-fg: var(--semantic-text);' "$css" \
  && grep -qF -- '--semantic-text: var(--colors-ink);' "$css" \
  && grep -qF -- '--semantic-bg: var(--semantic-surface);' "$css" \
  && grep -qF -- '--semantic-surface: var(--colors-paper);' "$css"
check $? "stok-03-alias-css-chain tokens.css keeps each fg/bg role as a var() reference to its immediate target"

jtrue "$T1/tokens/semantic.json" 'd == {"fg": "{semantic.text}", "text": "{colors.ink}", "bg": "{semantic.surface}", "surface": "{colors.paper}"}'
check $? "stok-04-alias-retained the stored canonical tokens record every role-to-role reference of the chained fg/bg bundle"

jtrue "$T1/tokens/tokens.resolved.json" 'd["tokens"]["semantic"] == {"fg": "#111111", "text": "#111111", "bg": "#FAFAF8", "surface": "#FAFAF8"} and d["aliases"]["semantic.fg"] == "semantic.text" and d["aliases"]["semantic.bg"] == "semantic.surface"'
check $? "stok-05-alias-resolved the resolved projection gives literal fg/bg values and keeps the alias map"

python3 "$VAL" "$T1" > "$TMP/val-chain.json" 2>/dev/null
jtrue "$TMP/val-chain.json" 'd["success"] is True'
check $? "stok-05-alias-validates the imported alias theme passes validate-theme-manifest, projections included"

# ---------------------------------------------------------------------------
# stok-06 — DTCG token objects are accepted and aliases inside them compile
# ---------------------------------------------------------------------------
python3 "$GEN" --tokens-dir "$FIX/tokens/dtcg-object" > "$TMP/dtcg.css" 2>/dev/null \
  && grep -qF -- '--colors-fg: var(--colors-ink);' "$TMP/dtcg.css" \
  && grep -qF -- '--colors-ink: #111111;' "$TMP/dtcg.css" \
  && grep -qF -- '--colors-paper: #FAFAF8;' "$TMP/dtcg.css"
check $? "stok-06-dtcg-object a DTCG token object compiles, its alias kept and its ignored members dropped"

# ---------------------------------------------------------------------------
# stok-07 / stok-08 — negative graphs: compiler and validator both refuse,
# with a finding-only envelope, and nothing is written
# ---------------------------------------------------------------------------
for spec in cycle:alias-cycle unresolved:unresolved-reference unsupported-composite:unsupported-construct malformed-alias:malformed-alias; do
  name="${spec%%:*}"
  code="${spec#*:}"
  work="$TMP/neg-$name"
  mkdir -p "$work/theme"
  cp -R "$FIX/tokens/$name" "$work/theme/tokens"

  python3 "$GEN" --tokens-dir "$work/theme/tokens" --write > "$work/gen.json" 2>/dev/null
  rc=$?
  jtrue "$work/gen.json" "d['success'] is False and set(d['data']) == {'code', 'token', 'reference'} and d['data']['code'] == '$code' and d['data']['token'] and d['error']"
  shape=$?
  [ $rc -eq 1 ] && [ $shape -eq 0 ] && [ ! -e "$work/theme/tokens/tokens.css" ] && [ ! -e "$work/theme/tokens/tokens.resolved.json" ]
  check $? "stok-07-compiler-$name the compiler exits 1 with only a $code finding and writes no projection"

  printf '{"schema_version": "1.0", "name": "Neg", "slug": "neg", "tiers": {"tokens": "tokens/"}}\n' > "$work/theme/manifest.json"
  printf '# Neg\n' > "$work/theme/theme.md"
  python3 "$VAL" "$work/theme" > "$work/val.json" 2>/dev/null
  rc=$?
  jtrue "$work/val.json" "d['success'] is False and d['data'].get('code') == '$code' and 'tier' not in d['data'] and d['error']"
  shape=$?
  [ $rc -eq 1 ] && [ $shape -eq 0 ]
  check $? "stok-08-validator-$name the validator exits 1 with the $code finding and no tier verdict"
done

# ---------------------------------------------------------------------------
# stok-09 — legacy nested/boolean values are skipped and reported, not failed
# ---------------------------------------------------------------------------
python3 "$GEN" --tokens-dir "$FIX/tokens/legacy-nested" --format resolved-json > "$TMP/legacy.json" 2>/dev/null
jtrue "$TMP/legacy.json" 'd["success"] and d["data"]["tokens"]["colors"] == {"ink": "#111111"} and sorted(s["token"] for s in d["data"]["skipped"]) == ["colors.brand", "colors.flag"]'
check $? "stok-09-legacy-skipped-reported legacy nested and boolean values are skipped, compiled around and reported"

# ---------------------------------------------------------------------------
# stok-10 / stok-11 — an importer graph failure writes nothing
# ---------------------------------------------------------------------------
import_bundle "$(pack alias-cycle)" "$TMP/cycle-target"
rc=$?
jtrue "$TMP/last.json" 'd["success"] is False and d["data"].get("code") == "alias-cycle" and set(d["data"]) == {"code", "token", "reference"}'
shape=$?
[ $rc -eq 1 ] && [ $shape -eq 0 ] && [ ! -e "$TMP/cycle-target" ]
check $? "stok-10-import-cycle-no-write a bundle alias cycle aborts with an alias-cycle finding before the target exists"

mkdir -p "$TMP/dangling-target"
printf 'user notes\n' > "$TMP/dangling-target/notes.md"
before="$(tree_digest "$TMP/dangling-target")"
import_bundle "$(pack alias-unresolved)" "$TMP/dangling-target" --allow-overwrite
rc=$?
jtrue "$TMP/last.json" 'd["success"] is False and d["data"].get("code") == "unresolved-reference" and d["data"].get("reference") == "--nowhere"'
shape=$?
[ $rc -eq 1 ] && [ $shape -eq 0 ] && [ "$before" = "$(tree_digest "$TMP/dangling-target")" ]
check $? "stok-11-import-unresolved-no-write an unresolved bundle alias aborts and leaves an existing target byte-identical"

# ---------------------------------------------------------------------------
# stok-12 — unsupported alias forms are dropped AND reported, never silently
# ---------------------------------------------------------------------------
import_bundle "$(pack alias-fallback)" "$TMP/lossy-target"
jtrue "$TMP/last.json" 'd["success"] and sorted(a["token"] for a in d["data"]["aliases_dropped"]) == ["--glow", "--wide-alias"] and [x["token"] for x in d["data"]["declarations_dropped"]] == ["--wide"] and d["data"]["aliases"] == {"semantic.accent-role": "colors.accent"}'
check $? "stok-12-drops-reported a fallback alias, an alias to a lossy value and a calc() value are each reported; the bare alias is kept"

# ---------------------------------------------------------------------------
# stok-13..17 — repeat import, overwrite gate, stale managed files, user assets
# ---------------------------------------------------------------------------
first="$(tree_digest "$T1")"
import_bundle "$CHAIN" "$T1"
jtrue "$TMP/last.json" 'd["success"] and d["data"].get("noop") is True'
[ $? -eq 0 ] && [ "$first" = "$(tree_digest "$T1")" ]
check $? "stok-13-reimport-noop re-importing the identical bundle is a no-op that changes no byte"

mkdir -p "$T1/assets"
printf '<svg/>\n' > "$T1/assets/my-logo.svg"
printf 'my own notes\n' > "$T1/NOTES.md"
V2="$(pack alias-chain-v2)"
gated_before="$(tree_digest "$T1")"
import_bundle "$V2" "$T1"
rc=$?
[ $rc -eq 1 ] && [ "$gated_before" = "$(tree_digest "$T1")" ]
check $? "stok-14-overwrite-gate a changed bundle without --allow-overwrite is refused and the target is untouched"

logo_sha="$(sha "$T1/assets/my-logo.svg")"
notes_sha="$(sha "$T1/NOTES.md")"
import_bundle "$V2" "$T1" --allow-overwrite
jtrue "$TMP/last.json" 'd["success"] and sorted(d["data"]["managed_files_removed"]) == ["components/web/cards.html", "tokens/typography.json"]'
[ $? -eq 0 ] && [ ! -e "$T1/tokens/typography.json" ] && [ ! -e "$T1/components/web/cards.html" ] \
  && jtrue "$T1/tokens/colors.json" 'd["ink"] == "#222222"'
check $? "stok-15-reimport-stale-removed an --allow-overwrite re-import replaces managed files and removes the ones the new bundle no longer produces"

[ "$logo_sha" = "$(sha "$T1/assets/my-logo.svg")" ] \
  && [ "$notes_sha" = "$(sha "$T1/NOTES.md")" ]
check $? "stok-16-protected-user-assets files the user added to the theme directory keep identical bytes across a re-import"

import_bundle "$CHAIN" "$T1" --allow-overwrite
import_bundle "$CHAIN" "$TMP/fresh"
[ -d "$TMP/fresh/tokens" ] && [ "$(tree_digest "$T1/tokens")" = "$(tree_digest "$TMP/fresh/tokens")" ]
check $? "stok-17-reimport-equivalent importing v1 again over v2 yields the same canonical tokens and projections as a fresh v1 import"

# ---------------------------------------------------------------------------
# stok-18 — a local bundle imports with networking refused
# ---------------------------------------------------------------------------
python3 - "$IMP" "$CHAIN" "$TMP/offline" > "$TMP/offline.json" 2>/dev/null <<'PY'
import runpy, sys
def refuse(event, args):
    if event.startswith("socket.") or event == "urllib.Request":
        raise RuntimeError("network access attempted: " + event)
sys.addaudithook(refuse)
importer, bundle, target = sys.argv[1:4]
sys.argv = [importer, "--bundle", bundle, "--target", target]
runpy.run_path(importer, run_name="__main__")
PY
rc=$?
jtrue "$TMP/offline.json" 'd["success"] is True'
shape=$?
[ $rc -eq 0 ] && [ $shape -eq 0 ]
check $? "stok-18-offline-local-bundle a local bundle imports with every socket and URL request refused"

# ---------------------------------------------------------------------------
# stok-19 — the documented subset and the compiler agree
# ---------------------------------------------------------------------------
python3 - "$PUB/references/token-subset.md" "$GEN" <<'PY'
import importlib.util, re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
line = next((l for l in doc.splitlines() if l.startswith("**Supported $type values:**")), "")
documented = re.findall(r"`([A-Za-z]+)`", line)
spec = importlib.util.spec_from_file_location("gen", sys.argv[2])
gen = importlib.util.module_from_spec(spec); spec.loader.exec_module(gen)
ok = documented == list(gen.SUPPORTED_TYPES) and "This is not full DTCG support." in doc
sys.exit(0 if ok else 1)
PY
check $? "stok-19-doc-parity token-subset.md lists exactly the compiler's supported \$type values and disclaims full DTCG support"

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures semantic-token check(s) failed."
  exit 1
fi
echo ""
echo "All semantic-token checks passed."
