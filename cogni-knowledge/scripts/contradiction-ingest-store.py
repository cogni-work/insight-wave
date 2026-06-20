#!/usr/bin/env python3
"""
contradiction-ingest-store.py — merge the per-group `source-contradictor`
fragments emitted by the `knowledge-ingest` Step 4.6 ingest-time contradiction
tripwire into one canonical `contradiction-ingest.json`.

Step 4.6 fans `source-contradictor` out — one dispatch per qualifying question
group (a sub-question's answering sources, split into the new-this-run sources
and the prior-run peers). Each dispatch writes its own per-group fragment
(`.metadata/.contradiction-ingest.<question-slug>.json`). This script is the
fan-in plumbing: the LLM judgment stays in the agent, this script only
re-combines, re-ids the findings globally, recomputes the aggregate counts, and
asserts the count invariants — exactly the `verify-store.py merge` posture.

Each finding's optional `resolution {survivor_claim_id, strategy: "recency",
rationale}` annotation (the zero-network recency-survivor suggestion the
`source-contradictor` agent attaches to a `contradiction` finding) is an **opaque
passthrough**: `merge` preserves the whole finding dict verbatim except for the
global `ctr-NNN` id re-write, so `resolution{}` (and any other additive finding
key) survives byte-identically. The script reads it in exactly one place —
`_resolution_coverage`, which reports the share of contradictions carrying a
non-null survivor suggestion (`data.resolution_coverage` + a top-level
`resolution_coverage` block on the canonical file) so the `knowledge-ingest`
Step 6 summary can surface it alongside an explicit low-recall floor; it never
gates, scores, or rewrites a finding.

  init   Write an empty canonical `contradiction-ingest.json` (no findings,
         zeroed counts, no groups). Lets the orchestrator stamp a clean artifact
         on a run that ends up with zero qualifying groups.
  merge  Read each per-group fragment (a `source-contradictor` envelope), splice
         their findings into one `findings[]` re-id'd `ctr-001..`, recompute the
         aggregate `counts`, assert the count invariants, record one
         `groups_compared[]` row per fragment, and atomic-write the canonical
         file (overwritten on re-ingest — idempotent, the same posture
         `knowledge-finalize` uses overwriting `contradictor-vN.json`).

This is a pure-observability artifact: it never gates ingest, never rolls back a
page, drives no downstream behaviour. A malformed / unreadable / schema-mismatched
fragment is skipped (recorded in `data.skipped_shards[]`), and a single out-of-vocab
finding (unknown `kind`/`severity`) is dropped + recorded (`data.skipped_findings[]`)
rather than failing the count invariants — both so a tripwire hiccup in one fragment
can never lose every other group's valid findings from observability. The ingested
pages already landed at Step 3, so a tripwire hiccup must never fail the run.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import glob as globmod
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import atomic_write  # noqa: E402

SCHEMA_VERSION = "0.1.0"
KINDS = ("contradiction", "unknown")
SEVERITIES = ("high", "medium", "low")


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _zero_counts() -> dict:
    return {"contradiction": 0, "unknown": 0, "total": 0, "high": 0, "medium": 0, "low": 0}


def _finding_valid(f: dict) -> bool:
    """A finding is in-vocab when its `kind` is known and a `contradiction`
    carries a known `severity` (an `unknown` carries none). The agent emits a
    closed vocabulary, but a single out-of-vocab finding must not be able to
    fail the count invariants and abort the whole merge — for a pure-observability
    fan-in, an invalid finding is dropped + recorded, never a reason to lose every
    other group's valid findings."""
    kind = f.get("kind")
    if kind not in KINDS:
        return False
    if kind == "contradiction" and f.get("severity") not in SEVERITIES:
        return False
    return True


def _recompute_counts(findings: list[dict]) -> dict:
    counts = _zero_counts()
    for f in findings:
        kind = f.get("kind")
        if kind in KINDS:
            counts[kind] += 1
        if kind == "contradiction":
            sev = f.get("severity")
            if sev in SEVERITIES:
                counts[sev] += 1
    counts["total"] = len(findings)
    return counts


def _assert_invariants(counts: dict) -> str:
    """Return an error string on a violated invariant, else ''."""
    if counts["total"] != counts["contradiction"] + counts["unknown"]:
        return (
            "count invariant violated: total != contradiction + unknown "
            f"({counts['total']} != {counts['contradiction']} + {counts['unknown']})"
        )
    if counts["contradiction"] != counts["high"] + counts["medium"] + counts["low"]:
        return (
            "count invariant violated: contradiction != high + medium + low "
            f"({counts['contradiction']} != {counts['high']} + {counts['medium']} + {counts['low']})"
        )
    return ""


def _resolution_coverage(findings: list[dict]) -> dict:
    """Share of `contradiction` findings carrying a non-null recency-survivor
    suggestion (`resolution.survivor_claim_id`), reported alongside an explicit
    low-recall floor by the readers. The `resolution{}` annotation is additive on
    schema 0.1.0 and an opaque passthrough through the merge (see module
    docstring); this is the only place that reads it — purely to surface coverage,
    never to gate or rewrite anything. A contradiction whose both sides carried no
    timestamp (`survivor_claim_id: null`), or a fragment from a pre-annotation
    agent (no `resolution` key), counts as uncovered."""
    contradictions = [f for f in findings if f.get("kind") == "contradiction"]
    resolved = sum(
        1
        for f in contradictions
        if isinstance(f.get("resolution"), dict) and f["resolution"].get("survivor_claim_id")
    )
    total = len(contradictions)
    pct = round(100.0 * resolved / total, 1) if total else 0.0
    return {"resolved": resolved, "contradictions": total, "pct": pct}


