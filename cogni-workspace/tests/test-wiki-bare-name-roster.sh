#!/usr/bin/env bash
#
# Roster-derived bare-name scan over the wiki page CONTENT.
#
# Why this exists
# ---------------
# Retiring a plugin renames every dispatch token and every page filename that
# carries its name, and the resolver-facing guards catch those. What no guard
# caught until now is the plugin name written as bare prose inside a page body
# — "see the cogni-research plugin" — which resolves to nothing, reads as
# current, and survives a retirement silently. A sweep fixed the occurrences
# that existed; this suite is what stops the next retirement leaving the class
# behind again.
#
# Contract under test
# -------------------
#   - No `cogni-…` token anywhere in a page present in BOTH wiki trees names
#     something absent from the live roster. "Body" in this suite's name means
#     the page CONTENT as opposed to its FILENAME — the sibling namespace guard
#     owns filenames — and the scan deliberately covers frontmatter too, since a
#     retired name in a `sources:` URL or a `related:` link is exactly as stale
#     as one in prose.
#   - The allowed set is derived at RUNTIME from the marketplace manifest, so a
#     plugin retired tomorrow is caught without editing this file.
#   - Each tree is scanned by its own call, so neutralising one arm reds a case.
#   - An arm that cannot see pages, or cannot read a roster, FAILS loudly rather
#     than reporting clean.
#
# Roster-derived, never a denylist
# --------------------------------
# A hardcoded list of today's retired names would pass every case here and catch
# nothing at the next absorption — it encodes one historical event rather than
# the rule. The roster is therefore read from `plugins[].name` and everything
# off it is an offender. Retired names appear in this file only inside fixtures
# and inside the reasoned allowances below, never as a scan needle.
#
# EXTRA_ALLOWED is appended by the MATCHER, not by roster_from
# -----------------------------------------------------------
# The sibling namespace guard folds its extra names into roster_from's return
# value. This suite deliberately does not: if the constant were baked in there,
# a manifest with an empty `plugins[]` would still yield a non-empty roster and
# the roster-size liveness floor below could never reach zero. Keeping the two
# separate is what lets that floor be a real assertion. Do not "fix" this back
# to the sibling's shape.
#
# Two surfaces: the page INTERSECTION, and an explicit tree-level SET
# -------------------------------------------------------------------
# Under `pages/`, only pages present in both trees are scanned, and that is
# load-bearing rather than stylistic: scanning the union would be red on
# arrival. The one root-only page is a frozen, dated lint report that names
# plugins retired since it was written, and the bundled-only pages are held
# pending a maintainer ruling on their fate — editing either to satisfy a guard
# would pre-decide that ruling.
#
# One level above `pages/` sits the second surface. `index.md` and `overview.md`
# are scanned by `scan_tree_level` over an explicit two-name set, once PER TREE
# rather than over an intersection: the two `index.md` copies diverge by design
# (the decisions record's Decision 3, group C), so an intersection-shaped arm
# would skip exactly the pair it exists to watch. `log.md` is deliberately in
# neither surface — it is frozen dated history whose ingest lines name retired
# plugins, so scanning it would be red on arrival and would force precisely the
# exclusion list described next.
#
# Because the bundled-only and one-sided pages fall out of the intersection by
# construction, and the tree-level surface is a two-name ALLOWLIST rather than a
# directory scan minus `log.md`, this suite carries ZERO path-fragment
# exclusion entries. That
# matters: a sibling guard records that a substring-matched exclusion list turns
# one loose fragment into a repo-wide exemption. The fix for a red here is to
# rename the stale name, never to add an exclusion — but note WHERE the hit is:
# a name in prose is this suite's to fix outright, while a name in a frontmatter
# `id:` or a wikilink is also a resolver concern, so the rename has to leave the
# tree-parity guard green rather than trade one red for another.
#
# The promotion probe (B28) reaches the bundled-only pages, which the
# intersection surface cannot see. It DERIVES that set as the complement of the
# same shared_basenames the intersection arm uses, so no page is named anywhere
# and the two sets cannot drift apart. That is deliberate: a literal list would
# have been the exclusion class this paragraph forbids wearing the opposite
# sign. Do not be tempted back to one — the arm's `total -eq 0` floor fires only
# when EVERY named page vanishes, so a list going stale one page at a time would
# narrow coverage silently, with every case still green.
#
# As of #1402 every bundled-only page has been promoted, so the derived set is
# empty and the probe is dormant by construction rather than red: its call site
# answers the empty case directly instead of handing the floor a set it would
# correctly refuse.
#
# The five declared allowances, and why each is token-exact
# --------------------------------------------------------
#   - Plugins hosted in a DIFFERENT marketplace are live, not retired, and are
#     legitimately absent from this repo's manifest. They are named in
#     EXTRA_ALLOWED.
#   - The GitHub ORG token appears in source URLs throughout the surface. Its
#     allowance is keyed to the exact token plus a trailing slash, never a
#     prefix: a prefix would bless every future off-roster name that happens to
#     start with the same letters, while the live roster entry sharing that
#     prefix already passes on the roster arm.
#   - The on-disk claim store keeps a directory name from a plugin that no
#     longer ships. The discriminator is the delimiter, as the plugin guide
#     states: the path form is preserved, the dispatch (colon) form is not. So
#     the allowance is keyed to that one token plus a slash — NOT to a blanket
#     "any name followed by a slash", which would also exempt a path naming a
#     genuinely retired plugin.
#   - One PAST-TENSE HISTORICAL FRAMING names a retired plugin as removed. The
#     sentence is accurate, asserts no live data flow, and is the kind of
#     statement a roster sweep must not "fix". The allowance is keyed to one
#     token plus CONTAINMENT of one complete frozen sentence — never the token
#     alone, which would bless every future live-assertion use of that name,
#     and never the page path, which is the exclusion shape forbidden above.
#     It is line-scoped: re-wrapping the paragraph that carries the sentence
#     re-reds the page. That is the intended conservative failure — a reflow is
#     an invitation to re-affirm the framing, not to keep blessing it silently.
#   - A SKILL of a live roster plugin can share the `cogni-` prefix, and the
#     matcher cannot span a colon: `cogni-workspace:cogni-issues` tokenizes as
#     `cogni-workspace:` (clean on the roster arm) and then a BARE
#     `cogni-issues`, so writing the qualified form does not rescue it. The
#     allowance is DERIVED at runtime from the skill directories of plugins on
#     the live roster — never written down — in the same spirit as
#     `roster_from`: a skill that stops shipping stops being blessed with no
#     edit here. Restricting it to roster plugins is what stops a retired
#     plugin's leftover skill tree from blessing anything.
#
# Allowance 5 blesses exactly ONE token across both real trees today,
# `cogni-issues`, and that is what keeps the two pages naming it clean WITHOUT a
# content edit — one of them writes the correctly qualified
# `cogni-workspace:cogni-issues`, which the tokenizer splits anyway. Rewriting
# correct prose to satisfy a scanner is the wrong direction. If someone later
# "fixes" those pages, B28 goes vacuous rather than red, which is why B26 owns
# the allowance's green half on a fixture of its own. Since #1402 both pages sit
# in the two-tree intersection, so B1 scans them and B28 no longer reaches them
# at all.
#
# Residual, named rather than papered over: a skill deliberately named after a
# retired plugin would be blessed. Nothing in the tree is — the domain-prefix
# convention makes it an anomaly — and closing it mechanically would need
# exactly the retired-name list this suite refuses to keep.
#
# The red halves of the org-token and store-path cases are exercised by fixtures
# only: no bare org token and no colon form of the store name exists in either
# tree today. That is forward-looking policy, not dead config — silence there
# would be a latent wrong answer the first time someone wrote one.
#
# Case-label shape
# ----------------
# Labels are `PASS: <id> <text>` / `FAIL: <id> <text>` with a letter-prefixed id
# and a single space after it, never a colon. The mutation harness matches the
# id as a whole token, so an id written with a trailing colon reports
# "case not found" instead of a verdict. The final summary line is numeral-led
# so it can never be read as a case's red line. Emitters stay plain: a colour
# before the label defeats the same match, and the repo-wide result-line
# plainness guard forbids an escape sequence anywhere in this file, including
# inside an emitter body.
#
# Mutation recipe
# ---------------
# Drive the boundary case, not the real-tree case: the real trees are already
# clean, so weakening that comparison leaves it green and the harness correctly
# reports the guard vacuous. Collapsing the boundary-aware alternation in the
# matcher to a bare prefix glob makes the retired look-alike match the live
# roster entry, which reds the boundary case while the real-tree case stays
# green. The harness ships in the service repo, not this one.
#
# For the tree-level arm, drive it separately: an early `return 0` inserted into
# `scan_tree_level` neutralises both of its per-tree calls while leaving the
# intersection arm untouched, so the tree-level red and floor cases go red while
# the real-tree cases — which assert rc 0, exactly what a neutralised arm
# returns — stay green. That asymmetry is the point: it shows the arm is
# falsifiable on its own rather than riding on the shared matcher.
#
# For the slash allowance, drive it at the constant: dropping the store token
# from the allowed set while leaving the org token alone reds B23, which owns
# that allowance's green half on a fixture of its own. B1 reds alongside it,
# because the live intersection genuinely carries the path form — but B7 and
# B22 both stay GREEN, and naming them individually matters because they do not
# move together: B7's store-token needle is an assert_out_has that the
# newly-offending slash form also satisfies, and the real tree-level pages B22
# scans carry no store token at all. That is why the green half needs B23 rather
# than riding on B1: B1's coverage is incidental on what the live trees happen
# to contain, so a page retirement or a sweep could remove it with every case
# still green.
#
# For the historical-framing allowance, drive it at the constant too, but at the
# SENTENCE rather than the token: emptying HISTORICAL_SENTENCE turns the
# containment test into a tautology, which widens the allowance from one frozen
# sentence to the whole token. B25 — the red half, a live present-tense framing
# of the same name on a fixture of its own — stops flagging and goes RED. B24,
# B28, B1 and B22 all stay GREEN, and naming them individually matters because
# they do not move together: B24 still satisfies a tautological containment,
# B28 is dormant on an empty derived set since #1402, and neither real-tree
# case scans a page carrying that token at all. That asymmetry is the point — it shows the sentence scope is
# load-bearing rather than decorative. The constant must stay double-quoted at
# column 0 for the expression to bite; a single-quoted or indented definition
# makes it a no-op and the harness reports `expr_no_op` rather than a verdict.
#
# For the skill-name allowance, drive it at the derivation, not a constant:
# there is nothing written down to edit. Widening `skill_names_from`'s roster
# membership test to accept any plugin directory reds B27, whose second arm
# plants a skill under an off-roster plugin precisely to prove the restriction
# is load-bearing. B26 stays GREEN (its skill sits under a roster plugin either
# way), and so do B1, B22 and B28.
#
# Portability: bash 3.2 (stock macOS /bin/bash) — no associative arrays, no
# mapfile/readarray, no case-modifying expansions, no globstar. Stdlib only:
# bash, coreutils, and python3 for JSON. No network.
#
# Assertions here match only this suite's own emitted literals. A foreign
# tool's diagnostic wording is localized, so asserting on it would pass
# vacuously on a non-English host.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$WS_ROOT/.." && pwd)"
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Plugins that legitimately live outside this repo's marketplace. See the header.
EXTRA_ALLOWED="cogni-docs cogni-service"

