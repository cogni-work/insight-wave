#!/usr/bin/env bash
# test-theme-lifecycle.sh — theme selection and discovery work from cogni-publishing
# alone, keep the three-field handoff, and treat user themes as read-only input.
#
# What this suite pins, each as its own addressable case:
#
#   * an explicit theme path resolves to theme_path / theme_name / theme_slug
#     with an empty environment and a throwaway HOME, and creates nothing;
#   * a bundled theme is selectable with no workspace state at all;
#   * the handoff fields are present, absolute, H1-derived and kebab-case;
#   * the optional user location has one deterministic precedence
#     (--user-themes > $COGNI_WORKSPACE_ROOT/themes), a user theme shadows a
#     bundled one, and every file there keeps its bytes across every read;
#   * a missing user location is never created by a read;
#   * the bundled root comes from the scripts' own location, not the caller's
#     $CLAUDE_PLUGIN_ROOT;
#   * every ${CLAUDE_PLUGIN_ROOT} path the moved skill documents resolves here,
#     and the moved component-loader files carry no retired dispatch token.
#
# CASE IDS are `thl-NN-<discriminator>`, allocated once and never renumbered.
# Every FAIL arm has a same-id PASS twin, both emitted through one argument.
#
# Contract: `bash <path>` from any cwd, no arguments, no network, exits non-zero
# on any failure. Every write goes to mktemp; the committed fixtures are copied
# before any script reads them.
#
# Mutation recipe:
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/discover-themes.py --expr 's/if slug == "cogni-work":/if False:/' --test 'bash cogni-publishing/tests/test-theme-lifecycle.sh' --case thl-16-recommended-first

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PUB="$(cd "$HERE/.." && pwd)"
FIX="$HERE/fixtures/themes"
SEL="$PUB/scripts/select-theme.py"
DISC="$PUB/scripts/discover-themes.py"
INSP="$PUB/scripts/inspect-themes.py"
DRIFT="$PUB/scripts/check-theme-drift.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check() { if [ "$1" -eq 0 ]; then pass "$2"; else fail "$2"; fi; }

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

tree_digest() {
  python3 - "$1" <<'PY'
import hashlib, os, sys
root = sys.argv[1]
for base, dirs, files in sorted(os.walk(root)):
    for name in sorted(dirs):
        print("dir", os.path.relpath(os.path.join(base, name), root))
    for name in sorted(files):
        p = os.path.join(base, name)
        print(os.path.relpath(p, root), hashlib.sha256(open(p, "rb").read()).hexdigest())
PY
}

# Isolated runner: empty environment except PATH, a throwaway HOME, a scratch cwd.
HOME_SANDBOX="$TMP/home"
CWD_SANDBOX="$TMP/cwd"
mkdir -p "$HOME_SANDBOX" "$CWD_SANDBOX"
isolated() { (cd "$CWD_SANDBOX" && env -i PATH="$PATH" HOME="$HOME_SANDBOX" "$@"); }

USER_THEMES="$TMP/user-themes"
cp -R "$FIX/user-themes" "$USER_THEMES"
EXPLICIT="$TMP/explicit-theme"
cp -R "$FIX/explicit-theme" "$EXPLICIT"

# ---------------------------------------------------------------------------
# thl-01..04 — explicit paths with no workspace anywhere
# ---------------------------------------------------------------------------
isolated python3 "$SEL" --theme-path "$EXPLICIT/theme.md" > "$TMP/explicit-file.json" 2>/dev/null
jtrue "$TMP/explicit-file.json" "d['success'] and d['data']['theme_path'] == '$EXPLICIT/theme.md' and d['data']['theme_name'] == 'Explicit Fixture' and d['data']['theme_slug'] == 'explicit-theme' and d['data']['source'] == 'explicit'"
check $? "thl-01-explicit-file an explicit theme.md resolves to the three-field handoff with an empty environment"

