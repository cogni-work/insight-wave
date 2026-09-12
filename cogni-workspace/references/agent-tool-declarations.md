# Agent tool declarations

Why the `tools:` line of a `cogni-workspace/agents/*.md` file is shaped the way it is. An agent body is
a runtime system prompt, loaded on every dispatch — rationale addressed to a future editor spends
that budget on text the agent cannot act on, so it lives here instead. Cite this file by its
repo-relative path (`cogni-workspace/references/agent-tool-declarations.md`) rather than restating a
rationale inside the agent it explains.

## The mirror rule

The Skill tool runs a skill in the dispatching agent's own context, so the skill's own tool
needs are served by the agent's grant. An agent that dispatches a skill therefore carries that
skill's `allowed-tools`, and narrowing `tools:` to what the agent *body* appears to use removes
capability, not privilege: the missing tools are exercised by the skill running inside the agent.
A least-privilege trim of exactly this kind was raised and declined on review for that reason.

The one grant the rule does **not** extend to is a prompt tool the skill is told not to reach: a
headless caller that always passes the non-interactive value never arrives at a prompt site, so
`AskUserQuestion` is kept or dropped on whether the skill exercises it in this agent's context,
never on whether the skill lists it. The pin on the dispatch line, not the grant, is what stops
the prompt. `tests/test-agent-interactive-flag.sh` discovers every agent that delegates to an
interactive-bearing skill and pins the flag at its dispatch site.

## enrich-report

`tools:` carries `skills/enrich-report/SKILL.md`'s `allowed-tools` under the mirror rule, including
`AskUserQuestion`, which that skill exercises at its Review checkpoint in this agent's context; the
agent pins `interactive=false` on the dispatch line, so the prompt is never reached. The grant mirrors that
`allowed-tools` line exactly. It previously also named `Edit` and `Grep`; neither the agent body nor
anything under `skills/enrich-report/` exercised either, so the mirror rule's capability argument did
not reach them and both were dropped rather than given a rationale.
