#!/usr/bin/env python3
"""
resweep_planner.py — workspace materialiser and report aggregator for
wiki-claims-resweep.

Two phases, selected via --phase:

    --phase plan       Read extract JSON (from --extract-file or stdin), create the
                       per-day sweep workspace under <wiki-root>/raw/claims-resweep-
                       <YYYY-MM-DD>/, write one claim-manifest markdown per page
                       and index.json, then emit a dispatch plan on stdout. The
                       SKILL hands each manifest to cogni-claims:claims (submit +
                       verify).

    --phase aggregate  Read verification results (from --results-file or stdin) +
                       the workspace dir, write report.md alongside the manifests,
                       and write/refresh <wiki-root>/.cogni-wiki/last-resweep.json
                       (lock-wrapped — last-resweep.json is shared state per the
                       Concurrency Invariant in cogni-wiki/CLAUDE.md). Emit summary
                       stats on stdout.

Boundary: this script writes only to (a) the per-day sweep workspace under
`raw/claims-resweep-<date>/` (isolated, no lock needed) and (b) the lock-wrapped
`.cogni-wiki/last-resweep.json`. It never touches the per-type page dirs, `wiki/index.md`,
or `.cogni-wiki/config.json` — page mutations are out of scope (report-only by
design; user runs wiki-update manually if they want stale markers).

stdlib-only, Python 3.8+. Output contract for plan phase:

    {
      "success": true,
      "data": {
        "workspace": "<abs path>",
        "workspace_rel": "raw/claims-resweep-<date>",
        "sweep_date": "YYYY-MM-DD",
        "plan": [
          {
            "slug": "<page-slug>",
            "manifest": "raw/claims-resweep-<date>/<slug>-claims.md",
            "claim_count": <int>,
            "source_count": <int>
          }
        ],
        "stats": {
          "pages": <int>,
          "total_claims": <int>,
          "total_unique_sources": <int>
        }
      },
      "error": ""
    }

For aggregate phase, output adds report_path, last_resweep_path, and per-status
counts.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fcntl
import json
import os
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


@contextmanager
def _wiki_lock(wiki_root: Path):
    """Mirror of wiki_index_update.py::_wiki_lock — same advisory lock so this
    script participates in the existing concurrency contract for shared state."""
    lock_dir = wiki_root / ".cogni-wiki"
    lock_dir.mkdir(parents=True, exist_ok=True)
    lock_path = lock_dir / ".lock"
    fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            os.close(fd)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def _yaml_escape(s: str) -> str:
    if any(c in s for c in ":#\n\"'"):
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return s


def render_manifest(page: dict, sweep_date: str) -> str:
    lines = [
        "---",
        f"page_slug: {page['slug']}",
        f"page_title: {_yaml_escape(page.get('title', page['slug']))}",
        f"sweep_date: {sweep_date}",
        f"claim_count: {len(page['claims'])}",
        f"source_count: {len({c['source_url'] for c in page['claims']})}",
        f"page_updated: {page.get('updated', '')}",
        "---",
        "",
        f"# Claims to re-verify — {page.get('title', page['slug'])}",
        "",
        f"Page: `{page.get('page_path') or page['slug']}`",
        f"Sweep: {sweep_date}",
        "",
        "## Claims",
        "",
    ]
    for i, c in enumerate(page["claims"], 1):
        lines.append(f"### Claim {i}")
        lines.append("")
        lines.append(f"- **statement**: {c['statement']}")
        lines.append(f"- **source_url**: {c['source_url']}")
        lines.append(f"- **source_title**: {c.get('source_title', '')}")
        lines.append(f"- **page_line**: {c.get('line', 0)}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def phase_plan(args) -> None:
    extract = load_json(args.extract_file)
    if not extract.get("success"):
        fail(f"extract input not successful: {extract.get('error', 'unknown')}")
    data = extract.get("data", {})
    wiki_root = Path(data.get("wiki_root", "")).resolve()
    if not wiki_root.is_dir():
        fail(f"extract.wiki_root not a directory: {wiki_root}")
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"extract.wiki_root is not a cogni-wiki: {wiki_root}")

    pages = data.get("pages", []) or []
    if not pages:
        ok({
            "workspace": "",
            "workspace_rel": "",
            "sweep_date": dt.date.today().isoformat(),
            "plan": [],
            "stats": {"pages": 0, "total_claims": 0, "total_unique_sources": 0},
        })

    sweep_date = args.date or dt.date.today().isoformat()
    workspace = wiki_root / "raw" / f"claims-resweep-{sweep_date}"
    workspace.mkdir(parents=True, exist_ok=True)

    plan: list[dict] = []
    unique_sources: set = set()
    for page in pages:
        if not page.get("claims"):
            continue
        manifest_path = workspace / f"{page['slug']}-claims.md"
        atomic_write(manifest_path, render_manifest(page, sweep_date))
        for c in page["claims"]:
            unique_sources.add(c["source_url"])
        plan.append({
            "slug": page["slug"],
            "manifest": str(manifest_path.relative_to(wiki_root)),
            "manifest_abs": str(manifest_path),
            "claim_count": len(page["claims"]),
            "source_count": len({c["source_url"] for c in page["claims"]}),
            "page_path": page.get("page_path") or page["slug"],
            "age_days": page.get("age_days"),
        })

    index_path = workspace / "index.json"
    atomic_write(index_path, json.dumps({
        "sweep_date": sweep_date,
        "mode": data.get("mode", "all"),
        "wiki_root": str(wiki_root),
        "pages": [
            {k: v for k, v in entry.items() if k != "manifest_abs"}
            for entry in plan
        ],
        "stats": {
            "pages": len(plan),
            "total_claims": sum(p["claim_count"] for p in plan),
            "total_unique_sources": len(unique_sources),
        },
    }, indent=2) + "\n")

    ok({
        "workspace": str(workspace),
        "workspace_rel": f"raw/claims-resweep-{sweep_date}",
        "sweep_date": sweep_date,
        "plan": plan,
        "stats": {
            "pages": len(plan),
            "total_claims": sum(p["claim_count"] for p in plan),
            "total_unique_sources": len(unique_sources),
        },
    })


def render_report(results: dict, plan_index: dict, sweep_date: str) -> str:
    pages_results = results.get("pages", [])
    totals = {"verified": 0, "deviated": 0, "source_unavailable": 0, "unverified": 0}
    for p in pages_results:
        for c in p.get("claims", []):
            status = c.get("status", "unverified")
            totals[status] = totals.get(status, 0) + 1

    deviated_pages = [p["slug"] for p in pages_results
                      if any(c.get("status") == "deviated" for c in p.get("claims", []))]
    unavailable_pages = [p["slug"] for p in pages_results
                         if any(c.get("status") == "source_unavailable" for c in p.get("claims", []))]

    lines = [
        "---",
        f"sweep_date: {sweep_date}",
        f"mode: {plan_index.get('mode', 'all')}",
        f"total_pages: {len(pages_results)}",
        f"total_claims: {sum(totals.values())}",
        f"verified: {totals['verified']}",
        f"deviated: {totals['deviated']}",
        f"source_unavailable: {totals['source_unavailable']}",
        f"unverified: {totals['unverified']}",
        "---",
        "",
        f"# Wiki claims re-verify sweep — {sweep_date}",
        "",
        "Pages were not modified. Run `wiki-update` manually for any page where you want to add a `## Stale (date)` marker.",
        "",
        "## Summary",
        "",
        f"- Pages scanned: {len(pages_results)}",
        f"- Total claims checked: {sum(totals.values())}",
        f"- Verified: {totals['verified']}",
        f"- Deviated: {totals['deviated']} (across {len(deviated_pages)} pages)",
        f"- Source unavailable: {totals['source_unavailable']} (across {len(unavailable_pages)} pages)",
        "",
    ]

    flagged = [p for p in pages_results
               if any(c.get("status") in ("deviated", "source_unavailable") for c in p.get("claims", []))]
    if flagged:
        lines.append("## Pages with findings")
        lines.append("")
        for p in flagged:
            lines.append(f"### {p['slug']}")
            lines.append("")
            for c in p.get("claims", []):
                status = c.get("status", "unverified")
                if status not in ("deviated", "source_unavailable"):
                    continue
                lines.append(f"- **status**: {status}")
                lines.append(f"  - statement: {c.get('statement', '')}")
                lines.append(f"  - source: {c.get('source_url', '')}")
                for d in c.get("deviations", []) or []:
                    lines.append(f"  - deviation: {d.get('type', '?')} ({d.get('severity', '?')}) — {d.get('explanation', '')}")
                    excerpt = d.get("source_excerpt", "")
                    if excerpt:
                        lines.append(f"    excerpt: {excerpt[:200]}")
            lines.append("")
    else:
        lines.append("No deviated or unavailable claims. Wiki citations are healthy as of this sweep.")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def phase_aggregate(args) -> None:
    results = load_json(args.results_file)
    if not results.get("success"):
        fail(f"results input not successful: {results.get('error', 'unknown')}")
    rdata = results.get("data", {})

    workspace = Path(args.workspace).resolve()
    if not workspace.is_dir():
        fail(f"workspace not a directory: {workspace}")
    index_path = workspace / "index.json"
    if not index_path.is_file():
        fail(f"workspace missing index.json: {index_path}")

    plan_index = json.loads(index_path.read_text(encoding="utf-8"))
    wiki_root = Path(plan_index.get("wiki_root", "")).resolve()
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"index.wiki_root no longer a cogni-wiki: {wiki_root}")
    sweep_date = plan_index.get("sweep_date", dt.date.today().isoformat())

    report_path = workspace / "report.md"
    atomic_write(report_path, render_report(rdata, plan_index, sweep_date))

    deviated_pages = sorted({
        p["slug"] for p in rdata.get("pages", [])
        if any(c.get("status") == "deviated" for c in p.get("claims", []))
    })
    unavailable_pages = sorted({
        p["slug"] for p in rdata.get("pages", [])
        if any(c.get("status") == "source_unavailable" for c in p.get("claims", []))
    })

    last_resweep = {
        "sweep_date": sweep_date,
        "mode": plan_index.get("mode", "all"),
        "deviated_pages": deviated_pages,
        "unavailable_pages": unavailable_pages,
        "report_path": str(report_path.relative_to(wiki_root)),
    }
    last_path = wiki_root / ".cogni-wiki" / "last-resweep.json"
    with _wiki_lock(wiki_root):
        atomic_write(last_path, json.dumps(last_resweep, indent=2) + "\n")

    totals = {"verified": 0, "deviated": 0, "source_unavailable": 0, "unverified": 0}
    for p in rdata.get("pages", []):
        for c in p.get("claims", []):
            status = c.get("status", "unverified")
            totals[status] = totals.get(status, 0) + 1

    ok({
        "report_path": str(report_path.relative_to(wiki_root)),
        "last_resweep_path": str(last_path.relative_to(wiki_root)),
        "sweep_date": sweep_date,
        "deviated_pages": deviated_pages,
        "unavailable_pages": unavailable_pages,
        "stats": {
            "total_pages": len(rdata.get("pages", [])),
            "total_claims": sum(totals.values()),
            **totals,
        },
    })


def load_json(path_arg: str | None) -> dict:
    if not path_arg or path_arg == "-":
        try:
            return json.loads(sys.stdin.read())
        except json.JSONDecodeError as e:
            fail(f"stdin is not valid JSON: {e}")
    p = Path(path_arg).expanduser()
    if not p.is_file():
        fail(f"file not found: {p}")
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        fail(f"{p}: invalid JSON ({e})")
    return {}  # unreachable


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Materialise sweep workspace and aggregate verification results.")
    parser.add_argument("--phase", choices=("plan", "aggregate"), required=True)
    parser.add_argument("--extract-file", help="Path to extract_page_claims.py JSON output (or '-' for stdin). Plan phase.")
    parser.add_argument("--results-file", help="Path to verification-results JSON (or '-' for stdin). Aggregate phase.")
    parser.add_argument("--workspace", help="Sweep workspace dir (raw/claims-resweep-<date>). Aggregate phase.")
    parser.add_argument("--date", help="Override sweep date (YYYY-MM-DD). Plan phase only.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.phase == "plan":
        if not args.extract_file:
            args.extract_file = "-"
        phase_plan(args)
    else:
        if not args.workspace:
            fail("--workspace is required for --phase aggregate")
        if not args.results_file:
            args.results_file = "-"
        phase_aggregate(args)


if __name__ == "__main__":
    main()
