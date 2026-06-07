# resolve-wiki-scripts.sh — shared shell probe for locating a cogni-wiki engine
# skill's scripts/ directory, sourced (never executed) by the knowledge-* SKILL.md
# flows. Keeping the probe in one file means a change to the resolution order
# lands once instead of being hand-applied across every flow. The Python peer
# (_knowledge_lib.resolve_wiki_scripts) stays a separate copy by necessity —
# standalone Python scripts cannot source a shell snippet.
#
# Usage (inside a SKILL.md shell block, with CLAUDE_PLUGIN_ROOT in the env):
#   . "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
#   WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || abort "..."
#
# bash 3.2 + stdlib only.

resolve_wiki_scripts() {  # $1 = skill name, e.g. wiki-ingest / wiki-lint / wiki-health
  local skill="$1"
  # Vendored-first: cogni-knowledge ships a byte-identical copy of the engine
  # in-tree, so prefer it and stay self-contained. The external sibling/cache
  # probes below are the fallback (keeps both plugins installable until archive).
  local ep="${2:-}"   # $2 = optional entry-point script; when set, a probe branch
                      # wins only if "<dir>/$ep" is a file (a partial vendor falls through)
  local vend="${CLAUDE_PLUGIN_ROOT}/scripts/vendor/cogni-wiki/skills/${skill}/scripts"
  test -d "$vend" && { [ -z "$ep" ] || [ -f "$vend/$ep" ]; } && { echo "$vend"; return 0; }
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-wiki/skills/${skill}/scripts"
  test -d "$sib" && { [ -z "$ep" ] || [ -f "$sib/$ep" ]; } && { echo "$sib"; return 0; }
  # pick the NEWEST cached version, not the lexically-first. Consider ONLY
  # numeric version dirs — sort -V ranks a non-numeric name (main/latest/a
  # branch checkout) ABOVE every real version, so a stray dir would otherwise
  # win. sort -V handles multi-digit segments (0.0.9 < 0.0.16 < 0.0.46).
  local newest ver
  newest=$(for d in "${CLAUDE_PLUGIN_ROOT}/../../cogni-wiki/"*/skills/"${skill}"/scripts; do
    [ -d "$d" ] || continue
    { [ -z "$ep" ] || [ -f "$d/$ep" ]; } || continue
    ver=${d%/skills/${skill}/scripts}; ver=${ver##*/}
    case "$ver" in ''|*[!0-9.]*) continue ;; esac
    printf '%s\n' "$d"
  done | sort -V | tail -1)
  [ -n "$newest" ] && { echo "$newest"; return 0; }
  return 1
}
