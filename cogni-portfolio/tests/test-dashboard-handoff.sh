#!/usr/bin/env bash
# Acceptance suite for the dashboard-refresher handoff contract.
#
# The `dashboard-refresher` agent is the plugin's only non-interactive path to a
# regenerated dashboard, and every end-of-step caller depends on two guarantees:
# a dashboard always gets produced, and nothing opens a browser window unasked.
# Both guarantees live in prose, in a single shared contract file — so nothing
# fails when they drift. These tests are what fails.
#
# The third case is the load-bearing one. `open_browser` defaults to false, and
# eleven in-plugin call sites promise the user "(a) open the dashboard" before
# dispatching the agent. Each of them has to name the opt-in explicitly, because
# the default alone no longer opens anything. The scan is intent-scoped, not
# blanket: a caller that only wants the returned url is correct with no flag.
#
# Named acceptance tests:
#   test_refresher_has_no_skip_path  the agent never terminates without generating
#   test_open_browser_optin          default is non-opening, and every intending call site says so
#   test_refresher_returns_url       a successful result carries a clickable url
#   test_entity_skills_cite_handoff  all eight entity skills end by citing the canonical handoff
#   test_pipeline_skills_cite_handoff
#                                    the six pipeline and ops skills each cite it exactly once
#   test_secondary_paths_reach_handoff
#                                    rostered alternate write paths keep their pointer back to
#                                    that terminal section (per-skill floors, not a census)
#   test_handoff_not_duplicated      the handoff is authored once, and no skill restates it
#   test_entity_handoff_does_not_open
#                                    the end-of-step path opens nothing on its own
#   test_midflow_offers_survive      the pre-existing review offers still open on request
#   test_resume_shows_dashboard_row  portfolio-resume surfaces a flag-driven dashboard row
#   test_handoff_does_not_open       the resume generation offer dispatches without opening a browser
#   test_dispatch_sites_grant_agent  every skill dispatching by name or citation grants Agent
#
# Usage: bash cogni-portfolio/tests/test-dashboard-handoff.sh [test_name ...]
#   No args -> run every test (the CI path). One or more names -> run only those
#   (used by the mutation harness to run a single assertion against a mutant).
#   An unknown name exits 2 rather than reporting green, so a stale mutation
#   recipe cannot pass while running zero assertions.
# Exits non-zero on any assertion failure.
#
# Scope note: the scan covers this plugin only, and deliberately excludes the
#   agent contract itself from the call-site surface — it is the file that
#   *documents* open_browser, not a caller of it, so including it would flag the
#   definition as an offender.
#
# Mutation recipe — the SHARED cogni-service harness, which classifies on the output
#   labels below. Replayable as written, from the repo root. The mutant must be a
#   documentation file, not a script: this suite asserts on documentation content, so
#   mutating a scripts/ file would leave every case green and prove nothing.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/agents/dashboard-refresher.md \
#     --expr 's#run the generator with no theme flag#return this JSON and stop#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_refresher_has_no_skip_path' \
#     --case test_refresher_has_no_skip_path
#   The expr reverts the no-theme branch to the terminal wording the fix removed, so
#   the case goes red on the mutant and green on HEAD. Pick a metacharacter-free
#   target: the harness feeds the expr to `perl -0pi`, where a dot would be a
#   wildcard rather than a literal.
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.
#   The in-repo equivalent is registered as mutation_dashboard_no_skip_path in
#   cogni-portfolio/scripts/mutation-check.sh.
#
# Mutation recipe — test_entity_skills_cite_handoff. Same harness, same shape.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/markets/SKILL.md \
#     --expr 's#references/dashboard-handoff#references/absent-handoff#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_entity_skills_cite_handoff' \
#     --case test_entity_skills_cite_handoff
#   The expr repoints one wired skill's citation, so the case goes red on the mutant
#   and green on HEAD. markets/ carries the citation exactly once and takes no pointer
#   line, so the single-occurrence anchor is unambiguous. The replacement is
#   deliberately DISJOINT from the searched string — a replacement such as
#   "references/dashboard-handoff-removed" still CONTAINS the searched literal as a
#   prefix, so the assertion would stay green and the mutation would survive.
#   The in-repo equivalent is registered as mutation_handoff_citation.
#
# Mutation recipe — test_pipeline_skills_cite_handoff. Same harness, same shape.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/portfolio-verify/SKILL.md \
#     --expr 's#references/dashboard-handoff#references/absent-handoff#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_pipeline_skills_cite_handoff' \
#     --case test_pipeline_skills_cite_handoff
#   The expr repoints one wired pipeline skill's citation, so the case goes red on the
#   mutant and green on HEAD. portfolio-verify carries the citation exactly once and
#   takes no pointer line, so the single-occurrence anchor is unambiguous. As above the
#   replacement is deliberately DISJOINT from the searched string — a replacement such
#   as "references/dashboard-handoff-removed" still CONTAINS the searched literal as a
#   prefix, so the assertion would stay green and the mutation would survive.
#   The in-repo equivalent is registered as mutation_pipeline_handoff_citation.
#
# Mutation recipe — test_dispatch_sites_grant_agent. Same SHARED harness, same
#   classify-on-labels contract, replayable as written from the repo root.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/products/SKILL.md \
#     --expr 's#Grep, Bash, Agent#Grep, Bash#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_dispatch_sites_grant_agent' \
#     --case test_dispatch_sites_grant_agent
#   The expr strips the Agent token from a skill that carries a dispatch line, so
#   the case goes red on the mutant and green on HEAD. `Grep, Bash, Agent` occurs
#   exactly once in that file and is metacharacter-free. The replacement is
#   deliberately DISJOINT from the searched string — one that still contained
#   `Agent` would leave the grant intact, the case green, and the mutation would
#   survive unnoticed. A documentation file again, for the reason above.
#   The in-repo equivalent is registered as mutation_dispatch_agent_grant in
#   cogni-portfolio/scripts/mutation-check.sh.
#
# Mutation recipe — test_dispatch_sites_grant_agent (citation-only arm). Same
#   SHARED harness, same classify-on-labels contract, replayable as written from
#   the repo root.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/portfolio-ingest/SKILL.md \
#     --expr 's#Grep, Bash, Agent, Skill#Grep, Bash, Skill#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_dispatch_sites_grant_agent' \
#     --case test_dispatch_sites_grant_agent
#   The recipe above covers the OTHER arm of the same case. Its sibling recipe
#   mutates products/SKILL.md, which names the agent outright; portfolio-ingest
#   names it nowhere — neither its SKILL.md nor any of its references/*.md carries
#   the literal — so it enters the surface only through the canonical citation.
#   Before this case derived both forms, the mutant here survived: the skill was
#   invisible to the scan, so stripping its grant changed nothing.
#   `Grep, Bash, Agent, Skill` occurs exactly once in that file and is
#   metacharacter-free, which matters because the harness feeds the expr to
#   perl -0pi. The replacement is deliberately DISJOINT from the searched string
#   and retains no whole Agent token — one that still granted Agent would leave
#   the case green and the mutation would survive unnoticed. portfolio-verify
#   carries a byte-identical allowed-tools tail, which is harmless because --file
#   scopes the harness to one file.
#   The in-repo equivalent is registered as mutation_citation_only_agent_grant in
#   cogni-portfolio/scripts/mutation-check.sh.
#
# Mutation recipe — test_secondary_paths_reach_handoff. Same SHARED harness, same
#   classify-on-labels contract, replayable as written from the repo root.
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-portfolio/skills/solutions/SKILL.md \
#     --expr 's#deal size data for the relevant segment.\n\nThis path ends the same way#deal size data for the relevant segment.\n\nRepricing is complete#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_secondary_paths_reach_handoff' \
#     --case test_secondary_paths_reach_handoff
#   The anchor spans the repricing section's closing paragraph into the pointer that
#   follows it, so it strips the REPRICING pointer specifically rather than whichever
#   of the three comes first — solutions drops to 2 against want=3, and the case goes
#   red on the mutant, green on HEAD (verdict guard_verified). The multi-line anchor
#   works because the harness feeds the expr to `perl -0pi`, which slurps the file.
#   The replacement is deliberately DISJOINT from the searched string: one that still
#   contained the pointer sentence would hold the count at 3 and the mutation would
#   survive. No in-repo equivalent is registered — the floor assertion is itself the
#   gate, and it is what this recipe proves has teeth: a REMOVED pointer still drops the
#   count below want, which is the failure the case exists to catch. The floor only
#   stops rejecting the opposite change, extending coverage to a path the rule covers.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the failure counter below, which exists so one run reports every offender.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
AGENT="$PLUGIN_DIR/agents/dashboard-refresher.md"
HANDOFF_REF="$PLUGIN_DIR/references/dashboard-handoff.md"
# The full literal INCLUDING the .md, matched fixed-string. Both are load-bearing:
# they are what makes a mutant's rewritten path fail to match.
HANDOFF_PATH_LITERAL='references/dashboard-handoff.md'
HANDOFF_HEADING='## Dashboard handoff'
ENTITY_SKILLS='products features markets propositions solutions compete customers packages'
# The pipeline and ops skills. A roster and not a derived set on purpose:
# skills_with_handoff_section() answers "does this section restate or open", but the
# positive claim — every skill that SHOULD cite one DOES — cannot be computed from the
# sections themselves, because a skill that forgot its section has nothing to find.
PIPELINE_SKILLS='portfolio-ingest portfolio-scan portfolio-verify portfolio-communicate portfolio-consolidate portfolio-taxonomy'
PTR_LINE='This path ends the same way — see the **Dashboard handoff** section in this file.'

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one "<case>: <msg>" string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

