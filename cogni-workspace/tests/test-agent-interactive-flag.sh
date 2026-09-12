#!/usr/bin/env bash
# Agent/interactive-skill pairing guard: every cogni-workspace agent that
# delegates to an interactive-bearing skill must pin the non-interactive value
# on its dispatch line (A3); EXEMPT entries are skipped there and policed by
# A5. An in-scope agent's own AskUserQuestion grant is deliberately NOT
# asserted on -- the A4 comment below records why. The grant assertions this
# suite does make run the other way: an interactive-bearing SKILL must keep
# its grant (A4), and an EXEMPT agent must not regain one (A5).
#
# Why this exists. Five cogni-workspace skills expose an `interactive` (or
# `--interactive`) parameter that defaults to TRUE and gates one or more
# AskUserQuestion sites on it. An agent has no user: reaching such a prompt
# stalls the subagent rather than returning an error, so the failure is a hang,
# not a traceback, and it surfaces far from its cause.
#
# An earlier, narrative-specific guard closed one instance of this class by
# naming one skill and one agent as literals; it retired with that skill. A
# literal-named guard cannot see a new agent or a new interactive-bearing skill,
# which is why this suite is the general form and discovers its population.
#
# The population is DISCOVERED, not enumerated. A1 finds the interactive-bearing
# skills by reading their own parameter tables; A2 finds the agents that name one
# of those skills. A sixth skill gaining an `interactive` row, or a new agent
# delegating to one, is therefore in scope the moment it lands — which is the
# whole point of replacing a literal-named guard with this one. The only literal
# roster here is EXEMPT, and it is deliberately small, justified per entry, and
# asserted non-vacuous by A5.
#
# A3 binds PER AGENT -- at least one dispatch site per agent carries the pin --
# and deliberately not "every args line carries it". An agent may legitimately
# carry a second dispatch example without the pin (the retired story-to-slides
# driver did), so the every-line reading would be red on a correct file, and the
# cheapest reaction to that redness would be to weaken the case rather than fix
# anything.
#
# Mutation recipe (proves A3 has teeth). Every flag value is a literal — the
# handoff preflight rejects a variable-bearing recipe, and a
# ${CLAUDE_PLUGIN_ROOT}-relative harness path resolves to one of the two
# argument-less in-repo copies and replays to a false green. Run from the repo
# root:
#
#   bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" \
#     --root . \
#     --file cogni-workspace/agents/enrich-report.md \
#     --expr 's/interactive=false/interactive=true/' \
#     --test 'bash cogni-workspace/tests/test-agent-interactive-flag.sh' \
#     --case A3
#
# The search literal occurs exactly once in that file (on the dispatch line;
# the parameter table spells the flag and its value in separate cells), so the
# expr cannot report expr_no_op; it is a plain non-global s/// with no capture
# groups, so it is valid for `perl -0pi`; and the replacement flips the value
# while keeping the key, so the mutant cannot re-satisfy A3 — enrich-report
# loses its dispatch-site pin and A3 goes red naming that file. A1, A2, A4 and
# A5 are untouched, so the redness is attributable to A3 alone.
#
# The expr carries no shell metacharacter -- no backtick, no $, no parenthesis.
# Deleting the whole ", always with `interactive=false`" clause also reddens A3,
# but that literal contains backticks and the handoff preflight rejects the
# recipe as not replayable as written. A recipe that cannot be replayed is not
# evidence.

# set -u but deliberately NOT set -e: a red arm must print its FAIL line and let
# the run reach the summary, not abort the script at the first failing check.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$(cd "$HERE/.." && pwd)"
SKILLS_DIR="$WS_ROOT/skills"
AGENTS_DIR="$WS_ROOT/agents"

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# ---------------------------------------------------------------------------
# EXEMPT -- agents that name an interactive-bearing skill but provably cannot
# reach one of its prompts. Each entry must carry its reason on the same line,
# and A5 asserts every entry's stated escape route still holds, so an exemption
# cannot outlive the property that justified it.
#
# Empty today. The one entry this list carried — narrative-adapter, which
# delegated to the narrative skill only in a mode that skipped every prompt
# site — retired with that skill. An empty list is safe: A3 skips nothing and
# A5 polices nothing, and both are still exercised by the discovered
# population. Add an entry only with its reason on the same line.
# ---------------------------------------------------------------------------
EXEMPT=""

# ---------------------------------------------------------------------------
# A0 -- the two directories this suite reasons over must exist. Without this,
# every later loop iterates an empty set and the whole suite passes vacuously.
# ---------------------------------------------------------------------------
if [ -d "$SKILLS_DIR" ] && [ -d "$AGENTS_DIR" ]; then
  pass "A0 setup skills/ and agents/ are both readable"
else
  fail "A0 setup skills/ and agents/ are both readable"
  echo ""
  echo "RESULT: $failures agent-interactive case(s) failed."
  exit 1
fi

