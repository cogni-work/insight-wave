#!/usr/bin/env bash
# Relocated-skill hygiene guard for the skills and agents cogni-workspace adopted
# from retired plugins: cogni-issues (from cogni-help), the troubleshoot material
# cogni-help contributed, now carried by workspace-status as its plugin-level tier, claims
# and claim-entity (from cogni-claims), copywriter / copy-reader plus two
# agents (from cogni-copywriting), and the render chain (from cogni-visual). The
# narrative skill, its agents and commands adopted from cogni-narrative, and the
# story-to-* brief producers adopted from cogni-visual, have since retired in favour
# of text-to-narrative, so their rows are gone rather than pointed at missing trees.
#
# A spec's tree may be a DIRECTORY or a single FILE. Adopted agents land as bare
# files under agents/, and the earlier directory-only form silently left every
# adopted agent ungraded — the cogni-claims adoption moved claim-verifier.md and
# source-inspector.md with no arm covering either. Both cases resolve the same
# way: `find` over a regular file yields that file, so only the existence tests
# needed widening from -d to -e.
#
# Each tree is paired with the dispatch token its OWN source plugin used, rather
# than checked against one global literal. A single shared token would be
# vacuous on half the trees and red on arrival on the other half: the claims
# trees legitimately carry no `cogni-help:` token, and asserting `cogni-claims:`
# over the cogni-issues tree would assert nothing at all. The pairing keeps every
# arm falsifiable against the plugin it actually came from.
#
# Why this exists. Two properties of those trees are load-bearing and nothing
# else in the repo enforces either one:
#
#   - No retired-plugin dispatch token may survive in the adopted copies. The
#     obvious candidate guard, scripts/check-external-dispatch.py, reaches only
#     part of that surface: its globs cover SKILL.md, agents, commands, hooks,
#     and a skill's own scripts/*.sh and scripts/*.py, while that skill's
#     evals/, references/ and every other file type under its scripts/ match
#     none of them. P1 below walks every file in both trees instead — the gap
#     is one of file-type coverage, not of what scripts/retired-plugins.json
#     carries.
#   - Every `${CLAUDE_PLUGIN_ROOT}`-relative path documented in those trees must
#     resolve under cogni-workspace. Most such paths are skill-relative and
#     survive relocation untouched, but a plugin-root-relative one silently
#     retargets: the source tree documented `${CLAUDE_PLUGIN_ROOT}/scripts/
#     course-status.sh`, which resolves to a cogni-workspace path that does not
#     exist and will not, because that script belongs to the course-delivery
#     system being retired. Nothing would have reported it.
#
# Scope. Every assertion reads the cogni-workspace tree ONLY. The properties
# under test belong to the destination copies, so no source tree is an input to
# any of them: this suite reads the same and passes the same whether or not a
# cogni-help tree exists anywhere in the repo. That independence is the point —
# relocation hygiene is checked where the relocated files actually live.
#
# Deliberately NOT asserted: counterpart-completeness against cogni-help. An
# assertion reading a tree this plugin does not own breaks whenever that tree
# changes or disappears — a guard a later change must remember to rewrite.
#
# Case-label shape is "PASS: <case>" / "FAIL: <case>", matching
# test-layering-claim-reconciled.sh and test-wiki-namespace-sync.sh, because the
# cogni-service mutation harness classifies a case green only on the PASS: form
# and red on the matching FAIL: form — printing only the failure line would leave
# every case unclassifiable as green. Case ids are P-prefixed and never bare
# numerals, so the trailing summary line is not read as a case's red line.
#
# Contract: runs as `bash <path>` with no arguments, from any cwd, touches no
# network, needs nothing beyond bash + coreutils, and exits non-zero on failure.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