# The agent contract is the scan surface for two of the three cases. A missing or
# empty file would make every literal assertion below vacuously "not found", which
# reads as a real failure rather than a broken surface — so say which it is.
agent_surface_ok() {
  local case_name="$1"
  if [ ! -s "$AGENT" ]; then
    fail "$case_name" "agents/dashboard-refresher.md is missing or empty; scan surface is broken"
    return 1
  fi
  return 0
}

# The canonical reference is the scan surface for the handoff cases, and gets the
# same treatment as the agent contract above: say "broken surface", not "absent".
reference_surface_ok() {
  local case_name="$1"
  if [ ! -s "$HANDOFF_REF" ]; then
    fail "$case_name" "references/dashboard-handoff.md is missing or empty; scan surface is broken"
    return 1
  fi
  return 0
}

# Print one skill's handoff section: from its heading to the next H2. Anchored on
# ^## so a bolded in-prose "**Dashboard handoff**" inside a pointer line can never
# open or extend a section.
handoff_section() {
  awk -v h="$HANDOFF_HEADING" '$0 == h {f=1; next} f && /^## / {f=0} f' "$1"
}

# Every rostered entity skill must be present before any of them can be judged. A
# scan that reads nothing would report "no offenders" and go green having proved
# nothing — the discipline of test_no_file_cites_notes in test-data-model-pointer.sh.
# The expected count is derived from ENTITY_SKILLS rather than written out, so
# extending the roster stays a one-line edit instead of a false surface failure.
entity_surface_ok() {
  local case_name="$1" missing="" skill
  for skill in $ENTITY_SKILLS; do
    [ -s "$PLUGIN_DIR/skills/$skill/SKILL.md" ] || missing="$missing $skill"
  done
  if [ -n "$missing" ]; then
    fail "$case_name" "missing entity SKILL.md:$missing; scan surface is broken"
    return 1
  fi
  return 0
}