isolated python3 "$SEL" --theme-path "$EXPLICIT" > "$TMP/explicit-dir.json" 2>/dev/null
jtrue "$TMP/explicit-dir.json" "d['success'] and d['data']['theme_path'] == '$EXPLICIT/theme.md' and d['data']['theme_slug'] == 'explicit-theme'"
check $? "thl-02-explicit-dir an explicit theme directory resolves to its theme.md"

(cd "$CWD_SANDBOX" && env -i PATH="$PATH" HOME="$HOME_SANDBOX" COGNI_WORKSPACE_ROOT="$TMP/ghost-workspace" \
  python3 "$SEL" --theme-path "$EXPLICIT/theme.md" > "$TMP/explicit-poisoned.json" 2>/dev/null)
jtrue "$TMP/explicit-poisoned.json" "d['success'] and d['data']['theme_path'] == '$EXPLICIT/theme.md'"
ok=$?
[ $ok -eq 0 ] && [ ! -e "$TMP/ghost-workspace" ] && [ -z "$(ls -A "$HOME_SANDBOX")" ] && [ -z "$(ls -A "$CWD_SANDBOX")" ]
check $? "thl-03-explicit-no-workspace-state explicit selection ignores a stale workspace root and creates nothing in HOME, cwd or the workspace"

isolated python3 "$SEL" --theme-path "$TMP/no-such-theme" > "$TMP/explicit-missing.json" 2>/dev/null
rc=$?
jtrue "$TMP/explicit-missing.json" "d['success'] is False and d['error']"
shape=$?
[ $rc -eq 1 ] && [ $shape -eq 0 ]
check $? "thl-04-explicit-missing a path with no theme.md exits 1 with a success:false envelope"

# ---------------------------------------------------------------------------
# thl-05 / thl-06 — a bundled theme with no workspace, and the handoff shape
# ---------------------------------------------------------------------------
isolated python3 "$SEL" --slug cogni-work > "$TMP/bundled.json" 2>/dev/null
jtrue "$TMP/bundled.json" "d['success'] and d['data']['source'] == 'standard' and d['data']['theme_path'] == '$PUB/themes/cogni-work/theme.md'"
check $? "thl-05-bundled-no-workspace a bundled theme is selectable by slug with no workspace state"

ok=0
for f in explicit-file explicit-dir bundled; do
  jtrue "$TMP/$f.json" "all(d['data'].get(k) for k in ('theme_path','theme_name','theme_slug')) and d['data']['theme_path'].startswith('/') and d['data']['theme_path'].endswith('/theme.md') and __import__('re').fullmatch(r'[a-z0-9]+(-[a-z0-9]+)*', d['data']['theme_slug']) is not None" || ok=1
done
check $ok "thl-06-handoff-fields every selection carries non-empty theme_path (absolute theme.md), theme_name and a kebab-case theme_slug"

# ---------------------------------------------------------------------------
# thl-07..09 — user location: shadowing and deterministic precedence
# ---------------------------------------------------------------------------
isolated python3 "$SEL" --slug boardroom --user-themes "$USER_THEMES" > "$TMP/shadow.json" 2>/dev/null
jtrue "$TMP/shadow.json" "d['success'] and d['data']['source'] == 'workspace' and d['data']['theme_path'] == '$USER_THEMES/boardroom/theme.md' and d['data']['theme_name'] == 'Boardroom User Override'"
check $? "thl-07-user-shadows-bundled a user theme shadows the bundled theme of the same slug"

OTHER_WS="$TMP/other-workspace"
mkdir -p "$OTHER_WS/themes/boardroom"
printf '# Env Workspace Boardroom\n' > "$OTHER_WS/themes/boardroom/theme.md"
(cd "$CWD_SANDBOX" && env -i PATH="$PATH" HOME="$HOME_SANDBOX" COGNI_WORKSPACE_ROOT="$OTHER_WS" \
  python3 "$SEL" --slug boardroom --user-themes "$USER_THEMES" > "$TMP/flag-beats-env.json" 2>/dev/null)
(cd "$CWD_SANDBOX" && env -i PATH="$PATH" HOME="$HOME_SANDBOX" COGNI_WORKSPACE_ROOT="$OTHER_WS" \
  python3 "$SEL" --slug boardroom > "$TMP/env-only.json" 2>/dev/null)
