#!/usr/bin/env python3
"""
rebuild_open_questions.py — emit `wiki/open_questions.md`, the persistent
checklist of lint-derived "data gaps" that compounds across sessions.

Auto-invoked by Step 8.5 of `wiki-lint` once per dispatch (after the
config bump). stdlib-only. `{success, data, error}` JSON on stdout.

Unlike `rebuild_context_brief.py` (full overwrite), this file is a
**read-modify-write**: we parse the existing checklist, reconcile against
the current lint output, flip newly-resolved items to `- [x]` with a best-
effort "closed by" attribution from `wiki/log.md`, and trim closed items
older than `CLOSED_RETENTION_DAYS`. The lock at `<wiki-root>/.cogni-wiki/.lock`
serialises the RMW so two concurrent `wiki-lint` invocations from separate
sessions don't trample each other.

Sections, in order:

  1. Pages without sources                  (`no_sources`)
  2. Synthesis pages without wiki:// sources (`synthesis_no_wiki_source`)
  3. Orphan pages                           (`orphan_page`)
  4. Stale pages                            (`stale_page`)
  5. Stale drafts                           (`stale_draft`)
  6. Claim-drift candidates                 (`claim_drift`)
  7. Reverse-link gaps                      (`reverse_link_missing`)
  8. Research-time gaps — uncovered         (`research_uncovered`)
  9. Research-time gaps — partial           (`research_partial`)

`tag_typo` (cosmetic) and `info`-class items are excluded — they aren't
"data gaps" the user needs to act on.

Classes 1–7 are lint findings about *existing* pages. Classes 8–9 are
research-time gaps about *missing* coverage — sub-questions the
curate→ingest→compose pipeline never managed to cover for a research run.
They are NOT produced by `lint_wiki.py`; they are deposited by
`cogni-knowledge:knowledge-finalize` via the `--findings -` stdin contract
(#354), keyed by a synthetic `sq:<sq_id>` identifier instead of an on-disk
page slug. `finalize` is a `CLOSING_OPS` op so a later finalize that covers a
previously-uncovered sub-question credit-closes the item (`closed … by finalize`).

The future LLM-emitted `missing_concept_page` items are out of scope for
v0.0.30 (deferred follow-up); the `--findings -` stdin contract is in
place from day 1 so the follow-up only needs to update Step 4d's prompt
to produce structured JSON and pipe it in here.

Failure isolation: a non-zero exit must not roll back the lint run. The
audit report and config bump from Steps 5–8 are already on disk.
"""

from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

# `_wikilib` lives in the sibling wiki-ingest/scripts/ directory.
sys.path.insert(
    0,
    str(Path(__file__).resolve().parents[2] / "wiki-ingest" / "scripts"),
)
from _wikilib import (  # noqa: E402
    _wiki_lock,
    atomic_write,
    emit_json,
    fail_if_pre_migration,
)


OPEN_QUESTIONS_PATH = "wiki/open_questions.md"

def _meta_first(wiki_root, filename):
    """Meta-first control-file resolution (cogni-knowledge divergence).

    The curated layout keeps the visible control files under `wiki/meta/`.
    Prefer `wiki/meta/<filename>` when it exists; fall back to an EXISTING
    legacy flat `wiki/<filename>` (pre-migration bases keep working); default
    a file absent from both layouts to `wiki/meta/` — the canonical location.
    Mirrors cogni-knowledge's `_knowledge_lib._resolve_control_path` so the
    vendored side can never desync from the CK-side writers. Self-contained
    on purpose: vendored scripts never import from cogni-knowledge/scripts/.
    """
    meta = Path(wiki_root) / "wiki" / "meta" / filename
    if meta.exists():
        return meta
    flat = Path(wiki_root) / "wiki" / filename
    if flat.exists():
        return flat
    return meta

CLOSED_RETENTION_DAYS = 90

# Class → section header. Order is the canonical render order.
SECTIONS = [
    ("no_sources",                "Pages without sources"),
    ("synthesis_no_wiki_source",  "Synthesis pages without wiki:// sources"),
    ("orphan_page",               "Orphan pages"),
    ("stale_page",                "Stale pages"),
    ("stale_draft",               "Stale drafts"),
    ("claim_drift",               "Claim-drift candidates"),
    ("reverse_link_missing",      "Reverse-link gaps"),
    # Research-time gaps (#354) — deposited by cogni-knowledge:knowledge-finalize
    # via --findings -, keyed by a synthetic `sq:<sq_id>` id, never by lint.
    ("research_uncovered",        "Research-time gaps — uncovered"),
    ("research_partial",          "Research-time gaps — partial"),
]
HEADER_TO_CLASS = {header: cls for cls, header in SECTIONS}
TRACKED_CLASSES = frozenset(cls for cls, _ in SECTIONS)