# The pipeline/ops counterpart. Separate from entity_surface_ok because the two
# rosters are different populations, and a case that scans a missing file would
# report "no offenders" while proving nothing.
pipeline_surface_ok() {
  local case_name="$1" missing="" skill
  for skill in $PIPELINE_SKILLS; do
    [ -s "$PLUGIN_DIR/skills/$skill/SKILL.md" ] || missing="$missing $skill"
  done
  if [ -n "$missing" ]; then
    fail "$case_name" "missing pipeline SKILL.md:$missing; scan surface is broken"
    return 1
  fi
  return 0
}

# Every skill that carries a handoff section, rostered or not. The negative cases
# below use this rather than ENTITY_SKILLS: the drift this reference exists to
# prevent is the dispatch reappearing as an inlined paragraph, and it would do that
# in whichever skill grows one next — including a skill nobody thought to roster.
skills_with_handoff_section() {
  local f
  for f in "$PLUGIN_DIR"/skills/*/SKILL.md; do
    [ -s "$f" ] || continue
    [ -n "$(handoff_section "$f")" ] && printf '%s\n' "$f"
  done
}

# --- test_refresher_has_no_skip_path ---------------------------------------
# The agent must never document a path that ends without a generated file. The
# generator applies its built-in default theme when given no theme flag, so the
# "no theme found" state is a generate-anyway branch, not a terminal one.
test_refresher_has_no_skip_path() {
  agent_surface_ok test_refresher_has_no_skip_path || return

  local missing=""

  if grep -qF 'run the generator with no theme flag' "$AGENT"; then :; else
    missing="$missing no-theme-branch-generates"
  fi
  if grep -qF 'DEFAULT_THEME' "$AGENT"; then :; else
    missing="$missing cites-DEFAULT_THEME"
  fi

  # The terminal skipped status must be gone entirely, not merely reworded around.
  if grep -qF '"status": "skipped"' "$AGENT"; then
    missing="$missing terminal-skipped-status-still-present"
  fi

  # Step 2 must actually SHOW the flagless invocation, or the branch names a
  # command shape the agent was never given.
  if grep -F 'generate-dashboard.py "<project_dir>"' "$AGENT" \
     | grep -vF -- '--theme' | grep -qvF -- '--design-variables'; then :; else
    missing="$missing no-flag-invocation-form"
  fi

  # The error branch is not part of this change and must survive it: a diff that
  # folds it into the new unconditional-generation flow would let a failed
  # generator return a success payload.
  if grep -qF '"status": "error"' "$AGENT"; then :; else
    missing="$missing error-branch-removed"
  fi
  if grep -qF 'Do not retry.' "$AGENT"; then :; else
    missing="$missing do-not-retry-removed"
  fi

  if [ -n "$missing" ]; then
    fail test_refresher_has_no_skip_path "agent contract problems:$missing"
  else
    pass test_refresher_has_no_skip_path "generates unconditionally; error branch intact"
  fi
}

# --- test_open_browser_optin -----------------------------------------------
# Two halves: the documented default is the non-opening one, and every call site
# whose prose promises to open names the opt-in explicitly.
#
# Both halves emit a green line on a clean run, so the addressable id names the
# HALF rather than the case — a single `test_open_browser_optin` token would name
# two lines and a mutation of either half could be credited by the other. The
# function name itself is unchanged: ALL_TESTS/run_one and scripts/mutation-check.sh
# dispatch on it.
test_open_browser_optin() {
  agent_surface_ok test_open_browser_optin-surface || return

  # Half 1 — the input contract.
  local contract_line
  contract_line="$(grep -F '`open_browser` (optional' "$AGENT" | head -1)"
  if [ -z "$contract_line" ]; then
    fail test_open_browser_optin-contract-default-false "no open_browser input-contract line in agents/dashboard-refresher.md"
  else
    case "$contract_line" in
      *"default: false"*) pass test_open_browser_optin-contract-default-false "input contract documents the non-opening default" ;;
      *) fail test_open_browser_optin-contract-default-false "input-contract line does not document 'default: false': $contract_line" ;;
    esac
  fi
  if grep -qF 'default: true' "$AGENT"; then
    fail test_open_browser_optin-no-default-true "agent contract still documents 'default: true' somewhere"
  else
    pass test_open_browser_optin-no-default-true "agent contract documents no 'default: true'"
  fi

  # Half 2 — the call-site surface. Three globs: agents/, skills/*/SKILL.md and
  # skills/*/references/*.md. The last one is not optional — two of the eleven
  # dispatch sites live only there, so a SKILL.md-bounded scan finds nine.
  local surface scanned
  surface="$(
    find "$PLUGIN_DIR/agents" -name '*.md' -type f 2>/dev/null
    find "$PLUGIN_DIR/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f 2>/dev/null
    find "$PLUGIN_DIR/skills" -mindepth 3 -maxdepth 3 -path '*/references/*.md' -type f 2>/dev/null
  )"
  scanned="$(printf '%s\n' "$surface" | grep -c . )"
  if [ "$scanned" -eq 0 ]; then
    fail test_open_browser_optin-scan-surface "scanned no files; scan surface is broken"
    return
  else
    pass test_open_browser_optin-scan-surface "scanned $scanned files"
  fi

  # A dispatch line mentions the agent by name. The agent's own contract file is
  # the definition, not a caller — exclude it.
  local dispatch_lines dispatch_count offenders=""
  dispatch_lines="$(
    printf '%s\n' "$surface" | while IFS= read -r f; do
      [ -n "$f" ] || continue
      [ "$f" = "$AGENT" ] && continue
      grep -nF 'dashboard-refresher' "$f" 2>/dev/null | while IFS= read -r hit; do
        printf '%s:%s\n' "$f" "$hit"
      done
    done
  )"
  dispatch_count="$(printf '%s\n' "$dispatch_lines" | grep -c . )"
  if [ "$dispatch_count" -eq 0 ]; then
    fail test_open_browser_optin-dispatch-surface "found no dashboard-refresher dispatch lines; scan surface is broken"
    return
  else
    pass test_open_browser_optin-dispatch-surface "found $dispatch_count dashboard-refresher dispatch lines"
  fi

  # Intent-scoped: require the flag only where the surrounding prose promises to
  # open. The window is the dispatch line plus the 8 lines above it — the widest
  # real offer-to-dispatch gap in the plugin is 6. A future end-of-step caller
  # that only wants the returned url is correct with no flag and stays green.
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    local file lineno text window from
    file="${entry%%:*}"
    text="${entry#*:}"
    lineno="${text%%:*}"
    text="${text#*:}"
    from=$(( lineno - 8 )); [ "$from" -lt 1 ] && from=1
    window="$(sed -n "${from},${lineno}p" "$file")"
    case "$(printf '%s' "$window" | tr '[:upper:]' '[:lower:]')" in
      *"open the dashboard"*)
        case "$text" in
          *open_browser*) : ;;
          *) offenders="$offenders ${file#"$PLUGIN_DIR/"}:$lineno" ;;
        esac
        ;;
    esac
  done <<EOF
