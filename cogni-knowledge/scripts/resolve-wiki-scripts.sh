# resolve-wiki-scripts.sh — shared shell probe for locating a cogni-wiki engine
# skill's scripts/ directory, sourced (never executed) by the knowledge-* SKILL.md
# flows. Keeping the probe in one file means a change to the resolution order
# lands once instead of being hand-applied across every flow. The Python peer
# (_knowledge_lib.resolve_wiki_scripts) stays a separate copy by necessity —
# standalone Python scripts cannot source a shell snippet.
#
# Usage (inside a SKILL.md shell block; CLAUDE_PLUGIN_ROOT preferred but optional —
# when unset, the plugin root is derived from this script's own sourced location):
#   . "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
#   WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || abort "..."
#
# bash 3.2 + stdlib only.

# Captured at SOURCE time, not function-run time: BASH_SOURCE[0] carries the
# sourced file path under bash; under zsh (FUNCTION_ARGZERO default) $0 carries
# it here at the top level but would be the *function name* inside the function
# body, so capturing later would derive a garbage root.
_RESOLVE_WIKI_SCRIPTS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd)"

resolve_wiki_scripts() {  # $1 = skill name, e.g. wiki-ingest / wiki-lint / wiki-health
  local skill="$1"
  # Vendored-first: cogni-knowledge ships a byte-identical copy of the engine
  # in-tree, so prefer it and stay self-contained. The external sibling/cache
  # probes below are the fallback (keeps both plugins installable until archive).
  local ep="${2:-}"   # $2 = optional entry-point script; when set, a probe branch
                      # wins only if "<dir>/$ep" is a file (a partial vendor falls through)
  # Plugin root: prefer CLAUDE_PLUGIN_ROOT, fall back to the root derived from
  # this script's own sourced location (nested-skill Bash blocks don't inherit
  # the env var). Without the guard, the cache glob below expands against an
  # empty prefix and zsh aborts fatally on the no-match (`no matches found`);
  # bash merely degrades to not-found.
  local _cpr="${CLAUDE_PLUGIN_ROOT:-$_RESOLVE_WIKI_SCRIPTS_ROOT}"
  local vend="${_cpr}/scripts/vendor/cogni-wiki/skills/${skill}/scripts"
  test -d "$vend" && { [ -z "$ep" ] || [ -f "$vend/$ep" ]; } && { echo "$vend"; return 0; }
  local sib="${_cpr}/../cogni-wiki/skills/${skill}/scripts"
  test -d "$sib" && { [ -z "$ep" ] || [ -f "$sib/$ep" ]; } && { echo "$sib"; return 0; }
  # pick the NEWEST cached version, not the lexically-first. Consider ONLY
  # numeric version dirs — sort -V ranks a non-numeric name (main/latest/a
  # branch checkout) ABOVE every real version, so a stray dir would otherwise
  # win. sort -V handles multi-digit segments (0.0.9 < 0.0.16 < 0.0.46).
  local newest ver
  newest=$(for d in "${_cpr}/../../cogni-wiki/"*/skills/"${skill}"/scripts; do
    [ -d "$d" ] || continue
    { [ -z "$ep" ] || [ -f "$d/$ep" ]; } || continue
    ver=${d%/skills/${skill}/scripts}; ver=${ver##*/}
    # Leading-paren case patterns: the closing-paren-only form trips bash 3.2's
    # case-inside-$(...) parser bug (the whole file then fails to source under
    # the macOS system bash); the balanced form is parsed by every bash + zsh.
    case "$ver" in ('') continue ;; (*[!0-9.]*) continue ;; esac
    printf '%s\n' "$d"
  done | sort -V | tail -1)
  [ -n "$newest" ] && { echo "$newest"; return 0; }
  return 1
}