jtrue "$TMP/flag-beats-env.json" "d['data']['theme_name'] == 'Boardroom User Override'"
a=$?
jtrue "$TMP/env-only.json" "d['data']['theme_name'] == 'Env Workspace Boardroom'"
b=$?
[ $a -eq 0 ] && [ $b -eq 0 ]
check $? "thl-08-precedence --user-themes beats COGNI_WORKSPACE_ROOT, which beats the bundled theme"

isolated python3 "$DISC" --user-themes "$USER_THEMES" --no-discover > "$TMP/discover.json" 2>/dev/null
jtrue "$TMP/discover.json" "[t['slug'] for t in d] == ['cogni-work', 'clean-slate', 'editorial', 'signal', 'acme-brand', 'boardroom'] and {t['slug'] for t in d if t['source'] == 'workspace'} == {'boardroom', 'acme-brand'} and sum(t['slug'] == 'boardroom' for t in d) == 1"
check $? "thl-09-discover-merge discovery recommends cogni-work, keeps bundled themes ahead of user themes, and shows a shadowed slug once"

# ---------------------------------------------------------------------------
# thl-10 / thl-11 — reads never modify or create the user location
# ---------------------------------------------------------------------------
before="$(tree_digest "$USER_THEMES")"
isolated python3 "$DISC" --user-themes "$USER_THEMES" --no-discover > /dev/null 2>&1
isolated python3 "$INSP" --user-themes "$USER_THEMES" --strict > /dev/null 2>&1
isolated python3 "$DRIFT" --user-themes "$USER_THEMES" > /dev/null 2>&1
isolated python3 "$SEL" --default --user-themes "$USER_THEMES" > "$TMP/default.json" 2>/dev/null
[ "$before" = "$(tree_digest "$USER_THEMES")" ]
check $? "thl-10-user-bytes-preserved discovery, inspection, drift and selection leave every user file and directory byte-identical"

ABSENT="$TMP/never-created"
isolated python3 "$DISC" --user-themes "$ABSENT" --no-discover > "$TMP/absent.json" 2>/dev/null
isolated python3 "$INSP" --user-themes "$ABSENT" > /dev/null 2>&1
isolated python3 "$DRIFT" --user-themes "$ABSENT" > /dev/null 2>&1
jtrue "$TMP/absent.json" "len(d) >= 5 and all(t['source'] == 'standard' for t in d)"
ok=$?
[ $ok -eq 0 ] && [ ! -e "$ABSENT" ]
check $? "thl-11-absent-user-location-not-created a missing user location yields bundled themes only and is never created"

# ---------------------------------------------------------------------------
# thl-12 — the bundled root is the scripts' own plugin, whatever the caller says
# ---------------------------------------------------------------------------
(cd "$CWD_SANDBOX" && env -i PATH="$PATH" HOME="$HOME_SANDBOX" CLAUDE_PLUGIN_ROOT="$TMP/some-other-plugin" \
  python3 "$DISC" --no-discover > "$TMP/foreign-root.json" 2>/dev/null)
jtrue "$TMP/foreign-root.json" "any(t['slug'] == 'cogni-work' and t['path'] == '$PUB/themes/cogni-work/theme.md' for t in d)"
check $? "thl-12-plugin-root-env-ignored a caller's CLAUDE_PLUGIN_ROOT does not move the bundled themes root"

jtrue "$TMP/default.json" "d['success'] and d['data']['theme_slug'] == 'cogni-work' and d['data']['source'] == 'standard'"
check $? "thl-13-select-default --default picks cogni-work as the recommended theme"

# ---------------------------------------------------------------------------
# thl-14 / thl-15 — the moved tree resolves in-plugin and carries no retired token
# ---------------------------------------------------------------------------
bad=""
walked=0
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  walked=$((walked + 1))
  rel="${ref#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  rel="${rel#\$CLAUDE_PLUGIN_ROOT/}"
  case "$rel" in *'<'*|*'{'*|*'arc-') continue ;; esac   # a placeholder or truncated glob names a pattern, not a file
  rel="${rel%/}"
  [ -e "$PUB/$rel" ] || bad="$bad $rel"