# One "<tree>|<forbidden dispatch token>" spec per adopted tree. The token is the
# one the tree's own source plugin dispatched under, so each arm stays falsifiable.
#
# A spec's tree is directory-level only where that destination directory holds
# nothing but adopted files. Where the destination is shared, the spec names each
# adopted file instead. A directory-level spec over agents/, references/, scripts/,
# tests/ or hooks/ would fail on arrival against files this adoption never touched:
# those trees hold cogni-workspace's own long-standing files, and some of them carry
# a retired plugin's colon-form token legitimately — this file's own spec table most
# of all, where the literal is the guard's matching data rather than a dispatch.
# (The consumer surfaces that used to sit on that list — verify-theme-backcompat.sh
# and skills/manage-themes — were repointed at the consumer stage of the cogni-visual
# absorption; the file-level specs stand on the shared-destination argument alone,
# not on those files.)
# commands/ qualifies as directory-level: every file in it arrived by adoption
# (none is a long-standing cogni-workspace command), so the directory spec is
# green and additionally covers the commands adopted in earlier retirements,
# which no file-level row reached.
# `find` over a regular file yields that file, so bare-file specs walk fine.
TREE_SPECS="
$WS_ROOT/skills/cogni-issues|cogni-help:
$WS_ROOT/skills/workspace-status|cogni-help:
$WS_ROOT/skills/claims|cogni-claims:
$WS_ROOT/skills/claim-entity|cogni-claims:
$WS_ROOT/agents/claim-verifier.md|cogni-claims:
$WS_ROOT/agents/source-inspector.md|cogni-claims:
$WS_ROOT/skills/copywriter|cogni-copywriting:
$WS_ROOT/skills/copy-reader|cogni-copywriting:
$WS_ROOT/agents/copywriter.md|cogni-copywriting:
$WS_ROOT/agents/reader.md|cogni-copywriting:
$WS_ROOT/skills/enrich-report|cogni-visual:
$WS_ROOT/skills/render-html-slides|cogni-visual:
$WS_ROOT/libraries|cogni-visual:
$WS_ROOT/references/cartographic-data|cogni-visual:
$WS_ROOT/agents/brief-review-assessor.md|cogni-visual:
$WS_ROOT/agents/concept-diagram-svg.md|cogni-visual:
$WS_ROOT/agents/concept-diagram.md|cogni-visual:
$WS_ROOT/agents/editorial-sketch.md|cogni-visual:
$WS_ROOT/agents/enrich-report.md|cogni-visual:
$WS_ROOT/agents/enriched-report-reviewer.md|cogni-visual:
$WS_ROOT/agents/html-slides.md|cogni-visual:
$WS_ROOT/agents/pptx.md|cogni-visual:
$WS_ROOT/agents/render-infographic-pencil.md|cogni-visual:
$WS_ROOT/agents/render-infographic-sketchnote.md|cogni-visual:
$WS_ROOT/agents/render-infographic-whiteboard.md|cogni-visual:
$WS_ROOT/agents/report-html-writer.md|cogni-visual:
$WS_ROOT/agents/slides-enrichment-artist.md|cogni-visual:
$WS_ROOT/agents/storyboard.md|cogni-visual:
$WS_ROOT/agents/web.md|cogni-visual:
$WS_ROOT/references/agent-tool-declarations.md|cogni-visual:
$WS_ROOT/references/theme-component-loader.md|cogni-visual:
$WS_ROOT/scripts/breadcrumb-allowlist.txt|cogni-visual:
$WS_ROOT/scripts/cartographic-outline.py|cogni-visual:
$WS_ROOT/scripts/load-theme-component.py|cogni-visual:
$WS_ROOT/scripts/rasterize-sketch.py|cogni-visual:
$WS_ROOT/tests/test-arc-taxonomy-sync.sh|cogni-visual:
$WS_ROOT/tests/test-de-ascii-orthography.sh|cogni-visual:
$WS_ROOT/tests/test-excalidraw-canvas-lock.sh|cogni-visual:
$WS_ROOT/hooks/ensure-excalidraw-canvas.sh|cogni-visual:
$WS_ROOT/commands|cogni-visual:
"

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# Case P1 — no source-plugin dispatch token survives in any adopted tree.
#
# The colon form is deliberate, and for the claims trees it is not merely
# stylistic — it is the difference between a correct guard and a broken one.
# `cogni-claims` without the colon is the name of the on-disk claim store,
# `{working_dir}/cogni-claims/`, which those trees carry on purpose:
# skills/claims/scripts/claims-store.sh writes it and claim-entity's
# references/workspace-conventions.md documents it. That directory keeps its name
# by an explicit decision — renaming it would break every existing user's store
# with no migration path — so a bare-name check would be red on arrival against
# content the absorption is required to preserve.
#
# The same reasoning already applied to cogni-help: the known-issues.md catalogue
# documents the cogni-teacher -> cogni-help progress-file rename, and the evals
# assert exactly that diagnosis. Both now live under skills/workspace-status/,
# which is why that tree is the cogni-help arm's subject. Those are prose about
# another plugin, not a dispatch surface. The qualified form is the one that
# would break at runtime.
#
# P1 stays ONE aggregated case across all trees rather than splitting per tree,
# so a mutation recipe resolving `--case P1` keeps matching a single label.
# ---------------------------------------------------------------------------
p1_hits=""
p1_scanned=0
for spec in $TREE_SPECS; do
  tree="${spec%%|*}"
  token="${spec##*|}"
  if [ ! -e "$tree" ]; then
    fail "P1 adopted tree missing: cogni-workspace/${tree#"$WS_ROOT"/}"
    continue
  fi
  while IFS= read -r f; do
    p1_scanned=$((p1_scanned + 1))
    if grep -Fq "$token" "$f" 2>/dev/null; then
      p1_hits="$p1_hits $token@$f"
    fi
  done <<EOF
