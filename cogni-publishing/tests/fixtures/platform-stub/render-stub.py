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
composition = json.loads(Path(args.composition).read_text(encoding="utf-8"))
provenance = {
    "artifact_type": "render-provenance",
    "artifact_version": "1",
    "artifact_id": f"platform-stub:{args.target}",
    "renderer": {"kind": "platform", "name": "test-platform-stub", "version": "test-fixture", "target": args.target},
    "design_system": composition["design_system"],
    "content_fingerprint": composition["normalized_brief_ref"]["content_fingerprint"],
    "outputs": {"artifact": {"path": name, "sha256": digest(artifact)}},
    "reproducible": False,
}
(out / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"success": True, "data": {"attempt": args.attempt, "artifact": str(artifact),
                                              "provenance": str(out / "provenance.json")}, "error": None}))