# The one past-tense historical framing that names a retired plugin as removed;
# see the header for why it is keyed to the sentence and not the token. Both
# must stay double-quoted at column 0 — the mutation recipe drives
# HISTORICAL_SENTENCE by that exact shape.
HISTORICAL_TOKEN="cogni-consulting"
HISTORICAL_SENTENCE="This replaces the former Double Diamond playbook — the cogni-consulting plugin was removed and its source lives only in git history."

# The GitHub organisation token, and the preserved on-disk store directory.
# Each is allowed ONLY as the exact token followed by a slash. See the header.
ORG_TOKEN="cogni-work"
STORE_TOKEN="cogni-claims"
SLASH_ALLOWED="$ORG_TOKEN $STORE_TOKEN"

# The tree-level surface, one level above `pages/`. An ALLOWLIST of two names,
# never a directory scan minus an exclusion — that distinction is what keeps
# this suite's zero-path-fragment-exclusions property true. `log.md` is absent
# on purpose: the decisions record's Decision 5 freezes it as dated history, and
# its ingest lines name plugins retired since they were written.
TREE_LEVEL_PAGES="index.md overview.md"

# ---------------------------------------------------------------------------
# The checker. Fixture cases and the real-tree case drive these same functions —
# the matcher is never reimplemented in a case body, so pointing a case at a
# broken matcher turns that case red.
# ---------------------------------------------------------------------------

# roster_from <marketplace.json> -> space-padded roster string (NO extras).
# Reads ONLY plugins[].name. The file's top-level "name" is the marketplace
# itself and "owner" is an object carrying a human name; a generic walk for any
# "name" key would pick both up as phantom namespaces.
roster_from() {
  local mf="$1" names
  # stderr, not stdout: every caller captures stdout into the roster string,
  # so a message echoed there would be swallowed instead of reported.
  [ -f "$mf" ] || { echo "ERROR marketplace manifest not found: $mf" >&2; return 1; }
  names="$(python3 -c '
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
print(" ".join(p["name"] for p in data["plugins"]))
' "$mf")" || return 1
  echo " $names "
}