$(find "$tree" -type f)
EOF
done

if [ "$p1_scanned" -eq 0 ]; then
  # Liveness floor: a broken walk must not report clean.
  fail "P1 scanned zero files — the adopted trees are missing or unreadable"
elif [ -n "$p1_hits" ]; then
  for h in $p1_hits; do
    hit_file="${h#*@}"
    echo "  ${h%%@*} dispatch token in cogni-workspace/${hit_file#"$WS_ROOT"/}"
  done
  fail "P1 adopted trees must contain no source-plugin dispatch token"
else
  pass "P1 no source-plugin dispatch token in the adopted trees ($p1_scanned files scanned)"
fi

# ---------------------------------------------------------------------------
# Case P2 — every ${CLAUDE_PLUGIN_ROOT}-relative path resolves under cogni-workspace.
#
# BOTH spellings are extracted -- `${CLAUDE_PLUGIN_ROOT}` and bare
# `$CLAUDE_PLUGIN_ROOT`. The braced-only reader was blind to the unbraced form,
# which is the majority spelling in the adopted agents (render-infographic-pencil
# and editorial-sketch both use it for a runtime library read and a Bash script
# call). A relocation that repointed one of those to a path that does not exist
# would have left this arm green, which is the same silent-failure shape P3
# exists for, one spelling over.
#
# A reference ending in `/` is a directory reference and is resolved as one; every
# other reference is resolved as a file. The directory arm is load-bearing, not
# defensive: cogni-issues/SKILL.md documents the scripts directory itself as
# `${CLAUDE_PLUGIN_ROOT}/skills/cogni-issues/scripts/`, so a file-only check would
# be red on arrival.
#
# A reference carrying a `{placeholder}` segment is a template over a family of
# files and resolves as the directory enclosing the template. The extractor
# admits `{` and `}` on purpose: a character class without them cuts the
# copywriter's flat `.../references/arc-{arc_id}.md` down to `.../references/arc-`,
# which no file matches, so the arm would be red on a correct cite.
# ---------------------------------------------------------------------------
p2_bad=""
p2_scanned=0
for spec in $TREE_SPECS; do
  tree="${spec%%|*}"
  [ -e "$tree" ] || continue
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    p2_scanned=$((p2_scanned + 1))
    rel="${ref#\$\{CLAUDE_PLUGIN_ROOT\}}"
    rel="${rel#\$CLAUDE_PLUGIN_ROOT}"
    # A bare root reference names the plugin root itself and resolves trivially;
    # scoring it as a file would make every such mention a false offender.
    [ -n "$rel" ] || continue
    target="$WS_ROOT$rel"
    case "$ref" in
      *\{*)
        # A templated reference names a family of files, so it resolves as the
        # directory that encloses the template: the prefix before the first `{`
        # when it ends in `/`, else that prefix's dirname. Both shapes the
        # copywriter has cited are covered — `.../story-arc/{arc_id}/...` and
        # the flat `.../references/arc-{arc_id}.md`.
        prefix="${target%%\{*}"
        case "$prefix" in
          */) enclosing="$prefix" ;;
          *)  enclosing="$(dirname "$prefix")" ;;
        esac
        [ -d "$enclosing" ] || p2_bad="$p2_bad $ref"
        ;;
      */)
        [ -d "$target" ] || p2_bad="$p2_bad $ref"
        ;;
      *)
        [ -f "$target" ] || p2_bad="$p2_bad $ref"
        ;;
    esac
  done <<EOF