# Log ops that count as plausibly closing a gap. `finalize` (#354) lets a
# knowledge-finalize dispatch credit-close a research-time gap via the
# `sqs=sq-01,sq-04` suffix it writes on its `wiki/log.md` line.
CLOSING_OPS = ("update", "ingest", "re-ingest", "synthesis", "finalize")

CANONICAL_HEADER_COMMENT = (
    "<!-- AUTOGENERATED by skills/wiki-lint/scripts/rebuild_open_questions.py.\n"
    "     Hand-edits are dropped on rebuild. Closed items >90 days old are trimmed.\n"
    "     See skills/wiki-lint/SKILL.md §\"Step 8.5\". -->\n"
)

OPEN_LINE_RE = re.compile(
    r"^- \[ \] `(?P<page>[^`]+)` — (?P<message>.*)$"
)
CLOSED_LINE_RE = re.compile(
    r"^- \[x\] ~~`(?P<page>[^`]+)` — (?P<message>.*)~~ "
    r"— closed (?P<date>\d{4}-\d{2}-\d{2})(?: by (?P<by>[a-z\-]+))?$"
)
SECTION_HEADER_RE = re.compile(r"^## (?P<header>.+)$")
LOG_LINE_RE = re.compile(
    r"^## \[(?P<date>\d{4}-\d{2}-\d{2})\] (?P<op>[a-z\-]+)\s*\| (?P<rest>.*)$"
)


def _today() -> datetime.date:
    return datetime.datetime.now(datetime.timezone.utc).date()


def _now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------------------
# Parse the existing open_questions.md (if any) into a flat dict.
# ---------------------------------------------------------------------------


def parse_existing(path: Path) -> dict:
    """Return `{(class, page): item}` parsed from an existing checklist.

    Each item carries `state` ("open"|"closed"), `message`, plus
    `opened_on` / `closed_on` / `by` for closed items. Lines that do not
    match the canonical render shape are silently dropped — the file is
    autogenerated and the comment header warns hand-editors.
    """
    out: dict = {}
    if not path.is_file():
        return out
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return out
    current_class: str | None = None
    for raw in text.splitlines():
        line = raw.rstrip()
        m = SECTION_HEADER_RE.match(line)
        if m:
            current_class = HEADER_TO_CLASS.get(m.group("header"))
            continue
        if current_class is None:
            continue
        m_open = OPEN_LINE_RE.match(line)
        if m_open:
            key = (current_class, m_open.group("page"))
            out[key] = {
                "state": "open",
                "message": m_open.group("message"),
                # `opened_on` is unrecoverable from the rendered form; treat
                # the file's existence as evidence the item is open *now*.
                # New items added below will set today's date.
            }
            continue
        m_closed = CLOSED_LINE_RE.match(line)
        if m_closed:
            try:
                closed_on = datetime.date.fromisoformat(m_closed.group("date"))
            except ValueError:
                continue
            key = (current_class, m_closed.group("page"))
            out[key] = {
                "state": "closed",
                "message": m_closed.group("message"),
                "closed_on": closed_on,
                "by": m_closed.group("by") or "",
            }
            continue
    return out


# ---------------------------------------------------------------------------
# Load incoming findings (stdin or lint_wiki.py subprocess).
# ---------------------------------------------------------------------------