# skill_names_from <repo_root> <roster> -> space-padded skill basenames.
# DERIVED, never written down: the skill directories of plugins on the LIVE
# roster. See the header for why the roster restriction is load-bearing; B27's
# second arm is what proves it.
skill_names_from() {
  local root="$1" roster="$2" out="" d plug base
  # Two-level glob, not `**`: bash 3.2 has no globstar (see the header).
  for d in "$root"/cogni-*/skills/cogni-*/; do
    # bash 3.2 has no nullglob, so an unmatched pattern survives LITERALLY.
    # Reject that token at the source. Nothing downstream would break if it got
    # through — both consumers quote it into a case pattern (`*" $plug "*` below,
    # `*" $tok "*` at Allowance 5), and quoting makes the `*` literal, so `cogni-*`
    # matches nothing rather than everything. This buys a truthful set, not safety.
    [ -d "$d" ] || continue
    base="${d%/}"; base="${base##*/}"
    plug="${d%/skills/*}"; plug="${plug##*/}"
    # `roster` arrives space-padded, so this is the same declarative membership
    # test scan_tree uses for `shared` — not a loop that could drift from it.
    case "$roster" in
      *" $plug "*) ;;
      *) continue ;;
    esac
    out="$out$base "
  done
  echo " $out"
}

# shared_basenames <dirA> <dirB> -> space-padded basenames present in BOTH.
# What keeps the top-level index / log / overview pages out of THIS surface is
# the SCAN ROOT: they sit one level above `pages/`, so no glob rooted here can
# reach them. Non-recursion is not what excludes them — both page dirs are flat
# today, so it currently selects nothing. `index.md` and `overview.md` are
# reached instead by `scan_tree_level`'s explicit basename set, which is why
# this root is never repointed at the parent: doing so would also pull in
# `log.md`, with no exclusion mechanism to catch it.
shared_basenames() {
  local a="$1" b="$2" f base out=""
  for f in "$a"/*.md; do
    [ -e "$f" ] || continue
    base="${f##*/}"
    [ -f "$b/$base" ] || continue
    out="$out$base "
  done
  echo " $out"
}

# tree_only_basenames <dirA> <dirB> -> space-padded basenames present in dirB
# but NOT in dirA — the exact complement of shared_basenames, so the two cannot
# drift apart. This is the bundled-only set: the pages Decision 4 holds out of
# the root tree, which the intersection surface can never reach.
tree_only_basenames() {
  local a="$1" b="$2" f base out=""
  for f in "$b"/*.md; do
    [ -e "$f" ] || continue
    base="${f##*/}"
    [ -f "$a/$base" ] && continue
    out="$out$base "
  done
  echo " $out"
}

# scan_file <file> <label> <roster> [skills] -> 0 clean, 1 when it emitted any offender.
# The five declared allowances live HERE and nowhere else, so the intersection
# arm and the tree-level arm cannot silently diverge on what they bless.
scan_file() {
  local f="$1" label="$2" roster="$3" skills="${4-}"
  local base="${f##*/}"
  local offenders=0 hit tok dl p matched lineno hline

  # Capture the token together with the one delimiter that can follow it, so
  # the path form and the dispatch form are distinguishable. The character
  # class is greedy, which is what keeps a longer off-roster name from being
  # truncated into a shorter allowed one.
  # `-n` prefixes each hit with `N:`. A line number never contains a colon and
  # the delimiter is at most one TRAILING character, so `12:cogni-workspace:`
  # and `12:cogni-work/` both round-trip through these two expansions. Splitting
  # here, before the delimiter case below, leaves every downstream comparison
  # working on exactly the token it did before the line number existed.
  for hit in $(grep -noE 'cogni-[a-z0-9-]+[/:]?' "$f" 2>/dev/null || true); do
    lineno="${hit%%:*}"
    hit="${hit#*:}"
    case "$hit" in
      */) tok="${hit%/}"; dl="/" ;;
      *:) tok="${hit%:}"; dl=":" ;;
      *)  tok="$hit";     dl=""  ;;
    esac

    matched=0
    for p in $roster $EXTRA_ALLOWED; do
      # Boundary-aware: the name exactly, or the name followed by "-".
      case "$tok" in
        "$p"|"$p"-*) matched=1; break ;;
      esac
    done
    # One slash-allowance mechanism, not two: the delimiter rule lives in a
    # single place so the two entries cannot silently diverge. The comparison
    # stays an EQUALITY, so this is still token-exact and never a prefix, and
    # never a blanket "any name followed by a slash".
    if [ "$matched" -eq 0 ] && [ "$dl" = "/" ]; then
      for p in $SLASH_ALLOWED; do
        [ "$tok" = "$p" ] && { matched=1; break; }
      done
    fi

    # Allowance 4 — the past-tense historical framing. Keyed to one token AND
    # containment of one complete frozen sentence, so it blesses that sentence
    # and nothing else: the same name in a live framing still flags. The line is
    # fetched only on the unmatched path for this one token, so the hot loop is
    # unchanged. Containment, not equality — the carrier line is a whole
    # paragraph whose second sentence is the frozen one.
    if [ "$matched" -eq 0 ] && [ "$tok" = "$HISTORICAL_TOKEN" ]; then
      hline="$(sed -n "${lineno}p" "$f" 2>/dev/null)"
      case "$hline" in
        *"$HISTORICAL_SENTENCE"*) matched=1 ;;
      esac
    fi

    # Allowance 5 — a skill name of a live-roster plugin. Equality against the
    # derived set, for any delimiter: the matcher cannot span a colon, so the
    # qualified `cogni-workspace:cogni-issues` still arrives here as a BARE
    # second token and writing the qualified form does not rescue it.
    if [ "$matched" -eq 0 ]; then
      case "$skills" in *" $tok "*) matched=1 ;; esac
    fi

    if [ "$matched" -eq 0 ]; then
      echo "OFF-ROSTER [$label] $base: $tok"
      offenders=$((offenders + 1))
    fi
  done

  [ "$offenders" -eq 0 ] || return 1
  return 0
}

