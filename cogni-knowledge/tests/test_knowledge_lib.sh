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

errors=0

# 1. Three-way identity of the shared symbols.
if python3 - "$SCRIPTS_DIR" <<'PY'
import importlib.util
import sys
from pathlib import Path

scripts = Path(sys.argv[1])

def load(name, fname):
    spec = importlib.util.spec_from_file_location(name, scripts / fname)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

kl = load("_knowledge_lib", "_knowledge_lib.py")
cs = load("candidate_store", "candidate-store.py")
fc = load("fetch_cache", "fetch-cache.py")

assert cs.normalize_url is fc.normalize_url is kl.normalize_url, (
    "normalize_url identities diverge: cs=%r fc=%r kl=%r"
    % (cs.normalize_url, fc.normalize_url, kl.normalize_url)
)
assert cs.atomic_write is fc.atomic_write is kl.atomic_write, (
    "atomic_write identities diverge: cs=%r fc=%r kl=%r"
    % (cs.atomic_write, fc.atomic_write, kl.atomic_write)
)
print("OK")
PY
then
  green "PASS: three-way identity — normalize_url and atomic_write are the same objects in candidate-store, fetch-cache, _knowledge_lib"
else
  red "FAIL: identity check broke"
  errors=$((errors + 1))
fi

# 2. Behavioural canonicalization: a URL exercising every transformation
#    must produce the same canonical form from all three callers.
if python3 - "$SCRIPTS_DIR" <<'PY'
import importlib.util
import sys
from pathlib import Path

scripts = Path(sys.argv[1])

def load(name, fname):
    spec = importlib.util.spec_from_file_location(name, scripts / fname)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

kl = load("_knowledge_lib", "_knowledge_lib.py")
cs = load("candidate_store", "candidate-store.py")
fc = load("fetch_cache", "fetch-cache.py")

url = "https://EXAMPLE.org/Foo/?utm_source=x&ref=y&keep=1#frag"
expected = "https://example.org/Foo?keep=1"

got_kl = kl.normalize_url(url)
got_cs = cs.normalize_url(url)
got_fc = fc.normalize_url(url)

assert got_kl == expected, ("_knowledge_lib", got_kl, expected)
assert got_cs == expected, ("candidate-store", got_cs, expected)
assert got_fc == expected, ("fetch-cache", got_fc, expected)
print("OK")
PY
then
  green "PASS: canonicalization — scheme/host lowercased, trailing slash stripped, utm_+ref dropped, fragment removed, path case preserved"
else
  red "FAIL: canonicalization mismatch"
  errors=$((errors + 1))
fi

# 3. atomic_write round-trip + no `.tmp` debris on success.
if python3 - "$SCRIPTS_DIR" "$WORK" <<'PY'
import importlib.util
import json
import sys
from pathlib import Path

scripts = Path(sys.argv[1])
work = Path(sys.argv[2])

spec = importlib.util.spec_from_file_location("_knowledge_lib", scripts / "_knowledge_lib.py")
kl = importlib.util.module_from_spec(spec)
sys.modules["_knowledge_lib"] = kl
spec.loader.exec_module(kl)

target = work / "out" / "payload.json"
payload = {"schema_version": "0.1.0", "candidates": [{"url": "https://example.org/a", "score": 0.42}]}
returned = kl.atomic_write(target, payload)

assert returned == target, (returned, target)
assert target.is_file(), target

readback = json.loads(target.read_text(encoding="utf-8"))
assert readback == payload, (readback, payload)

leftover = [p.name for p in target.parent.iterdir() if p.name.startswith(".payload.json.") and p.name.endswith(".tmp")]
assert leftover == [], leftover
print("OK")
PY
then
  green "PASS: atomic_write round-trips payload and leaves no .tmp debris"
else
  red "FAIL: atomic_write round-trip"
  errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All _knowledge_lib.py cases pass."
