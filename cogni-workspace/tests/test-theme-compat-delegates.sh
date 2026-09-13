#!/usr/bin/env bash
# test-theme-compat-delegates.sh — cogni-workspace keeps only thin routes into
# the theme lifecycle cogni-publishing owns, and those routes really arrive.
#
# The theme lifecycle moved to cogni-publishing as its single implementation.
# What stays here is compatibility only: the same-name manage-themes skill, four
# script entry points that callers outside the move still reach, the one resolver
# behind them, and a pointer for a moved reference. This suite holds both halves
# of that bargain:
#
#   * SHAPE and ABSENCE — each route is delegation-only (no discovery, import,
#     validation, token compilation, storage or bundled themes), and nothing of
#     the moved implementation is left behind to fork from;
#   * ARRIVAL — the delegated discovery returns the same theme_path /
#     theme_name / theme_slug the publishing selection does, an import-by-path
#     consumer gets the real functions, and a missing cogni-publishing fails
#     with an actionable envelope rather than silently.
#
# CASE IDS are `tcd-NN-<discriminator>`, allocated once and never renumbered;
# loop cases slugify the looped file into the id. Every FAIL arm has a same-id
# PASS twin, both emitted through one argument.
#
# Contract: `bash <path>` from any cwd, no arguments, no network, exits non-zero
# on any failure. Scratch trees live in mktemp.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS="$(cd "$HERE/.." && pwd)"
REPO="$(cd "$WS/.." && pwd)"
PUB="$REPO/cogni-publishing"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check() { if [ "$1" -eq 0 ]; then pass "$2"; else fail "$2"; fi; }

DELEGATES="discover-themes inspect-themes check-theme-drift sanitize-theme"

# ---------------------------------------------------------------------------
# tcd-01 — each script route is delegation-only
# ---------------------------------------------------------------------------
for name in $DELEGATES; do
  f="$WS/scripts/$name.py"
  python3 - "$f" "$name.py" <<'PY'
import re, sys
path, script = sys.argv[1], sys.argv[2]
try:
    src = open(path, encoding="utf-8").read()
except OSError:
    sys.exit(1)
code = re.sub(r'""".*?"""', "", src, flags=re.S)
calls = re.findall(r'_delegate\.delegate\(__name__, globals\(\), "([^"]+)"\)', code)
# `glob.` rather than `glob`: every delegate must call globals().
forbidden = ("def ", "json.load", "listdir", "glob.", "re.compile", "open(", "theme.md", "manifest")
ok = (src.count("\n") <= 20 and calls == [script]
      and not any(tok in code for tok in forbidden))
sys.exit(0 if ok else 1)
PY
  check $? "tcd-01-delegate-shape-$name $name.py is at most 20 lines, makes one delegate call naming itself, and holds no theme logic"
done

# ---------------------------------------------------------------------------
# tcd-02 — the resolver resolves; it does not do theme work
# ---------------------------------------------------------------------------
RES="$WS/scripts/_publishing_delegate.py"
python3 - "$RES" <<'PY'
import re, sys
try:
    src = open(sys.argv[1], encoding="utf-8").read()
except OSError:
    sys.exit(1)
code = re.sub(r'""".*?"""', "", src, flags=re.S)
forbidden = ("theme.md", "manifest", "tokens", "json.load", "re.compile", "parse_theme", "scan_themes")
sys.exit(1 if any(tok in code for tok in forbidden) else 0)
PY
check $? "tcd-02-resolver-no-theme-logic the shared resolver locates cogni-publishing and carries no theme logic"

# ---------------------------------------------------------------------------
# tcd-03 — the manage-themes skill delegates by name and does nothing itself
# The body line ceiling mirrors tcd-01's cap on the script routes, so a
# prose-only regression that restores the old storage instructions goes red.
# ---------------------------------------------------------------------------
SKILL="$WS/skills/manage-themes/SKILL.md"
python3 - "$SKILL" <<'PY'
import re, sys
try:
    text = open(sys.argv[1], encoding="utf-8").read()
except OSError:
    sys.exit(1)
m = re.match(r"^---\n.*?\n---\n(.*)$", text, re.S)
body = m.group(1) if m else ""
required = ("<!-- compatibility-delegate: cogni-publishing -->", "cogni-publishing:manage-themes",
            "theme_path", "theme_name", "theme_slug")
forbidden = ("python3", "scripts/", "discover-themes", "import-claude-design", "generate-tokens",
             "validate-theme", "CLAUDE_PLUGIN_ROOT", "COGNI_WORKSPACE_ROOT", "_template")
ok = (body and body.count("\n") <= 30 and all(r in body for r in required)
      and not any(f in body for f in forbidden))
sys.exit(0 if ok else 1)
PY
check $? "tcd-03-skill-delegates the manage-themes skill body stays within 30 lines, dispatches cogni-publishing:manage-themes, names the three handoff fields and runs or stores nothing itself"

# ---------------------------------------------------------------------------
# tcd-04 — nothing of the moved implementation is left to fork from
# ---------------------------------------------------------------------------
for rel in themes scripts/validate-theme-manifest.py scripts/generate-tokens-css.py \
           scripts/import-claude-design-bundle.py scripts/load-theme-component.py \
           scripts/check-contrast.py scripts/verify-theme-backcompat.sh \
           scripts/verify-claude-design-importer.sh scripts/baselines \
           references/theme-manifest.md references/theme-manifest.schema.json \
           references/theme-component-loader.md references/claude-design-bundle-mapping.md \
           docs/theme-system-v2-migration.md skills/manage-themes/references skills/manage-themes/evals; do
  slug="$(printf '%s' "$rel" | tr '/.' '--')"
  [ ! -e "$WS/$rel" ]
  check $? "tcd-04-absent-$slug cogni-workspace/$rel is gone; cogni-publishing holds the only copy"