# scan_tree <pages_dir> <label> <roster> <shared> -> 0 clean, 1 otherwise.
scan_tree() {
  local dir="$1" label="$2" roster="$3" shared="$4" skills="${5-}"
  local offenders=0 total=0
  local f base

  # Roster liveness floor. A manifest that parsed but carried no plugins would
  # otherwise make every token an offender or — with the extras folded in —
  # quietly bless a nearly-empty allowed set. This is a boolean, not a metric:
  # the roster is empty exactly when it holds no non-whitespace character.
  case "$roster" in
    *[![:space:]]*) ;;
    *)
      echo "ERROR [$label] roster is empty; refusing to scan against nothing"
      return 1 ;;
  esac

  if [ ! -d "$dir" ]; then
    echo "ERROR [$label] pages directory not found: $dir"
    return 1
  fi

  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    base="${f##*/}"
    # Only pages present in BOTH trees are in the declared surface.
    case "$shared" in
      *" $base "*) ;;
      *) continue ;;
    esac
    total=$((total + 1))
    scan_file "$f" "$label" "$roster" "$skills" || offenders=$((offenders + 1))
  done

  # Pages-scanned liveness floor. Without it, an arm pointed at a missing or
  # empty directory reports clean, and a half-dead guard is indistinguishable
  # from a working one — both trees are already clean, so nothing else would
  # notice its scan had stopped running.
  if [ "$total" -eq 0 ]; then
    echo "ERROR [$label] no shared .md pages found under $dir"
    return 1
  fi

  [ "$offenders" -eq 0 ] || return 1
  return 0
}

# scan_tree_level <wiki_dir> <label> <roster> -> 0 clean, 1 otherwise.
# The tree-level sibling of scan_tree, and deliberately NOT a variant of it: it
# takes no `shared` argument. The two `index.md` copies diverge by design, so an
# intersection-shaped arm would silently skip the very pair this arm exists to
# watch. Called once per tree, each copy is graded against the roster on its own
# terms and neither is ever compared to the other.
scan_tree_level() {
  local dir="$1" label="$2" roster="$3" skills="${4-}"
  local offenders=0 total=0
  local base f

  # Same roster liveness floor as scan_tree, for the same reason: a manifest
  # that parsed but carried no plugins must never read as "nothing to flag".
  case "$roster" in
    *[![:space:]]*) ;;
    *)
      echo "ERROR [$label] roster is empty; refusing to scan against nothing"
      return 1 ;;
  esac

  for base in $TREE_LEVEL_PAGES; do
    f="$dir/$base"
    [ -f "$f" ] || continue
    total=$((total + 1))
    scan_file "$f" "$label" "$roster" "$skills" || offenders=$((offenders + 1))
  done

  # Pages-scanned liveness floor. This single branch also covers a missing
  # directory — no named page resolves under one, so the counter stays zero and
  # the arm fails loudly instead of reporting a clean scan of nothing. That is
  # why there is no separate directory-exists test here.
  if [ "$total" -eq 0 ]; then
    echo "ERROR [$label] no tree-level pages found under $dir"
    return 1
  fi

  [ "$offenders" -eq 0 ] || return 1
  return 0
}

# scan_repo <repo_root> -> 0 clean, 1 otherwise. Scans BOTH trees on BOTH
# surfaces; each arm is a separate call so any one can be independently
# neutralised by a mutation.
scan_repo() {
  local root="$1" roster shared rc=0
  local root_pages="$root/wiki/wiki/pages"
  local ws_pages="$root/cogni-workspace/wiki/wiki/pages"
  roster="$(roster_from "$root/.claude-plugin/marketplace.json")" || return 1
  local skills
  skills="$(skill_names_from "$root" "$roster")"
  shared="$(shared_basenames "$root_pages" "$ws_pages")"
  scan_tree "$root_pages" "root" "$roster" "$shared" "$skills" || rc=1
  scan_tree "$ws_pages" "workspace" "$roster" "$shared" "$skills" || rc=1
  scan_tree_level "$root/wiki/wiki" "root-toplevel" "$roster" "$skills" || rc=1
  scan_tree_level "$root/cogni-workspace/wiki/wiki" "workspace-toplevel" "$roster" "$skills" || rc=1
  return "$rc"
}

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

RC=0
OUT=""

run_scan_repo() { OUT="$(scan_repo "$1" 2>&1)"; RC=$?; }
run_scan_tree() { OUT="$(scan_tree "$1" "$2" "$3" "$4" "${5-}" 2>&1)"; RC=$?; }
run_scan_tree_level() { OUT="$(scan_tree_level "$1" "$2" "$3" "${4-}" 2>&1)"; RC=$?; }

assert_rc() { # <expected-rc>
  [ "$RC" -eq "$1" ] && return 0
  echo "     expected rc=$1, got rc=$RC; output:"
  echo "$OUT" | sed 's/^/       /'
  return 1
}
assert_out_has() {
  case "$OUT" in *"$1"*) return 0 ;; esac
  echo "     expected output to contain: $1"
  echo "$OUT" | sed 's/^/       /'
  return 1
}
assert_out_lacks() {
  case "$OUT" in *"$1"*) echo "     expected output NOT to contain: $1"; return 1 ;; esac
  return 0
}

# mk_body <path> <body-line> — a schema-shaped fixture page with a chosen body.
mk_body() {
  local dir="${1%/*}" base="${1##*/}"
  [ -d "$dir" ] || mkdir -p "$dir"
  printf -- '---\nid: %s\ntitle: fixture\ntype: fixture\n---\n\n%s\n' \
    "${base%.md}" "$2" > "$1"
}

# mk_sourced_page <path> <related-token> — a fixture shaped like a real page:
# the org URL in a frontmatter `sources:` list AND in a footer Source link,
# which is where the overwhelming majority of org-token occurrences actually
# sit. The <related-token> goes in a frontmatter `related:` entry. This is the
# fixture that pins FRONTMATTER coverage: with a body-only scan, a retired name
# planted in `related:` would go unreported and case B14 reds.
mk_sourced_page() {
  local dir="${1%/*}" base="${1##*/}"
  [ -d "$dir" ] || mkdir -p "$dir"
  {
    printf -- '---\n'
    printf -- 'id: %s\n' "${base%.md}"
    printf -- 'title: fixture\ntype: fixture\n'
    printf -- 'sources:\n'
    printf -- '  - https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/x.md\n'
    printf -- 'related:\n'
    printf -- '  - %s\n' "$2"
    printf -- '---\n\n'
    printf -- 'Prose naming nothing stale.\n\n'
    printf -- '**Source**: [x.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/cogni-workspace/x.md)\n'
  } > "$1"
}

# mk_sourced_both <root> <basename> <related-token>
mk_sourced_both() {
  mk_sourced_page "$1/wiki/wiki/pages/$2" "$3"
  mk_sourced_page "$1/cogni-workspace/wiki/wiki/pages/$2" "$3"
}