$dispatch_lines
EOF

  if [ -n "$offenders" ]; then
    fail test_open_browser_optin-callsite-optin "call sites promise to open but pass no flag:$offenders"
  else
    pass test_open_browser_optin-callsite-optin "all intending call sites name the opt-in ($dispatch_count dispatch lines scanned)"
  fi
}

# --- test_refresher_returns_url --------------------------------------------
# Callers should cite a link, not each rebuild file:// + path themselves.
test_refresher_returns_url() {
  agent_surface_ok test_refresher_returns_url || return

  local missing=""
  grep -qF '"url": "file://' "$AGENT" || missing="$missing url-field"
  grep -qF '"path"' "$AGENT"          || missing="$missing path-field-dropped"
  grep -qF 'theme_source' "$AGENT"    || missing="$missing theme_source-field"

  # The three documented values, so a caller can tell a defaulted dashboard from
  # a themed one.
  local vocab
  vocab="$(grep -F 'theme_source' "$AGENT")"
  case "$vocab" in
    *design-variables*) : ;;
    *) missing="$missing theme_source-vocab-design-variables" ;;
  esac
  case "$vocab" in
    *default*) : ;;
    *) missing="$missing theme_source-vocab-default" ;;
  esac

  if [ -n "$missing" ]; then
    fail test_refresher_returns_url "return block problems:$missing"
  else
    pass test_refresher_returns_url "success payload carries a clickable url and theme_source"
  fi
}

# --- test_entity_skills_cite_handoff ---------------------------------------
# Every entity-writing skill must end its work step by citing the canonical
# handoff. EXACTLY one citation, not "at least one": the single-occurrence count is
# what keeps the registered mutation's anchor unambiguous while pointer lines exist
# elsewhere in the same files.
test_entity_skills_cite_handoff() {
  entity_surface_ok test_entity_skills_cite_handoff || return

  local offenders="" skill f count
  for skill in $ENTITY_SKILLS; do
    f="$PLUGIN_DIR/skills/$skill/SKILL.md"
    count="$(grep -cF "$HANDOFF_PATH_LITERAL" "$f")"
    if [ "$count" -ne 1 ]; then
      offenders="$offenders $skill(cites=$count)"
    elif [ -z "$(handoff_section "$f")" ]; then
      offenders="$offenders $skill(no-section)"
    fi
  done

  if [ -n "$offenders" ]; then
    fail test_entity_skills_cite_handoff "entity skills without exactly one handoff citation:$offenders"
  else
    pass test_entity_skills_cite_handoff "all 8 entity skills end by citing the canonical handoff"
  fi
}