def load_findings(wiki_root: Path, findings_stdin: bool) -> tuple[list, str]:
    """Return `(findings, source)` where findings is a list of dicts with
    at least {class, page, message}, restricted to `TRACKED_CLASSES`.

    `source` is "stdin" or "subprocess" (for the JSON payload's diagnostics).
    """
    if findings_stdin:
        try:
            payload = json.loads(sys.stdin.read())
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"--findings -: invalid JSON on stdin: {exc}") from exc
        # Accept either the bare `{errors, warnings, info}` shape (the original
        # --findings - contract) or a standard `{success, data: {...}}` envelope
        # (cogni-knowledge's build_open_questions_payload.py emits the latter so
        # its own stdout honours the {success, data, error} script convention,
        # #354). A `success: false` envelope is a HARD failure — surfacing it as
        # an exit-1 (which fires the caller's ⚠ surface) is correct, because the
        # alternative (treating its empty `data` as "no findings") would silently
        # close every open item. Defends any future `--findings -` producer too.
        if isinstance(payload, dict) and "success" in payload and "data" in payload:
            if not payload.get("success"):
                raise RuntimeError(
                    f"--findings -: upstream payload reported failure: "
                    f"{payload.get('error', '')}"
                )
            payload = payload.get("data") or {}
        return _flatten(payload), "stdin"

    lint_script = (
        Path(__file__).resolve().parents[2] / "wiki-lint" / "scripts" / "lint_wiki.py"
    )
    if not lint_script.is_file():
        raise RuntimeError(f"lint_wiki.py not found at {lint_script}")
    try:
        proc = subprocess.run(
            [sys.executable, str(lint_script), "--wiki-root", str(wiki_root)],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise RuntimeError(f"lint_wiki.py invocation failed: {exc}") from exc
    if not proc.stdout:
        raise RuntimeError("lint_wiki.py emitted no JSON on stdout")
    try:
        last_line = [ln for ln in proc.stdout.splitlines() if ln.strip()][-1]
        payload = json.loads(last_line)
    except (json.JSONDecodeError, IndexError) as exc:
        raise RuntimeError(f"lint_wiki.py JSON unparseable: {exc}") from exc
    if not payload.get("success"):
        raise RuntimeError(f"lint_wiki.py reported failure: {payload.get('error', '')}")
    return _flatten(payload.get("data") or {}), "subprocess"


def _flatten(payload: dict) -> list:
    """Take a `{errors, warnings, ...}` dict; return entries with a tracked class.

    An entry's identity is `id` (research-time gaps written by cogni-knowledge,
    e.g. `sq:sq-04`) or, as a fallback, `page` (lint findings written by
    `lint_wiki.py`). Either way it is stored under the `page` key so the rest of
    the reconcile/render pipeline is identifier-shape-agnostic (#354).
    """
    out = []
    for bucket in ("errors", "warnings", "info"):
        for ent in payload.get(bucket) or []:
            if not isinstance(ent, dict):
                continue
            cls = ent.get("class")
            ident = ent.get("id") or ent.get("page")
            if cls in TRACKED_CLASSES and ident:
                out.append({
                    "class": cls,
                    "page": ident,
                    "message": ent.get("message", ""),
                })
    return out


# ---------------------------------------------------------------------------
# "Closed by" attribution from wiki/log.md (best-effort).
# ---------------------------------------------------------------------------


def attribute_close(log_path: Path, page_slug: str) -> str:
    """Walk wiki/log.md from the bottom up; return the op of the most
    recent CLOSING_OPS line that names the identifier. Empty string if no
    match (renders as "closed YYYY-MM-DD" only).

    Two identifier shapes, two match rules:
      - lint page slug — substring scan of the line's `rest` (the long-standing
        behaviour; a `## [date] update | <slug> — …` line names the slug inline).
      - research-time gap `sq:<sq_id>` (#354) — the finalize line carries the
        bare ids in an `sqs=sq-04,sq-01` suffix, so we parse that CSV and check
        **exact** membership. Substring matching here would falsely credit
        `sq-04` against `sqs=sq-040,…` (or against an sq_id-shaped fragment in a
        `slug=`/`project=` value), so the exact check is load-bearing.
    """
    if not log_path.is_file():
        return ""
    try:
        text = log_path.read_text(encoding="utf-8")
    except OSError:
        return ""
    is_gap = page_slug.startswith("sq:")
    needle = page_slug[3:] if is_gap else page_slug
    for line in reversed(text.splitlines()):
        m = LOG_LINE_RE.match(line)
        if not m:
            continue
        if m.group("op") not in CLOSING_OPS:
            continue
        rest = m.group("rest")
        if is_gap:
            m_sqs = re.search(r"\bsqs=([^\s|]+)", rest)
            if m_sqs and needle in m_sqs.group(1).split(","):
                return m.group("op")
        elif needle in rest:
            return m.group("op")
    return ""


# ---------------------------------------------------------------------------
# Reconcile: old items + incoming findings → new state.
# ---------------------------------------------------------------------------


def reconcile(
    old: dict,
    incoming: list,
    log_path: Path,
    today: datetime.date,
    skip_trim: bool,
) -> tuple[dict, dict]:
    """Apply the reconciliation algorithm.

    Returns `(new_state, deltas)` where deltas is `{opened, closed, retained,
    trimmed, total, open, closed_visible, opened_by_class, closed_by_class}`.
    """
    incoming_keys = {(f["class"], f["page"]) for f in incoming}
    incoming_msgs = {(f["class"], f["page"]): f["message"] for f in incoming}
    new = dict(old)

    opened = 0
    closed = 0
    trimmed = 0
    # Per-class tallies so consumers can split (e.g. lint vs research, #354).
    opened_by_class: dict = {}
    closed_by_class: dict = {}

    # 1. Old open items no longer in incoming → close.
    for key, item in list(old.items()):
        if item["state"] == "open" and key not in incoming_keys:
            new[key] = {
                "state": "closed",
                "message": item["message"],
                "closed_on": today,
                "by": attribute_close(log_path, key[1]),
            }
            closed += 1
            closed_by_class[key[0]] = closed_by_class.get(key[0], 0) + 1

    # 2. New keys (or previously-closed keys re-appearing) → open.
    for key in incoming_keys:
        prior = old.get(key)
        if prior is None or prior["state"] == "closed":
            new[key] = {
                "state": "open",
                "message": incoming_msgs[key],
            }
            opened += 1
            opened_by_class[key[0]] = opened_by_class.get(key[0], 0) + 1
        else:
            # Refresh the message text from the latest lint output so a
            # changed message (e.g. updated age in a stale_page warning)
            # doesn't drift across runs.
            new[key]["message"] = incoming_msgs[key]

    # 3. Trim closed items older than CLOSED_RETENTION_DAYS.
    if not skip_trim:
        cutoff = today - datetime.timedelta(days=CLOSED_RETENTION_DAYS)
        for key, item in list(new.items()):
            if item["state"] == "closed" and item["closed_on"] < cutoff:
                del new[key]
                trimmed += 1

    open_count = sum(1 for v in new.values() if v["state"] == "open")
    closed_count = sum(1 for v in new.values() if v["state"] == "closed")
    deltas = {
        "opened": opened,
        "closed": closed,
        "retained": open_count + closed_count,
        "trimmed": trimmed,
        "total": len(new),
        "open": open_count,
        "closed_visible": closed_count,
        "opened_by_class": opened_by_class,
        "closed_by_class": closed_by_class,
    }
    return new, deltas


# ---------------------------------------------------------------------------
# Render the canonical markdown.
# ---------------------------------------------------------------------------


def render(state: dict, today: datetime.date) -> str:
    open_count = sum(1 for v in state.values() if v["state"] == "open")
    closed_count = sum(1 for v in state.values() if v["state"] == "closed")

    lines = [CANONICAL_HEADER_COMMENT, "\n"]
    lines.append("# Open questions\n\n")
    lines.append(f"_Generated_: {_now_iso()}  \n")
    lines.append(
        f"_Open_: {open_count}  ·  _Closed (last {CLOSED_RETENTION_DAYS} d)_: {closed_count}\n\n"
    )

    for cls, header in SECTIONS:
        items = [(k, v) for k, v in state.items() if k[0] == cls]
        if not items:
            continue
        # Sort: open items first (alphabetical by page slug), then closed
        # (most recent close first, then alphabetical).
        opens = sorted(
            (kv for kv in items if kv[1]["state"] == "open"),
            key=lambda kv: kv[0][1],
        )
        closeds = sorted(
            (kv for kv in items if kv[1]["state"] == "closed"),
            key=lambda kv: (-(kv[1]["closed_on"].toordinal()), kv[0][1]),
        )
        lines.append(f"## {header}\n\n")
        for (cls2, page), item in opens:
            lines.append(f"- [ ] `{page}` — {item['message']}\n")
        for (cls2, page), item in closeds:
            by = f" by {item['by']}" if item.get("by") else ""
            lines.append(
                f"- [x] ~~`{page}` — {item['message']}~~ — "
                f"closed {item['closed_on'].isoformat()}{by}\n"
            )
        lines.append("\n")

    if open_count == 0 and closed_count == 0:
        lines.append(
            "_No open or recently-closed gaps. The wiki is clean — keep ingesting._\n"
        )

    return "".join(lines)


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rebuild wiki/open_questions.md (cogni-wiki #220)."
    )
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument(
        "--findings",
        choices=["-"],
        default=None,
        help="Read merged findings JSON from stdin (default: invoke lint_wiki.py).",
    )
    parser.add_argument(
        "--skip-trim",
        action="store_true",
        help="Bypass the 90-day closed-retention trim (debug).",
    )
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        emit_json(False, error=f"not a wiki root: {wiki_root}")
        return 1

    fail_if_pre_migration(wiki_root)

    try:
        findings, source = load_findings(wiki_root, findings_stdin=(args.findings == "-"))
    except RuntimeError as exc:
        emit_json(False, error=str(exc))
        return 1

    out_path = _meta_first(wiki_root, "open_questions.md")
    log_path = _meta_first(wiki_root, "log.md")
    today = _today()

    with _wiki_lock(wiki_root):
        old = parse_existing(out_path)
        new_state, deltas = reconcile(old, findings, log_path, today, args.skip_trim)
        text = render(new_state, today)
        try:
            atomic_write(out_path, text)
        except OSError as exc:
            emit_json(False, error=f"atomic_write failed: {exc}")
            return 1

    emit_json(
        True,
        data={
            "path": str(out_path.relative_to(wiki_root)),
            "bytes": len(text.encode("utf-8")),
            "source": source,
            **deltas,
        },
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
