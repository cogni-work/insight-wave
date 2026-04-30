#!/usr/bin/env python3
"""refresh-region-catalog-baseline.py — regenerate the drift baseline file.

Runs `check-region-catalogs.sh` against the current catalogs, snapshots the
current Bucket A/B per-market findings, and writes them as the new baseline
file. Default mode prints a unified diff vs the existing baseline; `--write`
applies.

This script intentionally does NOT auto-run after each audit. The baseline
represents the agreed-intentional drift snapshot and humans curate it — usually
after a `manage-markets promote` PR merges (which legitimately shrinks the
agreed-drift set) or after `manage-markets add` adds a new market with curated
authority sources.

Output: single-line JSON envelope `{success, data, error}` on the final line.
"""
import argparse
import datetime
import difflib
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
AUDIT = REPO_ROOT / "cogni-workspace/scripts/check-region-catalogs.sh"
BASELINE = REPO_ROOT / "cogni-workspace/scripts/baselines/region-catalog-drift-baseline.json"

DOC = (
    "Agreed-intentional drift snapshot for cogni-workspace region catalogs. "
    "Captures the per-market Bucket A and Bucket B findings that today represent "
    "legitimate plugin-specific curation (cogni-trends carries global consultancies "
    "like mckinsey.com / deloitte.com for digitales-fundament; cogni-research carries "
    "the deeper regional regulator/statistics tail). "
    "check-region-catalogs.sh --baseline <this-file> emits deltas_vs_baseline; "
    "/cogni-workspace:manage-markets baseline-refresh regenerates this file "
    "after intentional curation. Do NOT auto-regenerate — humans curate this list."
)


def load_json(path):
    with open(path) as f:
        return json.load(f)


def dump_json(obj, path):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")


def run_audit():
    """Run check-region-catalogs.sh and return the parsed envelope."""
    res = subprocess.run(
        ["bash", str(AUDIT)],
        capture_output=True, text=True, check=False,
    )
    # The script prints human-readable lines first, then a single-line JSON
    # envelope on the last line.
    if not res.stdout.strip():
        raise RuntimeError(f"audit produced no stdout (exit {res.returncode}): {res.stderr}")
    last_line = res.stdout.strip().splitlines()[-1]
    return json.loads(last_line)


def render_diff(old_text, new_text):
    return "\n".join(difflib.unified_diff(
        old_text.splitlines(),
        new_text.splitlines(),
        fromfile=str(BASELINE.relative_to(REPO_ROOT)),
        tofile=str(BASELINE.relative_to(REPO_ROOT)),
        lineterm="",
    ))


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("--write", action="store_true",
                        help="apply changes (default: preview)")
    parser.add_argument("--quiet", action="store_true",
                        help="suppress diff body (JSON envelope still emitted)")
    args = parser.parse_args()

    try:
        env = run_audit()
    except Exception as e:
        print(json.dumps({"success": False, "data": {}, "error": f"audit failed: {e}"}))
        return 2

    info = (env.get("data") or {}).get("info_findings") or {}
    new_baseline = {
        "_doc": DOC,
        "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "bucket_a_findings": info.get("bucket_a_findings", {"per_market": {}, "summary": {}}),
        "bucket_b_findings": info.get("bucket_b_findings", {"per_market": {}, "summary": {}}),
    }

    if BASELINE.exists():
        old_text = BASELINE.read_text()
    else:
        old_text = ""
    new_text = json.dumps(new_baseline, indent=2, sort_keys=True, ensure_ascii=False) + "\n"

    if not args.quiet:
        diff = render_diff(old_text, new_text)
        if diff:
            print(diff)
        else:
            print("(no changes — current baseline matches live audit findings)")
        print()

    if args.write:
        dump_json(new_baseline, BASELINE)
        action = "wrote new baseline"
    else:
        action = "preview only — use --write to apply"

    envelope = {
        "success": True,
        "data": {
            "bucket_a_markets": len(new_baseline["bucket_a_findings"].get("per_market", {})),
            "bucket_b_markets": len(new_baseline["bucket_b_findings"].get("per_market", {})),
            "summary": action,
        },
        "error": "",
    }
    print(action)
    print(json.dumps(envelope))
    return 0


if __name__ == "__main__":
    sys.exit(main())