# --- test_pipeline_skills_cite_handoff --------------------------------------
# The pipeline and ops skills close their work step the same way the entity skills
# do. Same exactly-one-citation discipline as the entity case, for the same reason:
# the single-occurrence count keeps the registered mutation's anchor unambiguous.
#
# The Agent grant is NOT asserted here. test_dispatch_sites_grant_agent derives its
# dispatch lines from either form — naming the agent, or citing the canonical
# reference — so these six sit inside that case's surface and it covers their grant
# without a roster. Keeping a rostered copy too would mean the rostered one fails
# first, and only ever for the skills someone remembered to list.
# (test_resume_shows_dashboard_row still checks portfolio-resume's own grant as part
# of its row assertion; that is a narrower claim about one skill, not this roster.)
test_pipeline_skills_cite_handoff() {
  pipeline_surface_ok test_pipeline_skills_cite_handoff || return

  local offenders="" skill f count
  for skill in $PIPELINE_SKILLS; do
    f="$PLUGIN_DIR/skills/$skill/SKILL.md"
    count="$(grep -cF "$HANDOFF_PATH_LITERAL" "$f")"
    if [ "$count" -ne 1 ]; then
      offenders="$offenders $skill(cites=$count)"
    elif [ -z "$(handoff_section "$f")" ]; then
      offenders="$offenders $skill(no-section)"
    fi
  done

  if [ -n "$offenders" ]; then
    fail test_pipeline_skills_cite_handoff "pipeline skills without exactly one handoff citation:$offenders"
  else
    pass test_pipeline_skills_cite_handoff "all 6 pipeline and ops skills cite the canonical handoff"
  fi
}

# --- test_secondary_paths_reach_handoff ------------------------------------
# The acceptance bar is falsified by any file "whose end-of-step path can complete
# without reaching the handoff". Eight skills carry alternate write paths that do not
# flow into the terminal section — fourteen pointers rostered below, solutions and
# features holding three each, propositions and portfolio-scan two each — so each such
# path needs an explicit pointer back. The counts are floors rather than a census: which
# paths owe a pointer is decided by the rule in references/dashboard-handoff.md, so a
# path that rule covers but this roster has not caught up with must not turn this case
# red; losing a rostered one must.
# Three of them are early exits ABOVE the section rather than paths below it: portfolio-scan's
# research-only and shadow modes stop before Step 7.7, and portfolio-verify's
# no-propagable-resolutions branch jumps back to its communicate gate. All three have
# already written data the dashboard renders, so all three owe the same pointer.
test_secondary_paths_reach_handoff() {
  entity_surface_ok test_secondary_paths_reach_handoff || return
  pipeline_surface_ok test_secondary_paths_reach_handoff || return

  local offenders="" spec skill want got strays
  for spec in solutions:3 packages:1 propositions:2 portfolio-communicate:1 portfolio-scan:2 portfolio-verify:1 features:3 products:1; do
    skill="${spec%%:*}"
    want="${spec##*:}"
    got="$(grep -cF "$PTR_LINE" "$PLUGIN_DIR/skills/$skill/SKILL.md")"
    # >= so extending coverage to a path the rule already covers cannot break the case.
    if [ "$got" -lt "$want" ]; then
      offenders="$offenders $skill(want>=$want,got=$got)"
    fi
  done

  # A pointer names the section only. If one ever restates the dispatch it becomes a
  # second source of truth, and this check still catches that.
  # What the floor gives up, deliberately: a SURPLUS bare pointer. PTR_LINE names neither
  # the canonical path nor the agent, so a pointer added to a section the rule excludes is
  # invisible here, to the strays regex below, and to the citation counts. The exact count
  # used to catch it, at the price of rejecting correct coverage extensions too. Nothing
  # replaces that signal today; a ceiling keyed on the rule's excluded shapes would.
  strays="$(grep -lE "$(printf '%s' "$PTR_LINE" | sed 's/[][\.*^$]/\\&/g').*(dashboard-refresher|open_browser|references/dashboard-handoff)" \
            "$PLUGIN_DIR"/skills/*/SKILL.md 2>/dev/null | tr '\n' ' ')"
  if [ -n "$strays" ]; then
    offenders="$offenders pointer-restates-dispatch:$strays"
  fi

  if [ -n "$offenders" ]; then
    fail test_secondary_paths_reach_handoff "secondary write paths do not reach the handoff:$offenders"
  else
    pass test_secondary_paths_reach_handoff "every rostered alternate write path carries at least its expected pointer count"
  fi
}

