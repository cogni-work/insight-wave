#!/usr/bin/env python3
"""Deterministic stand-in for a host presentation skill used by test-platform-route.sh."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path


def digest(path):
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()


parser = argparse.ArgumentParser()
parser.add_argument("--target", choices=("html", "pptx"), required=True)
parser.add_argument("--out", required=True)
parser.add_argument("--root", required=True)
parser.add_argument("--composition", required=True)
parser.add_argument("--attempt", type=int, default=1)
parser.add_argument("--fail-until", type=int, default=0)
args = parser.parse_args()

if args.attempt <= args.fail_until:
    print(json.dumps({"success": False, "data": {"attempt": args.attempt, "findings": [
        {"code": "stub-open-finding", "unit": "u-answer", "message": "fixed stub finding"}
    ]}, "error": "verification_failed"}))
    raise SystemExit(1)

root = Path(args.root)
out = Path(args.out)
out.mkdir(parents=True, exist_ok=True)
name = "index.html" if args.target == "html" else "deck.pptx"
source = root / "docs" / "design-verify-proof" / "boardroom" / args.target / name
artifact = out / name
shutil.copyfile(source, artifact)
composition_path = out / "composition.json"
shutil.copyfile(args.composition, composition_path)
brief_path = out / "brief.json"
shutil.copyfile(root / "tests/fixtures/verify/direct-proof-v1.normalized.json", brief_path)
theme_path = out / "theme.json"
shutil.copyfile(root / "themes/boardroom/tokens/colors.json", theme_path)
host_path = out / "host.json"
host_path.write_text(json.dumps({"host": "offline-test", "skill": "test-platform-stub", "live": False}) + "\n")
composition = json.loads(composition_path.read_text(encoding="utf-8"))
fingerprint = composition["normalized_brief_ref"]["content_fingerprint"]
unit_ids = [unit["id"] for unit in composition["units"]]
review = out / "review-record.json"
review.write_text(json.dumps({"fixture": True, "findings": []}, indent=2) + "\n", encoding="utf-8")
provenance = {
    "artifact_type": "render-provenance",
    "artifact_version": "1",
    "artifact_id": f"platform-stub:{args.target}",
    "renderer": {"kind": "platform", "name": "test-platform-stub", "version": "test-fixture",
                 "target": args.target, "host": "offline-test"},
    "design_system": composition["design_system"],
    "inputs": {key: {"path": path.name, "sha256": digest(path)}
               for key, path in (("brief", brief_path), ("composition", composition_path), ("theme", theme_path))},
    "content_fingerprint": fingerprint,
    "outputs": {"artifact": {"path": name, "sha256": digest(artifact)}},
    "reproducible": False,
    "live_proof": False,
    "run": {"id": f"stub-{args.target}-{args.attempt}", "host": "offline-test",
            "skill": "test-platform-stub", "live": False,
            "evidence": {"path": host_path.name, "sha256": digest(host_path)}},
    "attempts": [{"attempt": args.attempt, "findings": [], "preserve": {"differences": []},
                  "content_fingerprint_before": fingerprint, "content_fingerprint_after": fingerprint,
                  "unit_ids_before": unit_ids, "unit_ids_after": unit_ids}],
    "review": {"path": "review-record.json", "sha256": digest(review), "open_findings": [],
               "coverage": {"all_units": True, "all_slides": True, "overview": True}},
    "applicability": {
        "theme": {"applicable": True, "reason": "Fixed boardroom fixture", "evidence": [{"path": theme_path.name, "sha256": digest(theme_path)}]},
        "fonts": {"applicable": False, "reason": "Admission fixture copies an existing artifact", "evidence": []},
        "runtime": {"applicable": False, "reason": "No host skill runs in this offline admission test", "evidence": []},
    },
}
(out / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"success": True, "data": {"attempt": args.attempt, "artifact": str(artifact),
                                              "provenance": str(out / "provenance.json")}, "error": None}))
