#!/usr/bin/env bash
# test_control_path_flip.sh — regression guard for the canonical wiki/meta/
# control-file flip.
#
# The desync this guards against: cogni-knowledge's resolver
# (_knowledge_lib._resolve_control_path, surfaced via control-path.py) and the
# vendored readers/writers' self-contained _meta_first helpers must agree on
# ONE path per control file in every layout state — otherwise a CK-side writer
# lands content where a vendored reader never looks (split log, stale brief).
#
# Covers:
#   1. Meta-only wiki (the post-flip canonical shape): resolver returns
#      wiki/meta/ paths; a file absent from both layouts ALSO defaults to meta.
#   2. Legacy-flat wiki (pre-migration): an existing flat file keeps resolving
#      flat — via the resolver AND via every vendored _meta_first helper.
#   3. Agreement: for both fixtures, the resolver and each of the four vendored
#      helpers resolve log.md to the SAME path (the desync regression check).
#   4. End-to-end writer/reader pair: wiki_queue-style append through
#      _meta_first lands in the file control-path.py resolves — on both shapes.
#
# bash 3.2 + python3 stdlib only. Exits non-zero on any failure.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

PLUGIN_ROOT="$PLUGIN_ROOT" WORK="$WORK" python3 - <<'PYEOF'
import importlib.util
import os
import sys
from pathlib import Path

plugin_root = Path(os.environ["PLUGIN_ROOT"])
work = Path(os.environ["WORK"])

sys.path.insert(0, str(plugin_root / "scripts"))
import _knowledge_lib as kl  # noqa: E402

# Load each vendored module's _meta_first by file path (they are standalone).
VENDORED = {
    "rebuild_open_questions": plugin_root / "scripts/vendor/cogni-wiki/skills/wiki-lint/scripts/rebuild_open_questions.py",
    "rebuild_context_brief": plugin_root / "scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts/rebuild_context_brief.py",
    "render_dashboard": plugin_root / "scripts/vendor/cogni-wiki/skills/wiki-dashboard/scripts/render_dashboard.py",
    "wiki_queue": plugin_root / "scripts/vendor/cogni-wiki/skills/wiki-ingest/scripts/wiki_queue.py",
}
helpers = {}
for name, path in VENDORED.items():
    # _wikilib lives in the sibling wiki-ingest scripts dir; modules insert it
    # themselves at import time, so importing by path works standalone.
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    helpers[name] = mod._meta_first

failures = []

def check(label, cond, detail=""):
    if cond:
        print(f"PASS: {label}")
    else:
        failures.append(label)
        print(f"FAIL: {label} {detail}")

# --- 1. meta-only wiki (post-flip canonical shape) -------------------------
meta_wiki = work / "meta-only"
(meta_wiki / "wiki" / "meta").mkdir(parents=True)
(meta_wiki / "wiki" / "meta" / "log.md").write_text("# Log\n", encoding="utf-8")

check("meta-only: resolver returns wiki/meta/log.md",
      kl.log_path(meta_wiki) == meta_wiki / "wiki" / "meta" / "log.md")
check("meta-only: file absent from both layouts defaults to wiki/meta/",
      kl.context_brief_path(meta_wiki) == meta_wiki / "wiki" / "meta" / "context_brief.md")

# --- 2. legacy-flat wiki (pre-migration) ------------------------------------
flat_wiki = work / "legacy-flat"
(flat_wiki / "wiki").mkdir(parents=True)
(flat_wiki / "wiki" / "log.md").write_text("# Log\n", encoding="utf-8")
(flat_wiki / "wiki" / "context_brief.md").write_text("brief", encoding="utf-8")

check("legacy-flat: resolver keeps an existing flat log.md",
      kl.log_path(flat_wiki) == flat_wiki / "wiki" / "log.md")
check("legacy-flat: resolver keeps an existing flat context_brief.md",
      kl.context_brief_path(flat_wiki) == flat_wiki / "wiki" / "context_brief.md")

# --- 3. resolver <-> vendored-helper agreement on log.md --------------------
for fixture_name, wiki in (("meta-only", meta_wiki), ("legacy-flat", flat_wiki)):
    resolver_path = kl.log_path(wiki)
    for mod_name, fn in helpers.items():
        check(f"{fixture_name}: {mod_name}._meta_first agrees with the resolver on log.md",
              Path(fn(wiki, "log.md")) == resolver_path,
              f"(helper={fn(wiki, 'log.md')} resolver={resolver_path})")

# --- 4. end-to-end writer/reader pair ---------------------------------------
for fixture_name, wiki in (("meta-only", meta_wiki), ("legacy-flat", flat_wiki)):
    target = Path(helpers["wiki_queue"](wiki, "log.md"))
    target.parent.mkdir(parents=True, exist_ok=True)
    with open(target, "a", encoding="utf-8") as f:
        f.write(f"## [2026-01-01] queue | {fixture_name} marker\n")
    read_back = kl.log_path(wiki).read_text(encoding="utf-8")
    check(f"{fixture_name}: a _meta_first append is visible through the resolver",
          f"{fixture_name} marker" in read_back)

sys.exit(1 if failures else 0)
PYEOF
status=$?

if [ "$status" -ne 0 ]; then
  red "control-path flip assertions failed"
  exit 1
fi
green "all control-path flip assertions passed"