# mk_marketplace <path> <plugin-names...> — carries the same confusable shape as
# the real manifest: a top-level "name" and an "owner" object with its own name.
mk_marketplace() {
  local out="$1"; shift
  local dir="${out%/*}"
  [ -d "$dir" ] || mkdir -p "$dir"
  python3 -c '
import json, sys
out = sys.argv[1]
names = sys.argv[2:]
doc = {
    "name": "fixture-marketplace",
    "owner": {"name": "Fixture Owner", "email": "fixture@example.invalid"},
    "plugins": [{"name": n, "source": "./" + n} for n in names],
}
with open(out, "w") as fh:
    json.dump(doc, fh, indent=2)
' "$out" "$@"
}

# mk_fixture_repo <root> — a two-armed stand-in. BOTH arms carry the same clean
# page, so it is in the intersection: the liveness floor fails an arm with no
# shared pages, so a one-armed fixture would false-fail every "exits 0" case.
mk_fixture_repo() {
  local root="$1"
  mk_marketplace "$root/.claude-plugin/marketplace.json" cogni-workspace cogni-consult
  mk_both "$root" "concept-baseline.md" "The cogni-workspace plugin is live."
  # The tree-level arm carries its own liveness floor, so a fixture with no
  # index/overview would fail every "exits 0" case on that floor rather than on
  # what the case actually tests. Both bodies stay on-roster.
  mk_toplevel_both "$root" "index.md" "Catalogue for the cogni-workspace trees."
  mk_toplevel_both "$root" "overview.md" "Overview of the cogni-workspace wiki."
}

# mk_toplevel_both <root> <basename> <body> — the tree-level counterpart of
# mk_both: writes one level above `pages/`, where scan_tree_level looks.
mk_toplevel_both() {
  mk_body "$1/wiki/wiki/$2" "$3"
  mk_body "$1/cogni-workspace/wiki/wiki/$2" "$3"
}

# mk_skill_dir <root> <plugin> <skill> — plant a skill directory so
# skill_names_from can derive its basename. The derivation globs directories, so
# no file is written.
mk_skill_dir() {
  mkdir -p "$1/$2/skills/$3"
}

# mk_both <root> <basename> <body> — write the same body into both trees.
mk_both() {
  mk_body "$1/wiki/wiki/pages/$2" "$3"
  mk_body "$1/cogni-workspace/wiki/wiki/pages/$2" "$3"
}

# ---------------------------------------------------------------------------
# B1 — the real trees are clean (asserted here, not only in fixtures).
# ---------------------------------------------------------------------------
run_scan_repo "$REPO_ROOT"
if assert_rc 0; then
  pass "B1 real wiki page bodies carry no off-roster plugin names"
else
  fail "B1 real wiki page bodies carry no off-roster plugin names"
fi

# ---------------------------------------------------------------------------
# B2 — an offender on the ROOT arm is named, with that arm's label.
# ---------------------------------------------------------------------------
R2="$TMPROOT/b2"; mk_fixture_repo "$R2"
mk_both "$R2" "concept-drift.md" "Clean baseline."
mk_body "$R2/wiki/wiki/pages/concept-drift.md" "See the cogni-research plugin."
run_scan_repo "$R2"
if assert_rc 1 && assert_out_has "OFF-ROSTER [root] concept-drift.md: cogni-research"; then
  pass "B2 a bare retired name on the root tree is flagged with the root label"
else
  fail "B2 a bare retired name on the root tree is flagged with the root label"
fi

# ---------------------------------------------------------------------------
# B3 — an offender on the WORKSPACE arm is named, with that arm's label. B2 and
# B3 together are what make each arm independently deletable-and-red.
# ---------------------------------------------------------------------------
R3="$TMPROOT/b3"; mk_fixture_repo "$R3"
mk_both "$R3" "concept-drift.md" "Clean baseline."
mk_body "$R3/cogni-workspace/wiki/wiki/pages/concept-drift.md" "See the cogni-wiki plugin."
run_scan_repo "$R3"
if assert_rc 1 && assert_out_has "OFF-ROSTER [workspace] concept-drift.md: cogni-wiki"; then
  pass "B3 a bare retired name on the workspace tree is flagged with the workspace label"
else
  fail "B3 a bare retired name on the workspace tree is flagged with the workspace label"
fi

# ---------------------------------------------------------------------------
# B4 — boundary. A retired look-alike that merely EXTENDS a live roster name is
# still an offender, and the live name itself is not flagged. This is the case
# the mutation recipe in the header drives.
# ---------------------------------------------------------------------------
R4="$TMPROOT/b4"; mk_fixture_repo "$R4"
# The live name and the retired look-alike sit on SEPARATE pages, so the
# "not flagged" half is asserted on a page basename rather than on a name that
# is a prefix of the offender — a needle that is a substring of the red line
# could never fail, and the green half would assert nothing.
mk_both "$R4" "concept-boundary-live.md" "The cogni-consult plugin ships."
mk_both "$R4" "concept-boundary-retired.md" "The cogni-consulting plugin does not."
run_scan_repo "$R4"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-boundary-retired.md: cogni-consulting" \
   && assert_out_lacks "concept-boundary-live.md"; then
  pass "B4 a retired name extending a live roster name is flagged while the live name is not"
else
  fail "B4 a retired name extending a live roster name is flagged while the live name is not"
fi

# ---------------------------------------------------------------------------
# B5 — the out-of-marketplace allowance is live config, not a silent hatch: the
# allowed names pass while a retired name on the SAME page is still flagged.
# ---------------------------------------------------------------------------
R5="$TMPROOT/b5"; mk_fixture_repo "$R5"
mk_both "$R5" "concept-extras.md" "Pair cogni-docs and cogni-service with the cogni-tips plugin."
run_scan_repo "$R5"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-extras.md: cogni-tips" \
   && assert_out_lacks ": cogni-docs" \
   && assert_out_lacks ": cogni-service"; then
  pass "B5 out-of-marketplace plugins are allowed while a retired name beside them is flagged"
else
  fail "B5 out-of-marketplace plugins are allowed while a retired name beside them is flagged"
fi

# ---------------------------------------------------------------------------
# B6 — the org token is allowed ONLY as the exact token plus a slash. A bare
# occurrence and a longer off-roster name sharing its prefix are both flagged;
# the live roster name sharing that prefix passes on the roster arm.
# ---------------------------------------------------------------------------
R6="$TMPROOT/b6"; mk_fixture_repo "$R6"
mk_both "$R6" "concept-org.md" \
  "Add cogni-work/insight-wave. The cogni-work org. Try cogni-workbench/ too. The cogni-workspace plugin is live."