# ---------------------------------------------------------------------------
# A1 -- discover the interactive-bearing skills: a SKILL.md carrying a
# parameter-table row for `interactive` or `--interactive`. Binds to the row
# shape (leading pipe + backticked flag) so a passing mention in prose does not
# enrol a skill that has no such parameter.
#
# Asserted non-empty. A discovery that finds nothing would make A2 and A3 pass
# over an empty population -- the vacuous-green shape this case exists to stop.
# ---------------------------------------------------------------------------
interactive_skills=""
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  if grep -qE '^\| `(--)?interactive` \|' "$skill_md"; then
    skill_name="$(basename "$(dirname "$skill_md")")"
    interactive_skills="$interactive_skills $skill_name"
  fi
done

skill_count=$(printf '%s\n' $interactive_skills | grep -c . || true)
if [ "$skill_count" -ge 1 ]; then
  pass "A1 discovered $skill_count interactive-bearing skill(s):$interactive_skills"
else
  fail "A1 discovered at least one interactive-bearing skill (found none -- discovery is broken, not the tree)"
fi

# ---------------------------------------------------------------------------
# A2 -- discover the agents in scope: an agent that names one of A1's skills.
# Also asserted non-empty, for the same vacuity reason as A1.
# ---------------------------------------------------------------------------
# The tools declaration is read here as well as in A4, so both cases agree on
# what an agent is allowed to do. Two forms are in use in this directory: the
# inline `tools: A, B, C` (also seen as a JSON array) and the YAML block
# sequence under a bare `tools:`.
read_tools_decl() {
  awk '
    /^tools:[[:space:]]*[^[:space:]]/ { print; next }
    /^tools:[[:space:]]*$/            { inblock = 1; next }
    inblock && /^[[:space:]]*-[[:space:]]/ { print; next }
    inblock                           { inblock = 0 }
  ' "$1"
}