$(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}[A-Za-z0-9_./{}-]*|\$CLAUDE_PLUGIN_ROOT[A-Za-z0-9_./{}-]*' "$tree" 2>/dev/null | sort -u)
EOF
done

if [ "$p2_scanned" -eq 0 ]; then
  # Liveness floor: the adopted cogni-issues skill documents its script paths, so
  # zero extracted references means the extractor broke, not that the trees are clean.
  fail "P2 extracted zero \${CLAUDE_PLUGIN_ROOT} references — the extractor is broken"
elif [ -n "$p2_bad" ]; then
  for b in $p2_bad; do
    echo "  does not resolve under cogni-workspace: $b"
  done
  fail "P2 every \${CLAUDE_PLUGIN_ROOT} reference must resolve under cogni-workspace"
else
  pass "P2 all $p2_scanned \${CLAUDE_PLUGIN_ROOT} references resolve under cogni-workspace"
fi

# ---------------------------------------------------------------------------
# Case P3 — no repo-relative source-plugin PATH reference dangles in an adopted tree.
#
# P1 pins the DISPATCH form (`cogni-visual:`, with the colon). Nothing pinned the
# PATH form. Retiring a source plugin deletes its tree, so every surviving
# `cogni-visual/<dir>/...` path in an adopted copy silently stops resolving while
# P1, P2 and scripts/check-external-dispatch.py all stay green — they match the
# dispatch form only. That is the same silent-failure shape P1 exists for, one
# surface over, and it is the shape that actually bites at runtime: two relocated
# render agents open Step 1 with a mandatory "read <path> in full" prerequisite.
#
# The match is deliberately narrowed to the plugin-structure directories. A bare
# `<plugin>/` prefix would be red on arrival against the artifact-directory
# convention `{source_dir}/cogni-visual/`, which is a deliberate keep rather than
# an oversight — that path's next segment is an artifact filename, never one
# of the directories below, so the narrowing separates the two classes exactly.
#
# The assertion is "must RESOLVE", not "must not appear". A source plugin that is
# still live resolves fine and is not this guard's business; the defect is a path
# left pointing into a tree that no longer exists.
#
# Liveness floor counts FILES WALKED, not references extracted — unlike P2, the
# clean state here is zero references, so flooring on the reference count would
# fail on a correct tree.
# ---------------------------------------------------------------------------
p3_hits=""
p3_scanned=0
for spec in $TREE_SPECS; do
  tree="${spec%%|*}"
  token="${spec##*|}"
  src="${token%:}"
  [ -e "$tree" ] || continue
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    p3_scanned=$((p3_scanned + 1))
  done <<EOF
$(find "$tree" -type f)
EOF
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    [ -e "$REPO_ROOT/$ref" ] || p3_hits="$p3_hits $ref"
  done <<EOF
$(grep -rhoE "$src/(agents|skills|scripts|libraries|references|commands|hooks|tests)/[A-Za-z0-9_./-]*" "$tree" 2>/dev/null | sort -u)
EOF
done

if [ "$p3_scanned" -eq 0 ]; then
  # Liveness floor: a broken walk must not report clean.
  fail "P3 scanned zero files — the adopted trees are missing or unreadable"
elif [ -n "$p3_hits" ]; then
  for b in $p3_hits; do
    echo "  dangling source-plugin path: $b"
  done
  fail "P3 every repo-relative source-plugin path reference must resolve"
else
  pass "P3 no dangling source-plugin path reference in the adopted trees ($p3_scanned files scanned)"
fi

# ---------------------------------------------------------------------------

if [ "$failures" -gt 0 ]; then
  echo
  echo "FAIL: $failures relocated-skill hygiene test(s) failed."
  exit 1
fi

echo
echo "OK: relocated-skill hygiene checks passed."