run_scan_repo "$R6"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-org.md: cogni-workbench" \
   && assert_out_lacks ": cogni-workspace"; then
  pass "B6 the org token is allowed only with its slash, and a prefix look-alike is still flagged"
else
  fail "B6 the org token is allowed only with its slash, and a prefix look-alike is still flagged"
fi

# ---------------------------------------------------------------------------
# B7 — the store path is allowed ONLY as the exact token plus a slash. The
# dispatch (colon) form is flagged, and a slash path naming a genuinely retired
# plugin is flagged too — so the rule is not "any name followed by a slash".
# ---------------------------------------------------------------------------
R7="$TMPROOT/b7"; mk_fixture_repo "$R7"
mk_both "$R7" "concept-store.md" \
  "Records land in cogni-claims/claims.json. Never dispatch cogni-claims: here, nor read cogni-research/notes.md."
run_scan_repo "$R7"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-store.md: cogni-research" \
   && assert_out_has "OFF-ROSTER [root] concept-store.md: cogni-claims"; then
  pass "B7 the store path is allowed only with its slash while the dispatch form and a retired path are flagged"
else
  fail "B7 the store path is allowed only with its slash while the dispatch form and a retired path are flagged"
fi

# ---------------------------------------------------------------------------
# B8 — qualified page slugs built from a live roster name are not greedily
# mis-read as off-roster names, while the same shape on a retired name is.
# ---------------------------------------------------------------------------
R8="$TMPROOT/b8"; mk_fixture_repo "$R8"
mk_both "$R8" "concept-slugs.md" \
  "See [[skill-cogni-consult-scope]] and [[agent-cogni-workspace-helper]], not cogni-consulting-scope."
run_scan_repo "$R8"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-slugs.md: cogni-consulting-scope" \
   && assert_out_lacks ": cogni-consult-scope" \
   && assert_out_lacks ": cogni-workspace-helper"; then
  pass "B8 qualified slugs on a live roster name pass while the same shape on a retired name is flagged"
else
  fail "B8 qualified slugs on a live roster name pass while the same shape on a retired name is flagged"
fi

# ---------------------------------------------------------------------------
# B9 / B10 / B11 — the liveness floors. Each degenerate input gets its OWN case,
# so a mutation that kills one floor names that floor rather than reporting the
# same red as a mutation that killed all three.
# ---------------------------------------------------------------------------
R9="$TMPROOT/b9"; mk_fixture_repo "$R9"
ROSTER9="$(roster_from "$R9/.claude-plugin/marketplace.json")"
SHARED9="$(shared_basenames "$R9/wiki/wiki/pages" "$R9/cogni-workspace/wiki/wiki/pages")"

run_scan_tree "$R9/wiki/wiki/pages-does-not-exist" "missing" "$ROSTER9" "$SHARED9"
if assert_rc 1 && assert_out_has "ERROR [missing] pages directory not found"; then
  pass "B9 an arm pointed at a missing directory fails with a named error"
else
  fail "B9 an arm pointed at a missing directory fails with a named error"
fi

mkdir -p "$TMPROOT/b9-empty"
run_scan_tree "$TMPROOT/b9-empty" "empty" "$ROSTER9" "$SHARED9"
if assert_rc 1 && assert_out_has "ERROR [empty] no shared .md pages found"; then
  pass "B10 an arm that finds no shared pages fails with a named error"
else
  fail "B10 an arm that finds no shared pages fails with a named error"
fi

R9B="$TMPROOT/b9b"; mk_fixture_repo "$R9B"
mk_marketplace "$R9B/.claude-plugin/marketplace.json"
ROSTER9B="$(roster_from "$R9B/.claude-plugin/marketplace.json")"
run_scan_tree "$R9B/wiki/wiki/pages" "noroster" "$ROSTER9B" "$SHARED9"
if assert_rc 1 && assert_out_has "ERROR [noroster] roster is empty"; then
  pass "B11 an arm handed an empty roster fails with a named error"
else
  fail "B11 an arm handed an empty roster fails with a named error"
fi

# ---------------------------------------------------------------------------
# B12 — the surface really is the intersection: a page present in only ONE tree
# is not scanned, even carrying a retired name. This is what lets the suite
# carry no exclusion list at all.
# ---------------------------------------------------------------------------
R10="$TMPROOT/b10"; mk_fixture_repo "$R10"
mk_body "$R10/wiki/wiki/pages/lint-one-sided.md" "Names the cogni-research plugin."
run_scan_repo "$R10"
if assert_rc 0 && assert_out_lacks "cogni-research"; then
  pass "B12 a page present in only one tree is outside the scanned surface"
else
  fail "B12 a page present in only one tree is outside the scanned surface"
fi

# ---------------------------------------------------------------------------
# B13 — roster-source isolation: the manifest's own top-level name and its owner
# name are not plugin names and must never leak into the allowed set.
# ---------------------------------------------------------------------------
R11="$TMPROOT/b11"; mk_fixture_repo "$R11"
mk_both "$R11" "concept-manifest.md" "The cogni-workspace plugin is live."
ROSTER11="$(roster_from "$R11/.claude-plugin/marketplace.json")"
if case "$ROSTER11" in *"fixture-marketplace"*|*"Fixture Owner"*) false ;; *) true ;; esac; then
  pass "B13 the roster is built from plugin names only, never the manifest or owner name"
else
  fail "B13 the roster is built from plugin names only, never the manifest or owner name"
fi

# ---------------------------------------------------------------------------
# B14 — frontmatter is part of the scanned surface, in both directions. The org
# URL sits in a `sources:` list and a footer Source link — the placement its
# allowance is actually justified by — and stays green; a retired name in a
# `related:` entry is still flagged. Without this case a regression to scanning
# only the prose below the frontmatter would leave every other case green, and
# the coverage loss would be silent.
# ---------------------------------------------------------------------------
R14="$TMPROOT/b14"; mk_fixture_repo "$R14"
mk_sourced_both "$R14" "concept-frontmatter.md" "cogni-research"
run_scan_repo "$R14"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-frontmatter.md: cogni-research" \
   && assert_out_lacks "concept-frontmatter.md: cogni-work"; then
  pass "B14 frontmatter is scanned — a retired name there is flagged while the org URL is not"
else
  fail "B14 frontmatter is scanned — a retired name there is flagged while the org URL is not"
fi

