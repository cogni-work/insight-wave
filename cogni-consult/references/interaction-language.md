# Interaction language vs. deliverable language

cogni-consult separates two independent language axes. Conflating them forces a
single choice where two are needed — e.g. an engagement whose deliverables are
deliberately English while the consultant and user converse in German.

## The two axes

| Axis | What it controls | Where it lives |
|------|------------------|----------------|
| **deliverable language** | The language of generated artifacts — knowledge-base output, dashboard document language, written deliverables. | The `language` field in `consult-project.json` (ISO 639-1, default `en`). Persisted; set at setup; seeds `--output-language` for the knowledge base. |
| **interaction language** | The language of the user-facing conversation — questions, acknowledgments, status messages, recommendations. | Runtime-derived, **never persisted**. Resolved fresh each session (see below). |

The `language` field is the deliverable axis **only**. Never read it to decide
which language to *converse* in.

## Resolving the interaction language

Resolve it the same way `cogni-help:cogni-issues` does, in this order:

1. **Workspace default** — read `.workspace-config.json` in the workspace root;
   its `language` field (e.g. `"en"` or `"de"`) is the default interaction
   language. The workspace `CLAUDE.md` may also state a preferred language.
2. **Message-detection override** — if the user's message is written in a
   different language, prefer the user's language. Someone writing in German
   wants a German reply even when the workspace is set to English.
3. **Fallback** — if `.workspace-config.json` is missing and the message
   language is unclear, default to English.

Conduct the entire conversation in the resolved interaction language; technical
terms, slugs, skill names, CLI commands, and file names stay English regardless.

## Why they are separate

A consultant can legitimately produce English deliverables for a client while
working through them with a German-speaking stakeholder. One axis cannot express
that. Keeping the deliverable language in `consult-project.json` and deriving the
interaction language at runtime lets each follow its own source of truth.
