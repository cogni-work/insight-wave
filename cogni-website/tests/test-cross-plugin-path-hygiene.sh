#!/usr/bin/env bash
#
# Cross-plugin path hygiene for cogni-website.
#
# Every cross-plugin file path this plugin documents must resolve. A plugin that
# names a path into a tree that no longer exists sends its reader — often the
# agent running the skill — to a file that is not there, and nothing else in the
# repository grades it.
#
# SCOPE: cogni-website only, and that narrowness is deliberate rather than an
# oversight. A repo-wide form of this check is red on arrival and cannot be made
# green without edits well outside any one plugin's remit: cogni-knowledge alone
# carries dozens of files naming retired-plugin trees, because it vendors a
# retired engine and records its own absorption history as prose, and further
# references live in the repository-root guide and in the dated, deliberately
# frozen sweep artifacts under docs/. The sibling check for the absorption
# destination lives in cogni-workspace/tests/test-relocated-skill-hygiene.sh,
# whose own header states the same boundary for the same reason.
#
# The assertion is MUST-RESOLVE, never must-not-appear. Naming another live
# plugin's file is legitimate and common; naming one that is absent is the
# defect. That choice is what lets this suite carry no registry of retired
# plugin names, so it cannot go stale as the roster changes.
#
# Mutation recipe: see the pull request body. Three arms cover the repo-relative
# resolver, the sibling-form resolver, and the extraction floor.

set -u

SUITE_DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_DIR=$(cd "$SUITE_DIR/.." && pwd)
REPO_ROOT=$(cd "$PLUGIN_DIR/.." && pwd)

failures=0

pass() { printf '%s\n' "PASS: $1 $2"; }
fail() { printf '%s\n' "FAIL: $1 $2"; failures=$((failures + 1)); }

# Text surfaces this plugin ships. Kept to the shapes that carry prose paths.
FILE_LIST=$(find "$PLUGIN_DIR" -type f \
    \( -name '*.md' -o -name '*.sh' -o -name '*.py' -o -name '*.json' \) \
    | LC_ALL=C sort)

files_walked=0
for f in $FILE_LIST; do
    files_walked=$((files_walked + 1))
done

# --- w3: surface-shape floors -------------------------------------------------
# The two resolver cases below can only grade what the walk reaches. These three
# pin that it reaches each shape this plugin actually documents paths in, so a
# narrowed walk shows up here rather than as a quietly smaller reference set.

if printf '%s\n' "$FILE_LIST" | grep -q "^$PLUGIN_DIR/CLAUDE.md$"; then
    pass w3-surface-claude-md-reached "walk reached the plugin-root CLAUDE.md"
else
    fail w3-surface-claude-md-reached "walk did not reach the plugin-root CLAUDE.md"
fi

if printf '%s\n' "$FILE_LIST" | grep -q "^$PLUGIN_DIR/libraries/.*\.md$"; then
    pass w3-surface-libraries-reached "walk reached at least one libraries/*.md"
else
    fail w3-surface-libraries-reached "walk reached no libraries/*.md"
fi

if printf '%s\n' "$FILE_LIST" | grep -q "^$PLUGIN_DIR/skills/.*/SKILL\.md$"; then
    pass w3-surface-skill-md-reached "walk reached at least one skills/*/SKILL.md"
else
    fail w3-surface-skill-md-reached "walk reached no skills/*/SKILL.md"
fi

if [ "$files_walked" -ge 15 ]; then
    pass w1-floor-files-walked "walked $files_walked files"
else
    fail w1-floor-files-walked "walked only $files_walked files, expected at least 15"
fi

# --- w1: repo-relative cross-plugin references must resolve -------------------
# Extract <plugin>/<component-dir>/<path> and resolve it from the repository
# root. The component-dir alternation is what keeps a data-directory convention
# such as {source_dir}/cogni-foo/ from being read as a source path.

repo_refs=$(grep -rhoE 'cogni-[a-z-]+/(agents|skills|scripts|libraries|references|commands|hooks|tests)/[A-Za-z0-9_./-]+' \
    $FILE_LIST 2>/dev/null | LC_ALL=C sort)

refs_extracted=0
repo_bad=""
for ref in $repo_refs; do
    # Strip trailing sentence punctuation the pattern may have absorbed.
    clean=$(printf '%s\n' "$ref" | sed -e 's/[.,)]*$//')
    [ -n "$clean" ] || continue
    refs_extracted=$((refs_extracted + 1))
    if [ ! -e "$REPO_ROOT/$clean" ]; then
        repo_bad="$repo_bad $clean"
    fi
done

if [ "$refs_extracted" -ge 13 ]; then
    pass w1-floor-refs-extracted "extracted $refs_extracted repo-relative references"
else
    fail w1-floor-refs-extracted "extracted only $refs_extracted references, expected at least 13 — the resolver case below would pass vacuously"
fi

if [ -z "$repo_bad" ]; then
    pass w1-repo-relative-refs-resolve "all $refs_extracted repo-relative references resolve"
else
    fail w1-repo-relative-refs-resolve "unresolved:$repo_bad"
fi

# --- w2: sibling-form references must resolve through their own hop -----------
# The runtime form a skill tells its reader to open. Resolution goes through the
# literal hop so that damaging the hop alone is caught here even when the tail
# still resolves from the repository root, which is what w1 would see.
# Both the bare and braced spellings are accepted: the live sites spell it bare,
# while the braced spelling appears elsewhere in this plugin without a hop.

sibling_refs=$(grep -rhoE '[$]\{?CLAUDE_PLUGIN_ROOT\}?/[A-Za-z0-9_./-]+' \
    $FILE_LIST 2>/dev/null | grep -E '/\.\.?/' | LC_ALL=C sort)

sibling_found=0
sibling_bad=""
for ref in $sibling_refs; do
    tail_path=$(printf '%s\n' "$ref" | sed -e 's/^[$]{*CLAUDE_PLUGIN_ROOT}*//' -e 's/[.,)]*$//')
    [ -n "$tail_path" ] || continue
    sibling_found=$((sibling_found + 1))
    if [ ! -e "$PLUGIN_DIR$tail_path" ]; then
        sibling_bad="$sibling_bad $tail_path"
    fi
done

if [ "$sibling_found" -ge 3 ]; then
    pass w2-floor-sibling-refs-found "found $sibling_found sibling-form references"
else
    fail w2-floor-sibling-refs-found "found only $sibling_found sibling-form references, expected at least 3"
fi

if [ -z "$sibling_bad" ]; then
    pass w2-sibling-form-refs-resolve "all $sibling_found sibling-form references resolve"
else
    fail w2-sibling-form-refs-resolve "unresolved:$sibling_bad"
fi

# --- w4: publishing contracts are public and workspace-private reads retired -
if grep -Rqs 'cogni-publishing/references/' "$PLUGIN_DIR"; then
    pass w4-public-publishing-contract "website names a public publishing reference"
else
    fail w4-public-publishing-contract "no public cogni-publishing reference found"
fi

if grep -RqsE 'cogni-workspace/(skills/(text-to-narrative|copywriter|manage-themes)|libraries/(arc-taxonomy|web-section))/' "$PLUGIN_DIR"; then
    fail w4-no-workspace-private-publishing "workspace-private publishing path remains"
else
    pass w4-no-workspace-private-publishing "no workspace-private publishing path remains"
fi

if [ "$failures" -ne 0 ]; then
    printf '%s\n' "cross-plugin path hygiene: $failures failing case(s)"
    exit 1
fi
printf '%s\n' "cross-plugin path hygiene: all cases green"
exit 0