# --- test_handoff_not_duplicated -------------------------------------------
# One author, many citers. A skill that restates the dispatch parameters has forked
# the contract, which is the drift this reference exists to prevent.
test_handoff_not_duplicated() {
  reference_surface_ok test_handoff_not_duplicated || return

  local scanned authors author_count offenders="" f sec
  scanned="$(find "$PLUGIN_DIR" -name '*.md' -type f | wc -l | tr -d ' ')"
  if [ "$scanned" -eq 0 ]; then
    fail test_handoff_not_duplicated "scanned no markdown files; scan surface is broken"
    return
  fi

  authors="$(grep -rlF '# End-of-step dashboard handoff' "$PLUGIN_DIR" \
             --include='*.md' --exclude-dir=tests 2>/dev/null)"
  author_count="$(printf '%s\n' "$authors" | grep -c . )"
  if [ "$author_count" -ne 1 ]; then
    fail test_handoff_not_duplicated "the handoff must be authored in exactly one file, found $author_count"
    return
  fi

  # Retention. The citing skills are forbidden from restating the dispatch, so the
  # reference is the ONLY place these facts exist anywhere in the plugin. Without
  # this, trimming the reference leaves eight skills citing a document that no
  # longer says what to dispatch — and every other case here stays green.
  local token
  for token in dashboard-refresher project_dir plugin_root url; do
    grep -qF "$token" "$HANDOFF_REF" || offenders="$offenders canonical-lost:$token"
  done

  # Rostered or not: whichever skill grows a handoff section next must cite, not copy.
  for f in $(skills_with_handoff_section); do
    sec="$(handoff_section "$f")"
    if printf '%s' "$sec" | grep -qE 'dashboard-refresher|project_dir|plugin_root|open_browser'; then
      offenders="$offenders ${f#"$PLUGIN_DIR/"}"
    fi
  done

  if [ -n "$offenders" ]; then
    fail test_handoff_not_duplicated "the handoff is not singly authored:$offenders"
  else
    pass test_handoff_not_duplicated "authored once in references/, cited never copied ($scanned files scanned)"
  fi
}

# The resume skill is the scan surface for the two cases below. Same reasoning
# as agent_surface_ok: a missing or empty file makes every literal assertion
# vacuously "not found", which reads as a real failure rather than a broken
# surface — so say which it is.
RESUME="$PLUGIN_DIR/skills/portfolio-resume/SKILL.md"
resume_surface_ok() {
  local case_name="$1"
  if [ ! -s "$RESUME" ]; then
    fail "$case_name" "skills/portfolio-resume/SKILL.md is missing or empty; scan surface is broken"
    return 1
  fi
  return 0
}

# --- test_resume_shows_dashboard_row ---------------------------------------
# The resume status table must carry a Dashboard row, and BOTH documented
# branches must survive: the has_dashboard-driven link, and the opt-in,
# non-opening generation offer. Anchor on the row's cell shape, not the bare
# word "dashboard" — that word appears elsewhere in this skill's prose, so a
# word-level grep would stay green with the row deleted.
test_resume_shows_dashboard_row() {
  resume_surface_ok test_resume_shows_dashboard_row || return

  local missing=""

  # The row itself, by cell shape.
  grep -qF '| Dashboard |' "$RESUME" || missing="$missing dashboard-table-row"

  # Branch 1 — presence comes from the discovery flag, not a fresh probe.
  # Anchor on the bullet's own phrasing: the bare flag name also appears in the
  # Step 1 discovery contract, so grepping it alone could never fail.
  grep -qF 'discovery flag `has_dashboard`' "$RESUME"             || missing="$missing presence-flag-not-cited"
  grep -qF 'never re-probe the filesystem' "$RESUME"              || missing="$missing filesystem-reprobe-not-banned"
  grep -qF 'file://<project-dir>/output/dashboard.html' "$RESUME" || missing="$missing no-clickable-link"

  # Branch 2 — the missing case says so, and generation stays opt-in.
  grep -qF 'offer to generate one' "$RESUME" || missing="$missing no-generation-offer"
  grep -qF 'if the user accepts' "$RESUME"   || missing="$missing no-opt-in-gate"

  # The frontmatter must permit the dispatch, or the documented branch is inert.
  grep -q '^allowed-tools:.*Agent' "$RESUME" || missing="$missing agent-tool-not-declared"

  if [ -n "$missing" ]; then
    fail test_resume_shows_dashboard_row "portfolio-resume dashboard row problems:$missing"
  else
    pass test_resume_shows_dashboard_row "dashboard row is flag-driven, links, opt-in gated, and Agent is declared"
  fi
}

# --- test_entity_handoff_does_not_open -------------------------------------
# The end-of-step path hands back a link, never a window. The reference must say so
# in the terms the agent contract uses — omission, not `open_browser: false`.
#
# Named for the entity surface, not the generic behaviour, because portfolio-resume
# owns a same-named case asserting over its own SKILL.md. Two functions with one name
# would leave bash holding only the last definition while ALL_TESTS still listed the
# name — the suite would report green having never run the dropped case.
test_entity_handoff_does_not_open() {
  reference_surface_ok test_entity_handoff_does_not_open || return

  local problems="" sections=0 f sec
  grep -qF 'Do not pass `open_browser`' "$HANDOFF_REF" \
    || problems="$problems no-omission-instruction"
  # Whole-file, not the open_browser line: pinning both to one physical line makes a
  # cosmetic reflow of that paragraph fail the case while nothing has changed.
  grep -qi 'omitting it' "$HANDOFF_REF" \
    || problems="$problems omission-not-explained"
  grep -qF 'Never open a browser from this step.' "$HANDOFF_REF" \
    || problems="$problems no-never-open-sentence"
  if grep -qF 'open_browser: true' "$HANDOFF_REF"; then
    problems="$problems reference-passes-the-opt-in"
  fi

  for f in $(skills_with_handoff_section); do
    sec="$(handoff_section "$f")"
    sections=$((sections + 1))
    if printf '%s' "$sec" | grep -qF 'open_browser: true'; then
      problems="$problems ${f#"$PLUGIN_DIR/"}:passes-the-opt-in"
    fi
    if printf '%s' "$sec" | grep -qiF 'open the dashboard'; then
      problems="$problems ${f#"$PLUGIN_DIR/"}:promises-to-open"
    fi
  done

  if [ "$sections" -eq 0 ]; then
    fail test_entity_handoff_does_not_open "extracted no handoff sections; scan surface is broken"
    return
  fi
  if [ -n "$problems" ]; then
    fail test_entity_handoff_does_not_open "end-of-step path can open a browser:$problems"
  else
    pass test_entity_handoff_does_not_open "reference states the omission and $sections sections open nothing"
  fi
}