# ---------------------------------------------------------------------------
# B15 — the tokenizer is greedy, so a retired name is never reported from inside
# an unrelated longer word that merely starts with it. The complement of B4:
# there a retired name EXTENDED a live one, here an off-roster word extends a
# retired one and must be named in full, not truncated to the retired prefix.
# ---------------------------------------------------------------------------
R15="$TMPROOT/b15"; mk_fixture_repo "$R15"
mk_both "$R15" "concept-greedy.md" "A cogni-researcher wrote this."
run_scan_repo "$R15"
# The has-half is the whole assertion: a tokenizer that truncated to the retired
# prefix would emit "cogni-research" INSTEAD of the full word, so this needle
# fails. A paired assert_out_lacks on the prefix could not discriminate, since
# the prefix is a substring of the correct output.
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-greedy.md: cogni-researcher"; then
  pass "B15 a longer off-roster word is named in full, never truncated to a retired prefix"
else
  fail "B15 a longer off-roster word is named in full, never truncated to a retired prefix"
fi

# ---------------------------------------------------------------------------
# B16 — an offender in the ROOT tree's index.md is named, with the root-toplevel
# label. B16 and B17 together are what make each tree-level arm independently
# deletable-and-red, the same property B2/B3 give the intersection arms.
# ---------------------------------------------------------------------------
R16="$TMPROOT/b16"; mk_fixture_repo "$R16"
mk_body "$R16/wiki/wiki/index.md" "Catalogue entry for the cogni-research plugin."
run_scan_repo "$R16"
if assert_rc 1 && assert_out_has "OFF-ROSTER [root-toplevel] index.md: cogni-research"; then
  pass "B16 a bare retired name in the root tree index.md is flagged with the root-toplevel label"
else
  fail "B16 a bare retired name in the root tree index.md is flagged with the root-toplevel label"
fi

# ---------------------------------------------------------------------------
# B17 — the WORKSPACE arm, exercised through the other basename so neither arm
# nor either name can be satisfied by the other's coverage.
# ---------------------------------------------------------------------------
R17="$TMPROOT/b17"; mk_fixture_repo "$R17"
mk_body "$R17/cogni-workspace/wiki/wiki/overview.md" "Overview naming the cogni-wiki plugin."
run_scan_repo "$R17"
if assert_rc 1 && assert_out_has "OFF-ROSTER [workspace-toplevel] overview.md: cogni-wiki"; then
  pass "B17 a bare retired name in the workspace tree overview.md is flagged with the workspace-toplevel label"
else
  fail "B17 a bare retired name in the workspace tree overview.md is flagged with the workspace-toplevel label"
fi

# ---------------------------------------------------------------------------
# B18 — divergence tolerance. The two index.md copies differ by design, so the
# arm must scan each on its own terms: different clean bodies stay green, and an
# offender planted in ONE copy reds only that copy's arm. An intersection-shaped
# arm would skip the pair entirely and report clean.
# ---------------------------------------------------------------------------
R18="$TMPROOT/b18"; mk_fixture_repo "$R18"
mk_body "$R18/wiki/wiki/index.md" "Root catalogue keeping its own maintenance section. See cogni-workspace."
mk_body "$R18/cogni-workspace/wiki/wiki/index.md" "Bundled catalogue keeping different bullets. See cogni-consult."
run_scan_repo "$R18"
b18_divergent_clean=0
assert_rc 0 && b18_divergent_clean=1
mk_body "$R18/wiki/wiki/index.md" "Root catalogue naming the cogni-narrative plugin."
run_scan_repo "$R18"
if [ "$b18_divergent_clean" -eq 1 ] && assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root-toplevel] index.md: cogni-narrative" \
   && assert_out_lacks "[workspace-toplevel]"; then
  pass "B18 by-design divergence between the two index.md copies is scanned, not skipped"
else
  fail "B18 by-design divergence between the two index.md copies is scanned, not skipped"
fi

# ---------------------------------------------------------------------------
# B19 — log.md stays outside the surface. Its retired names are frozen dated
# history, so reaching it would red the suite on arrival and force the exclusion
# list this suite carries none of.
# ---------------------------------------------------------------------------
R19="$TMPROOT/b19"; mk_fixture_repo "$R19"
mk_body "$R19/wiki/wiki/log.md" "Dated ingest line naming the cogni-research plugin."
mk_body "$R19/cogni-workspace/wiki/wiki/log.md" "Dated ingest line naming the cogni-research plugin."
run_scan_repo "$R19"
if assert_rc 0 && assert_out_lacks "cogni-research"; then
  pass "B19 log.md is outside the tree-level surface and its frozen retired names are not flagged"
else
  fail "B19 log.md is outside the tree-level surface and its frozen retired names are not flagged"
fi

# ---------------------------------------------------------------------------
# B20 — tree-level liveness floor. An arm that resolves none of its named pages
# must fail loudly; a silent clean scan of nothing is the half-dead guard.
# ---------------------------------------------------------------------------
mkdir -p "$TMPROOT/b20-empty"
run_scan_tree_level "$TMPROOT/b20-empty" "toplevel-missing" "$ROSTER9"
if assert_rc 1 && assert_out_has "ERROR [toplevel-missing] no tree-level pages found"; then
  pass "B20 a tree-level arm that resolves no named page fails with a named error"
else
  fail "B20 a tree-level arm that resolves no named page fails with a named error"
fi

# ---------------------------------------------------------------------------
# B21 — the tree-level arm carries the roster floor too, so an empty manifest
# cannot quietly bless every token on this surface either.
# ---------------------------------------------------------------------------
run_scan_tree_level "$R9B/wiki/wiki" "toplevel-noroster" "$ROSTER9B"
if assert_rc 1 && assert_out_has "ERROR [toplevel-noroster] roster is empty"; then
  pass "B21 a tree-level arm handed an empty roster fails with a named error"
else
  fail "B21 a tree-level arm handed an empty roster fails with a named error"
fi

# ---------------------------------------------------------------------------
# B22 — the REAL trees are clean on this surface (asserted here, not only in
# fixtures), which is what pins today's swept state against regression.
# ---------------------------------------------------------------------------
ROSTER22="$(roster_from "$REPO_ROOT/.claude-plugin/marketplace.json")"
run_scan_tree_level "$REPO_ROOT/wiki/wiki" "root-toplevel" "$ROSTER22"
b22_root_ok=0
assert_rc 0 && b22_root_ok=1
run_scan_tree_level "$REPO_ROOT/cogni-workspace/wiki/wiki" "workspace-toplevel" "$ROSTER22"
if [ "$b22_root_ok" -eq 1 ] && assert_rc 0; then
  pass "B22 the real tree-level pages in both trees carry no off-roster plugin names"
else
  fail "B22 the real tree-level pages in both trees carry no off-roster plugin names"
fi