done

# ---------------------------------------------------------------------------
# tcd-05 — the one moved reference left behind is a pointer, not an authority
# ---------------------------------------------------------------------------
PTR="$WS/references/design-variables-pattern.md"
[ -f "$PTR" ] && [ "$(wc -l < "$PTR")" -le 15 ] \
  && grep -qF 'cogni-publishing/references/design-variables-pattern.md' "$PTR" \
  && ! grep -q '^|' "$PTR"
check $? "tcd-05-pointer-shape references/design-variables-pattern.md is a short pointer to the cogni-publishing copy with no rules of its own"

# ---------------------------------------------------------------------------
# tcd-06 — the delegated discovery and the publishing selection agree
# ---------------------------------------------------------------------------
COGNI_PUBLISHING_PLUGIN="$PUB" COGNI_WORKSPACE_ROOT="" \
  python3 "$WS/scripts/discover-themes.py" --no-discover > "$TMP/delegated.json" 2>/dev/null
COGNI_WORKSPACE_ROOT="" python3 "$PUB/scripts/select-theme.py" --slug cogni-work > "$TMP/selected.json" 2>/dev/null
python3 - "$TMP/delegated.json" "$TMP/selected.json" <<'PY'
import json, sys
try:
    listing = json.load(open(sys.argv[1]))
    sel = json.load(open(sys.argv[2]))["data"]
except Exception:
    sys.exit(1)
entry = next((t for t in listing if t.get("slug") == "cogni-work"), None)
ok = (entry is not None and entry["path"] == sel["theme_path"]
      and entry["name"] == sel["theme_name"] and entry["slug"] == sel["theme_slug"])
sys.exit(0 if ok else 1)
PY
check $? "tcd-06-handoff-parity the workspace discovery route and publishing selection return the same theme_path, theme_name and theme_slug"

# ---------------------------------------------------------------------------
# tcd-07 — a workspace caller's CLAUDE_PLUGIN_ROOT still reaches the bundled themes
# ---------------------------------------------------------------------------
CLAUDE_PLUGIN_ROOT="$WS" COGNI_WORKSPACE_ROOT="" \
  python3 "$WS/scripts/inspect-themes.py" > "$TMP/inspect.json" 2>/dev/null
python3 - "$TMP/inspect.json" "$PUB/themes" <<'PY'
import json, os, sys
try:
    d = json.load(open(sys.argv[1]))["data"]
except Exception:
    sys.exit(1)
ok = os.path.realpath(d["standard_dir"]) == os.path.realpath(sys.argv[2]) and d["total_count"] >= 5
sys.exit(0 if ok else 1)
PY
check $? "tcd-07-workspace-caller-reaches-bundled inspect-themes run as a workspace skill runs it still lists the bundled themes"

# ---------------------------------------------------------------------------
# tcd-08 / tcd-09 — import by path gets the real module; a missing plugin says so
# ---------------------------------------------------------------------------
COGNI_PUBLISHING_PLUGIN="$PUB" python3 - "$WS/scripts/sanitize-theme.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("guard", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
sys.exit(0 if callable(getattr(m, "sanitize_section", None)) and callable(getattr(m, "is_safe_value", None)) else 1)
PY
check $? "tcd-08-import-by-path loading the sanitize-theme route by path exposes the publishing guard's functions"

FAKE="$TMP/fake-repo/cogni-workspace/scripts"
mkdir -p "$FAKE" "$TMP/empty-home"
cp "$RES" "$FAKE/"
for name in $DELEGATES; do cp "$WS/scripts/$name.py" "$FAKE/"; done
env -i PATH="$PATH" HOME="$TMP/empty-home" python3 "$FAKE/discover-themes.py" > "$TMP/missing.json" 2>/dev/null
rc=$?
python3 - "$TMP/missing.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
ok = d["success"] is False and d["data"].get("missing_plugin") == "cogni-publishing" and "install cogni-publishing" in d["error"]
sys.exit(0 if ok else 1)
PY
shape=$?
env -i PATH="$PATH" HOME="$TMP/empty-home" python3 - "$FAKE/sanitize-theme.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("guard", sys.argv[1])
m = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(m)
except ImportError:
    sys.exit(0)
sys.exit(1)
PY
imp=$?
[ $rc -eq 2 ] && [ $shape -eq 0 ] && [ $imp -eq 0 ]
check $? "tcd-09-missing-plugin with no cogni-publishing a script route exits 2 with an install-guidance envelope and an import raises ImportError"

# ---------------------------------------------------------------------------
# tcd-10 — the resolver locates the template manage-workspace seeds from
# ---------------------------------------------------------------------------
root="$(COGNI_PUBLISHING_PLUGIN="" python3 "$RES" --print-root --sentinel themes/_template/theme.md 2>/dev/null)"
[ -n "$root" ] && [ -f "$root/themes/_template/theme.md" ]
check $? "tcd-10-print-root the resolver prints a cogni-publishing root that holds themes/_template/theme.md"

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures theme-compat-delegate check(s) failed."
  exit 1
fi
echo ""
echo "All theme-compat-delegate checks passed."