def _canonical(output_language: str, groups: list[dict], findings: list[dict], counts: dict) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "output_language": output_language,
        "groups_compared": groups,
        "findings": findings,
        "counts": counts,
        "resolution_coverage": _resolution_coverage(findings),
    }


def cmd_init(args: argparse.Namespace) -> int:
    out_path = Path(args.out).resolve()
    payload = _canonical(args.output_language, [], [], _zero_counts())
    atomic_write(out_path, payload)
    return _emit(True, data={"out_path": str(out_path), "groups_compared": 0, "counts": payload["counts"]})


def _resolve_shards(spec: str) -> list[Path]:
    """Accept a glob, or a comma-separated list of paths/globs. Sorted, de-duped."""
    paths: list[Path] = []
    seen: set[str] = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        # A literal path with no glob metacharacters still works through glob().
        for hit in sorted(globmod.glob(part)):
            rp = str(Path(hit).resolve())
            if rp not in seen:
                seen.add(rp)
                paths.append(Path(rp))
    return paths


def cmd_merge(args: argparse.Namespace) -> int:
    out_path = Path(args.out).resolve()
    shard_paths = _resolve_shards(args.shards)

    findings: list[dict] = []
    groups: list[dict] = []
    skipped: list[dict] = []
    skipped_findings: list[dict] = []

    # Deterministic order: by question_slug, so the global ctr-NNN re-id is stable
    # across re-runs that compare the same groups. A fragment that fails to parse
    # or carries the wrong schema is skipped (fail-soft) — never aborts the merge.
    parsed: list[tuple[str, dict]] = []
    for sp in shard_paths:
        try:
            frag = json.loads(sp.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            skipped.append({"shard": sp.name, "reason": f"unreadable: {exc}"})
            continue
        if not isinstance(frag, dict):
            skipped.append({"shard": sp.name, "reason": "top-level is not a JSON object"})
            continue
        if frag.get("schema_version") != SCHEMA_VERSION:
            skipped.append({"shard": sp.name, "reason": f"schema_version != {SCHEMA_VERSION}"})
            continue
        if not isinstance(frag.get("findings"), list):
            skipped.append({"shard": sp.name, "reason": "missing findings list"})
            continue
        qslug = frag.get("question_slug") or sp.stem
        parsed.append((str(qslug), frag))

    parsed.sort(key=lambda t: t[0])

    for qslug, frag in parsed:
        compared = frag.get("compared") or {}
        frag_valid: list[dict] = []
        for f in frag["findings"]:
            if not isinstance(f, dict):
                skipped_findings.append({"question_slug": qslug, "reason": "non-object finding"})
                continue
            if not _finding_valid(f):
                skipped_findings.append({
                    "question_slug": qslug,
                    "reason": f"out-of-vocab kind/severity: kind={f.get('kind')!r} severity={f.get('severity')!r}",
                })
                continue
            frag_valid.append(f)
        groups.append({
            "question_slug": qslug,
            "new_count": compared.get("new_count", 0),
            "peer_count": compared.get("peer_count", 0),
            "finding_count": len(frag_valid),
            "missing_pages": compared.get("missing_pages", []),
        })
        findings.extend(frag_valid)

    # Global re-id ctr-001.. (the per-fragment ids are local to each agent run and
    # collide across groups; the canonical file owns the one stable join key).
    for i, f in enumerate(findings, start=1):
        f["id"] = f"ctr-{i:03d}"

    counts = _recompute_counts(findings)
    inv_err = _assert_invariants(counts)
    if inv_err:
        return _emit(False, error=inv_err)

    payload = _canonical(args.output_language, groups, findings, counts)
    atomic_write(out_path, payload)
    return _emit(True, data={
        "out_path": str(out_path),
        "groups_compared": len(groups),
        "shards_merged": len(parsed),
        "skipped_shards": skipped,
        "skipped_findings": skipped_findings,
        "counts": counts,
        "resolution_coverage": _resolution_coverage(findings),
    })


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Merge per-group source-contradictor fragments into contradiction-ingest.json",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init", help="Write an empty canonical contradiction-ingest.json")
    p_init.add_argument("--out", required=True, help="Path to the canonical contradiction-ingest.json")
    p_init.add_argument("--output-language", default="en", help="Output language tag (default en)")
    p_init.set_defaults(func=cmd_init)

    p_merge = sub.add_parser("merge", help="Merge per-group fragments into contradiction-ingest.json")
    p_merge.add_argument(
        "--shards", required=True,
        help="Glob or comma-separated list of per-group fragment paths",
    )
    p_merge.add_argument("--out", required=True, help="Path to the canonical contradiction-ingest.json")
    p_merge.add_argument("--output-language", default="en", help="Output language tag (default en)")
    p_merge.set_defaults(func=cmd_merge)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