# ---------------------------------------------------------------------------
# B23 — the store path's GREEN half, on a fixture of its own. B7 covers only the
# red half: scan_file strips the delimiter before emitting, so the path form and
# the dispatch form of the same token produce byte-identical offender lines, and
# B7's needle is satisfied by the dispatch form alone even when the path form
# also offends. This is the case the header's slash-allowance recipe drives.
# ---------------------------------------------------------------------------
R23="$TMPROOT/b23"; mk_fixture_repo "$R23"
mk_both "$R23" "concept-store-path.md" \
  "Records land in cogni-claims/claims.json under the workspace root."
run_scan_repo "$R23"
if assert_rc 0 \
   && assert_out_lacks "concept-store-path.md: cogni-claims"; then
  pass "B23 the store path form alone is allowed and emits no offender line"
else
  fail "B23 the store path form alone is allowed and emits no offender line"
fi

# B24 — historical-framing allowance, GREEN half. The frozen sentence sits
# inside a longer paragraph, which is why the gate is containment: an equality
# test against the line would never fire on the real page either.
R24="$TMPROOT/b24"; mk_fixture_repo "$R24"
mk_both "$R24" "workflow-consulting-engagement.md" \
  "A structured consulting engagement whose research compounds. $HISTORICAL_SENTENCE"
run_scan_repo "$R24"
if assert_rc 0 \
   && assert_out_lacks "workflow-consulting-engagement.md: cogni-consulting"; then
  pass "B24 the frozen historical framing is allowed and emits no offender line"
else
  fail "B24 the frozen historical framing is allowed and emits no offender line"
fi

# B25 — historical-framing allowance, RED half, and the mutation-recipe target.
# The SAME token in a live present-tense framing must still flag, or the
# allowance is a hatch that blesses the name everywhere.
R25="$TMPROOT/b25"; mk_fixture_repo "$R25"
mk_both "$R25" "concept-live-framing.md" \
  "Run the cogni-consulting plugin to scope the engagement."
run_scan_repo "$R25"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-live-framing.md: cogni-consulting"; then
  pass "B25 the same retired name in a live framing is still flagged"
else
  fail "B25 the same retired name in a live framing is still flagged"
fi

# B26 — skill-name allowance, GREEN half. Both the qualified and the bare form
# must pass: the matcher cannot span a colon, so the qualified form arrives as a
# bare second token and writing it qualified rescues nothing on its own.
R26="$TMPROOT/b26"; mk_fixture_repo "$R26"
mk_skill_dir "$R26" "cogni-workspace" "cogni-issues"
mk_both "$R26" "workflow-onboarding.md" \
  "Use cogni-workspace:cogni-issues to file problems, or the cogni-issues skill directly."
run_scan_repo "$R26"
if assert_rc 0 \
   && assert_out_lacks "workflow-onboarding.md: cogni-issues"; then
  pass "B26 a skill name of a live roster plugin is allowed in both forms"
else
  fail "B26 a skill name of a live roster plugin is allowed in both forms"
fi

# B27 — skill-name allowance, RED half, two arms. Arm 1: a name with no skill
# directory still flags, so the allowance is derived rather than blanket. Arm 2:
# a skill directory under a plugin ABSENT from the roster blesses nothing, which
# is what stops a retired plugin's leftover skill tree from exempting itself.
R27="$TMPROOT/b27"; mk_fixture_repo "$R27"
mk_skill_dir "$R27" "cogni-retired" "cogni-ghost"
mk_both "$R27" "concept-unknown-skill.md" \
  "See cogni-nonesuch and cogni-ghost for details."
run_scan_repo "$R27"
if assert_rc 1 \
   && assert_out_has "OFF-ROSTER [root] concept-unknown-skill.md: cogni-nonesuch" \
   && assert_out_has "OFF-ROSTER [root] concept-unknown-skill.md: cogni-ghost"; then
  pass "B27 an unknown name flags and an off-roster plugin skill blesses nothing"
else
  fail "B27 an unknown name flags and an off-roster plugin skill blesses nothing"
fi

# B28 — promotion probe. The bundled-only pages are outside the intersection by
# construction, so B1 cannot see them however clean it reports. This scans them
# against the LIVE roster as if promotion had already happened, which pulls a
# residue forward to today instead of surfacing it the moment promotion lands.
#
# The page set is DERIVED, never listed: tree_only_basenames is the exact
# complement of the shared_basenames the intersection arm uses, so a bundled-only
# page added tomorrow is probed without anyone remembering to edit this case —
# and a page that is promoted or renamed leaves the set on its own. A literal
# list would have gone stale silently in both directions, because the arm's
# `total -eq 0` floor only fires when EVERY named page vanishes, not when one
# does.
#
# Since #1402 promoted all seven, EVERY page has left the set.
ROSTER28="$ROSTER22"
BUNDLED28="$(tree_only_basenames "$REPO_ROOT/wiki/wiki/pages" \
  "$REPO_ROOT/cogni-workspace/wiki/wiki/pages")"
# The derived set is empty once every bundled-only page has been promoted (#1402
# promoted all seven). scan_tree's `total -eq 0` floor would read that as a
# half-dead scan and return 1, so the empty case is answered HERE rather than by
# weakening a floor B1 and B10 depend on. The emptiness test is the same
# `*[![:space:]]*` predicate scan_tree and scan_tree_level use, so this branch
# covers exactly the case the floor would have refused, by construction rather
# than by argument.
#
# An empty set alone is NOT sufficient to pass: it reads the same whether every
# page was promoted or the derivation broke, which is the silent narrowing the
# derived set exists to prevent. So the empty arm proves the derivation is still
# live by requiring a non-empty intersection before it passes.
case "$BUNDLED28" in
  *[![:space:]]*)
    run_scan_tree "$REPO_ROOT/cogni-workspace/wiki/wiki/pages" "held-promotion-probe" \
      "$ROSTER28" "$BUNDLED28" "$(skill_names_from "$REPO_ROOT" "$ROSTER28")"
    if assert_rc 0; then
      pass "B28 the held bundled-only pages are clean against the live roster"
    else
      fail "B28 the held bundled-only pages are clean against the live roster"
    fi ;;
  *)
    SHARED28="$(shared_basenames "$REPO_ROOT/wiki/wiki/pages" \
      "$REPO_ROOT/cogni-workspace/wiki/wiki/pages")"
    case "$SHARED28" in
      *[![:space:]]*)
        pass "B28 no bundled-only residue remains to probe (every page is in both trees)" ;;
      *)
        fail "B28 both the bundled-only set and the intersection are empty — the derivation is dead, not satisfied" ;;
    esac ;;
esac

# ---------------------------------------------------------------------------
if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures wiki-bare-name-roster test(s) failed."
  exit 1
fi
echo ""
echo "All wiki-bare-name-roster tests passed."