done <<EOF
$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_.$/<>{}-]*|\$CLAUDE_PLUGIN_ROOT/[A-Za-z0-9_.$/<>{}-]*' "$PUB/skills" 2>/dev/null | sort -u)
EOF
# The floor keeps the case falsifiable: a scan that stopped matching would walk
# nothing and report every reference resolved.
[ -z "$bad" ] && [ "$walked" -ge 10 ]
check $? "thl-14-plugin-root-refs-resolve every CLAUDE_PLUGIN_ROOT path the publishing skills document resolves inside cogni-publishing (walked $walked)${bad:+ — unresolved:$bad}"

grep -l 'cogni-visual:' "$PUB/references/theme-component-loader.md" "$PUB/scripts/load-theme-component.py" > /dev/null 2>&1
[ $? -eq 1 ]
check $? "thl-15-no-retired-dispatch-token the moved theme-component loader files carry no cogni-visual dispatch token"

# ---------------------------------------------------------------------------
# thl-16..19 — deterministic recommendation order
# ---------------------------------------------------------------------------
isolated python3 "$DISC" --no-discover > "$TMP/bundled-order.json" 2>/dev/null
jtrue "$TMP/bundled-order.json" "[t['slug'] for t in d] == ['cogni-work', 'boardroom', 'clean-slate', 'editorial', 'signal']"
check $? "thl-16-recommended-first bundled discovery lists cogni-work first, followed by the archetype presets in lexical slug order"

jtrue "$TMP/discover.json" "[t['source'] for t in d[:4]] == ['standard'] * 4 and [t['source'] for t in d[4:]] == ['workspace'] * 2"
check $? "thl-17-user-themes-last non-shadowed bundled themes precede user themes in discovery order"

MTIME_PLUGIN="$TMP/mtime-plugin"
mkdir -p "$MTIME_PLUGIN/themes"
cp -R "$PUB/themes/." "$MTIME_PLUGIN/themes/"
isolated python3 "$DISC" --plugin-root "$MTIME_PLUGIN" --no-discover > "$TMP/mtime-before.json" 2>/dev/null
python3 - "$MTIME_PLUGIN/themes" <<'PY'
import os, pathlib, sys
files = sorted(pathlib.Path(sys.argv[1]).glob("*/theme.md"))
for index, path in enumerate(reversed(files), 1):
    os.utime(path, (index, index))
PY
isolated python3 "$DISC" --plugin-root "$MTIME_PLUGIN" --no-discover > "$TMP/mtime-after.json" 2>/dev/null
python3 - "$TMP/mtime-before.json" "$TMP/mtime-after.json" <<'PY'
import json, sys
before = [item["slug"] for item in json.load(open(sys.argv[1], encoding="utf-8"))]
after = [item["slug"] for item in json.load(open(sys.argv[2], encoding="utf-8"))]
raise SystemExit(0 if before == after else 1)
PY
check $? "thl-18-mtime-independent changing every theme.md timestamp does not change discovery order"

NO_REFERENCE="$TMP/no-reference-plugin"
mkdir -p "$NO_REFERENCE/themes"
for slug in boardroom clean-slate editorial signal; do
  cp -R "$PUB/themes/$slug" "$NO_REFERENCE/themes/$slug"
done
isolated python3 "$DISC" --plugin-root "$NO_REFERENCE" --no-discover > "$TMP/no-reference.json" 2>/dev/null
jtrue "$TMP/no-reference.json" "[t['slug'] for t in d] == ['boardroom', 'clean-slate', 'editorial', 'signal']"
check $? "thl-19-no-reference-theme discovery without cogni-work remains deterministic and exits successfully"

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures theme-lifecycle check(s) failed."
  exit 1
fi
echo ""
echo "All theme-lifecycle checks passed."
