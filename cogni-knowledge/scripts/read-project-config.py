#!/usr/bin/env python3
"""
read-project-config.py — read a single field from a cogni-research project's
`.metadata/project-config.json`.

Replaces the `python3 -c "import json; print(json.load(open(...)).get(...))"`
shellouts in `knowledge-research` Step 3 and `knowledge-report` Step 5. Both
call sites read the same `report_source` field with a `web` default; isolating
the read path here makes the contract testable and stops the two skills'
shellouts from drifting apart.

Input:
  --project-path  absolute or cwd-relative path to a cogni-research project
                  directory (the parent of `.metadata/project-config.json`)
  --field         field name to read (default: report_source)
  --default       value returned if the field is absent OR the config file
                  does not exist (default: web)

Output (insight-wave envelope):
  {"success": bool, "data": {"field": "...", "value": "..."}, "error": "..."}

Behaviour:
  Missing config file → success=true, data.value=<default> (matches the
    previous shellout's KeyError fallback semantics).
  Missing field with valid JSON → success=true, data.value=<default>.
  Malformed JSON → success=false with the decoder's error message.
  Missing project-path argument → argparse error.

Stdlib only. Read-only — never writes.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_CONFIG_RELPATH = ".metadata/project-config.json"


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read a single field from a cogni-research project's .metadata/project-config.json.",
        allow_abbrev=False,
    )
    parser.add_argument("--project-path", required=True)
    parser.add_argument("--field", default="report_source")
    parser.add_argument("--default", default="web")
    args = parser.parse_args(argv)

    project_path = Path(args.project_path).resolve()
    cfg = project_path / PROJECT_CONFIG_RELPATH

    if not cfg.is_file():
        # Same semantics as the shellout: missing file falls back to the
        # default. The caller decides whether that's a problem.
        return _emit(True, data={"field": args.field, "value": args.default})

    try:
        payload = json.loads(cfg.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"project-config.json is not valid JSON at {cfg}: {exc}")
    except OSError as exc:
        return _emit(False, error=f"could not read {cfg}: {exc}")

    value = payload.get(args.field, args.default)
    return _emit(True, data={"field": args.field, "value": value})


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
