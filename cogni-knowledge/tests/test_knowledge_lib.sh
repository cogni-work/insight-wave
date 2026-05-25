#!/usr/bin/env bash
# test_knowledge_lib.sh — contract test for the shared _knowledge_lib.py.
#
# Asserts:
#   1. Three-way `is`-identity: candidate-store.normalize_url,
#      fetch-cache.normalize_url, and _knowledge_lib.normalize_url are the
#      same function object. Same for atomic_write. This is the structural
#      guarantee that the dedup-key contract between the curator-side merge
#      (candidates.json) and the fetcher-side cache lookup (fetch-cache)
#      cannot drift — it isn't a convention, it's the same function.
#   2. Behavioural canonicalization: a representative URL exercising every
#      transformation (mixed-case scheme/host, trailing slash, utm_/ref
#      stripping, fragment removal) yields the same canonical form across
#      all three callers.
#   3. atomic_write round-trip: a payload writes, reads back equal, and
#      leaves no `.tmp` debris in the parent directory on success.
#
# Script names contain hyphens (candidate-store, fetch-cache), which means
# plain `import candidate-store` is invalid Python. Tests load the modules
# by path via importlib.util.spec_from_file_location.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

for f in _knowledge_lib.py candidate-store.py fetch-cache.py; do
  if [ ! -f "$SCRIPTS_DIR/$f" ]; then
    red "FAIL: $f not found at $SCRIPTS_DIR/$f"
    exit 1
  fi
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Run all three assertions in one python3 subprocess; emit a tagged status
# line per assertion so bash can grade each independently. Splitting into
# three subprocesses would re-import the same three modules each time.
OUT=$(python3 - "$SCRIPTS_DIR" "$WORK" <<'PY'
import importlib.util
import json
import sys
from pathlib import Path

scripts = Path(sys.argv[1])
work = Path(sys.argv[2])


def load(name, fname):
    spec = importlib.util.spec_from_file_location(name, scripts / fname)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def check(tag, fn):
    try:
        fn()
        print(f"{tag}: OK")
    except AssertionError as exc:
        print(f"{tag}: FAIL {exc}")


kl = load("_knowledge_lib", "_knowledge_lib.py")
cs = load("candidate_store", "candidate-store.py")
fc = load("fetch_cache", "fetch-cache.py")


def assert_identity():
    assert cs.normalize_url is fc.normalize_url is kl.normalize_url, (
        f"normalize_url identities diverge: cs={cs.normalize_url!r} "
        f"fc={fc.normalize_url!r} kl={kl.normalize_url!r}"
    )
    assert cs.atomic_write is fc.atomic_write is kl.atomic_write, (
        f"atomic_write identities diverge: cs={cs.atomic_write!r} "
        f"fc={fc.atomic_write!r} kl={kl.atomic_write!r}"
    )


def assert_canonicalization():
    url = "https://EXAMPLE.org/Foo/?utm_source=x&ref=y&keep=1#frag"
    expected = "https://example.org/Foo?keep=1"
    for tag, mod in (("_knowledge_lib", kl), ("candidate-store", cs), ("fetch-cache", fc)):
        got = mod.normalize_url(url)
        assert got == expected, f"{tag}: got={got!r} expected={expected!r}"


def assert_atomic_write_roundtrip():
    target = work / "out" / "payload.json"
    payload = {"schema_version": "0.1.0", "candidates": [{"url": "https://example.org/a", "score": 0.42}]}
    returned = kl.atomic_write(target, payload)
    assert returned == target, (returned, target)
    assert target.is_file(), target
    readback = json.loads(target.read_text(encoding="utf-8"))
    assert readback == payload, (readback, payload)
    leftover = [
        p.name for p in target.parent.iterdir()
        if p.name.startswith(".payload.json.") and p.name.endswith(".tmp")
    ]
    assert leftover == [], leftover


def assert_slugify():
    # #303: German umlauts transliterate by convention (ä→ae …) BEFORE the
    # keep-regex strip, so `für` → `fuer` (not `f-r`); remaining Latin scripts
    # de-accent via NFKD. The empty/non-alnum → "" contract is preserved.
    cases = {
        "Lean Canvas für Insight-Wave": "lean-canvas-fuer-insight-wave",
        "für insight-wave": "fuer-insight-wave",
        "Geschäftsidee": "geschaeftsidee",
        "Über": "ueber",
        "Öl": "oel",
        "Maß": "mass",
        "Café": "cafe",
        "El Niño": "el-nino",
        "": "",
        "   ": "",
        "!!!": "",
    }
    for inp, exp in cases.items():
        got = kl.slugify(inp)
        assert got == exp, f"slugify({inp!r})={got!r} expected {exp!r}"
    # max-len truncation preserved (default 80), with no trailing dash.
    long = kl.slugify("a" * 100)
    assert len(long) == 80, f"max-len not enforced: len={len(long)}"
    trimmed = kl.slugify("a" * 79 + " b")
    assert not trimmed.endswith("-"), f"trailing dash after truncation: {trimmed!r}"


def assert_ref_heading():
    # #301/#300: localized reference heading, default/unknown → English.
    assert kl.ref_heading("de") == "Referenzen", kl.ref_heading("de")
    assert kl.ref_heading("DE") == "Referenzen", "case-insensitive"
    assert kl.ref_heading("en") == "References", kl.ref_heading("en")
    assert kl.ref_heading("xx") == "References", "unknown code → English"
    assert kl.ref_heading(None) == "References", "None → English"


check("identity", assert_identity)
check("canonicalization", assert_canonicalization)
check("atomic_write_roundtrip", assert_atomic_write_roundtrip)
check("slugify", assert_slugify)
check("ref_heading", assert_ref_heading)
PY
)

errors=0

grade() {
  local tag="$1" description="$2"
  local line
  line=$(printf '%s\n' "$OUT" | grep "^${tag}:" || true)
  case "$line" in
    "${tag}: OK")     green "PASS: $description" ;;
    "${tag}: FAIL "*) red   "FAIL: $description"; red "  ${line#${tag}: FAIL }"; errors=$((errors + 1)) ;;
    *)                red   "FAIL: $description (no result line for '$tag' — python subprocess crashed?)"
                      red   "  output: $OUT"; errors=$((errors + 1)) ;;
  esac
}

grade identity                "three-way identity — normalize_url and atomic_write are the same objects in candidate-store, fetch-cache, _knowledge_lib"
grade canonicalization        "canonicalization — scheme/host lowercased, trailing slash stripped, utm_+ref dropped, fragment removed, path case preserved"
grade atomic_write_roundtrip  "atomic_write round-trips payload and leaves no .tmp debris"
grade slugify                 "slugify — German umlaut transliteration (für→fuer), NFKD de-accent, empty/non-alnum→'' contract, max-len truncation"
grade ref_heading             "ref_heading — localized reference heading (de→Referenzen), default/unknown→References"

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All _knowledge_lib.py cases pass."