scoped_agents=""
for agent_md in "$AGENTS_DIR"/*.md; do
  [ -f "$agent_md" ] || continue
  agent_name="$(basename "$agent_md" .md)"
  # An agent that cannot dispatch cannot reach a prompt. Three agents
  # (brief-review-assessor, report-html-writer, slides-enrichment-artist) read a
  # reference file out of a skill's directory without ever invoking the skill;
  # without this gate they enrol and A3 goes red demanding a pin that would
  # assert a dispatch they do not perform.
  case "$(read_tools_decl "$agent_md")" in
    *Skill*) ;;
    *) continue ;;
  esac
  for s in $interactive_skills; do
    # A skill REFERENCE, never the bare word: `narrative` is also an ordinary
    # noun that half these agent bodies use in prose, and matching it enrolled
    # four agents that dispatch nothing. The three accepted forms are the
    # plugin-qualified name, the Skill-tool invocation line, and a path to the
    # skill's own SKILL.md. That last form is deliberately not `skills/$s/` --
    # reading `skills/$s/references/<file>.md` is ordinary reference loading and
    # is not a dispatch.
    if grep -qE "cogni-workspace:$s\b|^[[:space:]]*Skill:[[:space:]]*$s\b|skills/$s/SKILL\.md" "$agent_md"; then
      scoped_agents="$scoped_agents $agent_name"
      break
    fi
  done
done

agent_count=$(printf '%s\n' $scoped_agents | grep -c . || true)
if [ "$agent_count" -ge 1 ]; then
  pass "A2 discovered $agent_count agent(s) delegating to an interactive-bearing skill:$scoped_agents"
else
  fail "A2 discovered at least one delegating agent (found none -- discovery is broken, not the tree)"
fi

# ---------------------------------------------------------------------------
# A3 -- every in-scope, non-exempt agent pins the non-interactive value.
#
# Both spellings are accepted because both are correct at their own call site:
# the Skill-tool `args` form takes `interactive=false`, the narrative skill's
# flag surface takes `--interactive false`. Accepting only one would force a
# wrong spelling into half the population.
#
# This is the case the mutation recipe above drives red.
# ---------------------------------------------------------------------------
unpinned=""
for agent_name in $scoped_agents; do
  case " $EXEMPT " in *" $agent_name "*) continue ;; esac
  agent_md="$AGENTS_DIR/$agent_name.md"
  # Bound to the DISPATCH SITE, not to a bare occurrence anywhere in the file.
  # The first draft of this case accepted the literal wherever it appeared, and
  # the recorded mutation below returned `vacuous_guard`: the agents also
  # document the parameter in prose and in a table row, so deleting the pin from
  # the actual dispatch left two other copies behind and the case stayed green.
  # It is the same by-site discipline the retired narrative-specific guard
  # stated, arrived at the same way.
  #
  # The pin must share a line with the invocation itself. Four dispatch spellings
  # are in use and all four satisfy this: the `<parameter name="args">` line, the
  # `args:` line inside a fenced Skill block, "Load and follow the skill at ...,
  # always with ...", and "Invoke the ... skill ... always with ...". The
  # documentation surfaces deliberately do not: the table row states the default
  # in its own column rather than as the literal, and the explanatory paragraph
  # names the value in words.
  if grep -E 'interactive=false|--interactive false' "$agent_md" \
     | grep -qE 'args|[Ss]kill|[Ii]nvoke|follow'; then
    continue
  fi
  unpinned="$unpinned $agent_name"
done

if [ -z "$unpinned" ]; then
  pass "A3 every in-scope non-exempt agent pins interactive=false"
else
  fail "A3 every in-scope non-exempt agent pins interactive=false (unpinned:$unpinned)"
fi

# ---------------------------------------------------------------------------
# A4 -- the default HUMAN-interactive path survives on every discovered skill.
#
# This is the #1773-class wrong-fix direction, and it is the one that costs a
# real user something. Pinning the agent side makes the skill's prompts look
# unreachable, and the cheapest-looking cleanup from there is to strip
# `AskUserQuestion` from a skill's `allowed-tools:` or to delete its
# `interactive` branch. Either silently breaks the checkpoint for every HUMAN
# caller while the agent-side pin still reads as correct, so A3 alone would stay
# green straight through it.
#
# An earlier draft of this case asserted the opposite of the grant conjunct --
# that no in-scope AGENT may hold an `AskUserQuestion` grant. That was wrong on
# base facts: `references/agent-tool-declarations.md` records, per agent, why a
# `tools:` line carries what it does -- `enrich-report` carries its skill's
# `allowed-tools` -- the common reason being that the Skill tool runs the skill
# in the agent's own context, and that a least-privilege trim of exactly this
# kind was raised and declined on review. The grant is
# capability the skill exercises, not privilege the agent uses; the pin, not the
# grant, is what stops the prompt.
#
# Asserted by SITE, never by a total occurrence count -- a pinned total goes
# red on the legitimate direction of travel (a skill gaining a second gated
# prompt), which is what the retired narrative-specific guard recorded.
# ---------------------------------------------------------------------------
skill_regressions=""
for s in $interactive_skills; do
  skill_md="$SKILLS_DIR/$s/SKILL.md"
  if ! grep -qE '^allowed-tools:.*AskUserQuestion' "$skill_md"; then
    skill_regressions="$skill_regressions $s(grant-stripped)"
  fi
  # The gating statement: a line naming `interactive`, a `When`, and the `false`
  # arm. Every one of the five discovered skills carries at least one today.
  if ! grep 'interactive' "$skill_md" | grep -E '[Ww]hen' | grep -q 'false'; then
    skill_regressions="$skill_regressions $s(branch-deleted)"
  fi
done

if [ -z "$skill_regressions" ]; then
  pass "A4 every interactive-bearing skill keeps its AskUserQuestion grant and its false-branch"
else
  fail "A4 every interactive-bearing skill keeps its AskUserQuestion grant and its false-branch (regressions:$skill_regressions)"
fi

# ---------------------------------------------------------------------------
# A5 -- every EXEMPT entry is still both in scope and still justified.
#
# Two failure directions, and the suite must catch both. An exemption naming an
# agent no longer in scope is dead roster that silently widens if the name is
# ever reused. An exemption whose stated escape route has lapsed -- here,
# narrative gaining a prompt outside the --format-skipped range, or the agent
# regaining an AskUserQuestion grant -- is an exemption that now hides a live
# instance, which is exactly what A3 would otherwise have caught.
# ---------------------------------------------------------------------------
exempt_problems=""
for agent_name in $EXEMPT; do
  case " $scoped_agents " in
    *" $agent_name "*) ;;
    *) exempt_problems="$exempt_problems $agent_name(not-in-scope)"; continue ;;
  esac
  agent_md="$AGENTS_DIR/$agent_name.md"
  # The stated escape route: derivative-only delegation, no prompt reachable.
  if ! grep -q '\-\-format' "$agent_md"; then
    exempt_problems="$exempt_problems $agent_name(no-longer-format-only)"
  fi
  if grep -q 'AskUserQuestion' "$agent_md"; then
    exempt_problems="$exempt_problems $agent_name(regained-grant)"
  fi
done

if [ -z "$exempt_problems" ]; then
  pass "A5 every EXEMPT entry is in scope and its stated justification still holds"
else
  fail "A5 every EXEMPT entry is in scope and its stated justification still holds (problems:$exempt_problems)"
fi

# ---------------------------------------------------------------------------
# The summary line begins RESULT:, never FAIL:. A FAIL:-prefixed summary is
# itself parsed as a case verdict by the shared mutation harness.
# ---------------------------------------------------------------------------
echo ""
if [ "$failures" -gt 0 ]; then
  echo "RESULT: $failures agent-interactive case(s) failed."
  exit 1
fi
echo "RESULT: all agent-interactive cases passed."
exit 0