# --- test_midflow_offers_survive -------------------------------------------
# The end-of-step handoff ADDS a path; it must never remove one. Each pre-existing
# review offer is a deliberate checkpoint where the user asked for a window, so each
# must still name the opt-in. >= so a future legitimate offer does not break this.
test_midflow_offers_survive() {
  # Each caller carries its own expected count, so a lost offer names the file
  # rather than reporting a bare total that a maintainer has to re-grep by hand.
  local callers total=0 offenders="" spec rel want f n
  callers='compete/SKILL.md:1 customers/SKILL.md:1 features/SKILL.md:1 markets/SKILL.md:1
           packages/SKILL.md:1 portfolio-architecture/SKILL.md:1 portfolio-dashboard/SKILL.md:1
           products/SKILL.md:1 solutions/SKILL.md:1
           propositions/references/quality-gates.md:2'

  for spec in $callers; do
    rel="${spec%:*}"
    want="${spec##*:}"
    f="$PLUGIN_DIR/skills/$rel"
    if [ ! -s "$f" ]; then
      offenders="$offenders $rel(missing)"
      continue
    fi
    n="$(grep -cE 'dashboard-refresher.*open_browser: true' "$f")"
    # >= so a future legitimate offer does not break the case.
    if [ "$n" -lt "$want" ]; then
      offenders="$offenders $rel(want>=$want,got=$n)"
    fi
    total=$((total + n))
  done

  if [ "$total" -eq 0 ]; then
    fail test_midflow_offers_survive "found no mid-flow dispatch lines; scan surface is broken"
    return
  fi

  if [ -n "$offenders" ]; then
    fail test_midflow_offers_survive "mid-flow review offers were lost:$offenders"
  else
    pass test_midflow_offers_survive "all 10 caller files keep their opt-in offer ($total dispatch lines)"
  fi
}

# --- test_handoff_does_not_open --------------------------------------------
# The resume offer regenerates a dashboard; it must never launch a browser on
# its own. The refresher already defaults open_browser to false, but the resume
# call site states it explicitly so the intent is readable where it is made.
# test_open_browser_optin does not cover this: that case is scoped to call
# sites whose surrounding prose promises to open, and this one does not.
test_handoff_does_not_open() {
  resume_surface_ok test_handoff_does_not_open || return

  local missing=""
  grep -qF 'dashboard-refresher' "$RESUME" || missing="$missing no-refresher-dispatch"
  grep -qF 'open_browser: false' "$RESUME" || missing="$missing generation-may-open-browser"
  # Presence, not absence, is the defect here — so an explicit if, matching the
  # inverted-polarity assertions elsewhere in this suite.
  if grep -qF 'open_browser: true' "$RESUME"; then
    missing="$missing resume-opens-a-browser"
  fi

  if [ -n "$missing" ]; then
    fail test_handoff_does_not_open "portfolio-resume generation offer problems:$missing"
  else
    pass test_handoff_does_not_open "the resume generation offer dispatches with the non-opening flag"
  fi
}

# --- test_dispatch_sites_grant_agent ---------------------------------------
# A documented dispatch is only reachable at runtime if the frontmatter GOVERNING
# that file grants the dispatch tool. Both halves are derived, never enumerated:
# the surface is the same three-glob scan test_open_browser_optin computes, and
# the governing file comes from the path — a dispatch in
# skills/<x>/references/*.md is governed by skills/<x>/SKILL.md, the only file in
# that skill carrying frontmatter. A skill that starts dispatching tomorrow is
# covered with no edit here. agents/*.md declare their tools under a different
# key, so they stay in the scan surface but outside this rule.
#
# A documented dispatch is EITHER form: naming the agent, or citing the canonical
# references/dashboard-handoff.md contract that dispatches it. The canonical
# end-of-step handoff deliberately never names the agent — that omission is what
# keeps it clear of test_handoff_not_duplicated and of test_open_browser_optin's
# offender window — so a name-only surface was blind to exactly the skills using
# the shared contract, and their grant had to be rostered elsewhere. Deriving both
# forms here is what lets the grant be asserted in one place. The dot is escaped
# in the alternation, so a near-miss path like references/dashboard-handoffXmd
# cannot pass.
#
# What this case still shares with test_open_browser_optin is the three-glob FILE
# surface below, not the dispatch-line derivation: that is deliberately wider here,
# because promising to open a browser is a different claim from documenting a
# dispatch, and only the latter is satisfied by citing the contract.
test_dispatch_sites_grant_agent() {
  local surface scanned
  surface="$(
    find "$PLUGIN_DIR/agents" -name '*.md' -type f 2>/dev/null
    find "$PLUGIN_DIR/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f 2>/dev/null
    find "$PLUGIN_DIR/skills" -mindepth 3 -maxdepth 3 -path '*/references/*.md' -type f 2>/dev/null
  )"
  scanned="$(printf '%s\n' "$surface" | grep -c . )"
  if [ "$scanned" -eq 0 ]; then
    fail test_dispatch_sites_grant_agent "scanned no files; scan surface is broken"
    return
  fi

  local dispatch_lines dispatch_count
  dispatch_lines="$(
    printf '%s\n' "$surface" | while IFS= read -r f; do
      [ -n "$f" ] || continue
      [ "$f" = "$AGENT" ] && continue
      grep -nE 'dashboard-refresher|references/dashboard-handoff\.md' "$f" 2>/dev/null | while IFS= read -r hit; do
        printf '%s:%s\n' "$f" "$hit"
      done
    done
  )"
  dispatch_count="$(printf '%s\n' "$dispatch_lines" | grep -c . )"
  if [ "$dispatch_count" -eq 0 ]; then
    fail test_dispatch_sites_grant_agent "found no documented dispatch lines (agent name or canonical citation); scan surface is broken"
    return
  fi

  # PARTIAL decay is what the zero-check above structurally cannot catch, and a
  # two-form derivation is exactly where it bites: the name arm satisfies that
  # check on its own forever, so the citation arm could die — a renamed reference,
  # a lost escape — and this case would stay green with the citation-only skills
  # silently ungoverned again. That is the defect this widening exists to remove,
  # and the rostered assertion that used to cover those skills is gone, so each arm
  # carries its own floor. Same discipline as test_invocation_surface_intact in
  # test-bash-grant.sh. The citation floor is built from HANDOFF_PATH_LITERAL, so a
  # rename that leaves the alternation behind fails LOUDLY here instead of quietly
  # narrowing the surface. Floors, never exact counts, so honest churn cannot trip
  # them.
  local name_arm citation_arm
  name_arm="$(printf '%s\n' "$dispatch_lines" | grep -cF 'dashboard-refresher')"
  citation_arm="$(printf '%s\n' "$dispatch_lines" | grep -cF "$HANDOFF_PATH_LITERAL")"
  if [ "$name_arm" -eq 0 ] || [ "$citation_arm" -eq 0 ]; then
    fail test_dispatch_sites_grant_agent "a derivation arm went dead: name hits=$name_arm citation hits=$citation_arm (both must be non-zero)"
    return
  fi

  # One pass, no early exit: every offender lands in $offenders and the single
  # fail() below names them all. $seen collapses a skill that dispatches from more
  # than one file so it is reported once. The heredoc — not a pipe — is what keeps
  # both accumulators in this shell.
  local offenders="" seen="" governed=0
  while IFS= read -r entry; do
    local file governing rel grant
    file="${entry%%:*}"
    governing=""
    case "$file" in
      "$PLUGIN_DIR"/skills/*/references/*) governing="${file%/references/*}/SKILL.md" ;;
      "$PLUGIN_DIR"/skills/*/SKILL.md)     governing="$file" ;;
    esac
    if [ -n "$governing" ]; then
      rel="${governing#"$PLUGIN_DIR/"}"
      case " $seen " in
        *" $rel "*) : ;;
        *)
          seen="$seen $rel"
          governed=$((governed + 1))
          if [ ! -s "$governing" ]; then
            # Distinct from a missing grant on purpose: a broken surface must never
            # read as a skill that simply forgot the token.
            offenders="$offenders $rel:governing-SKILL.md-missing"
          else
            grant="$(grep -m1 '^allowed-tools:' "$governing")"
            if [ -z "$grant" ]; then
              offenders="$offenders $rel:no-allowed-tools-line"
            else
              # The grant LINE only, whole-token. Every dispatching skill's prose
              # says "dashboard-refresher agent", so a body-wide grep for Agent
              # would be vacuously green; and matching a substring would let
              # Skill, AskUserQuestion or an mcp__* token pass as the grant.
              grant="${grant#allowed-tools:}"
              case ",${grant//[[:space:]]/}," in
                *,Agent,*) : ;;
                *) offenders="$offenders $rel:missing-Agent" ;;
              esac
            fi
          fi
          ;;
      esac
    fi
  done <<EOF
$dispatch_lines
EOF

  if [ -n "$offenders" ]; then
    fail test_dispatch_sites_grant_agent "dispatching skills whose allowed-tools omits Agent:$offenders"
  else
    pass test_dispatch_sites_grant_agent "all $governed dispatching skills grant Agent ($dispatch_count dispatch lines scanned)"
  fi
}

# Every case from both branches, registered together. A name dropped here still
# resolves as a shell function, so run_one() would happily execute it while a no-arg
# CI run silently skips it — the registration list is the only thing that makes the
# suite complete.
ALL_TESTS="test_refresher_has_no_skip_path test_open_browser_optin test_refresher_returns_url test_entity_skills_cite_handoff test_pipeline_skills_cite_handoff test_secondary_paths_reach_handoff test_handoff_not_duplicated test_entity_handoff_does_not_open test_midflow_offers_survive test_resume_shows_dashboard_row test_handoff_does_not_open test_dispatch_sites_grant_agent"

# Reject an unknown case name instead of letting bash's "command not found" pass
# through: with no `set -e` and no failures increment, an unrecognised name would
# otherwise print "All tests passed." having run nothing at all.
run_one() {
  case " $ALL_TESTS " in
    *" $1 "*) "$1" ;;
    *) printf 'unknown test %s\n' "$1" >&2; exit 2 ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for t in "$@"; do run_one "$t"; done
else
  for t in $ALL_TESTS; do "$t"; done
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'
