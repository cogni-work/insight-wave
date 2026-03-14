#!/usr/bin/env python3
"""
scan_resumption_state.py
Version: 1.0.0
Purpose: Scan filesystem to determine resumption state for batch processing phases
Category: validation

Answers "what work items are already done?" for Phase 3 (findings) or Phase 7 (claims).
Uses existing entity frontmatter (batch_ref, question_ref, finding_refs) as state —
no new tracking infrastructure needed.

Usage:
    scan_resumption_state.py --project-path <path> --phase <3|7> [--json]

Arguments:
    --project-path <path>  Project directory path (required)
    --phase <3|7>          Phase to scan (required)
    --json                 Output JSON format (optional flag, always JSON)

Output (JSON):
    Phase 3:
    {
        "success": true,
        "phase": 3,
        "total_questions": 46,
        "completed_questions": 30,
        "pending_questions": ["question-foo-abc123", ...],
        "completed_question_ids": ["question-bar-def456", ...],
        "recommendation": "FULL_RUN" | "RESUME" | "COMPLETE"
    }

    Phase 7:
    {
        "success": true,
        "phase": 7,
        "total_findings": 120,
        "completed_findings": 80,
        "pending_finding_ids": ["finding-foo-abc123", ...],
        "pending_finding_paths": ["/path/to/finding-foo-abc123.md", ...],
        "recommendation": "FULL_RUN" | "RESUME" | "COMPLETE"
    }

Exit codes:
    0 - Success (COMPLETE or RESUME or FULL_RUN)
    1 - Error (invalid path, missing directories)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set


# ---------------------------------------------------------------------------
# Entity schema resolution (lightweight — reads config/entity-schema.json)
# ---------------------------------------------------------------------------

def load_entity_schema(plugin_root: Optional[str] = None) -> dict:
    """Load entity-schema.json and return key -> directory mapping."""
    candidates = []

    if plugin_root:
        candidates.append(Path(plugin_root) / "config" / "entity-schema.json")

    # Resolve from script location
    script_dir = Path(__file__).resolve().parent
    candidates.append(script_dir.parent / "config" / "entity-schema.json")

    for candidate in candidates:
        if candidate.is_file():
            with open(candidate) as f:
                schema = json.load(f)
            mapping = {}
            for et in schema.get("entity_types", []):
                mapping[et["key"]] = {
                    "directory": et["directory"],
                    "data_subdir": et.get("data_subdir", "data"),
                    "prefix": et.get("prefix", ""),
                }
            return mapping

    # Hardcoded fallback (always works)
    return {
        "refined-questions": {"directory": "02-refined-questions", "data_subdir": "data", "prefix": "question"},
        "query-batches": {"directory": "03-query-batches", "data_subdir": "data", "prefix": "batch"},
        "findings": {"directory": "04-findings", "data_subdir": "data", "prefix": "finding"},
        "claims": {"directory": "10-claims", "data_subdir": "data", "prefix": "claim"},
    }


def get_entity_dir(schema: dict, key: str, project_path: str) -> Path:
    """Resolve entity data directory path."""
    info = schema[key]
    subdir = info["data_subdir"] or ""
    if subdir:
        return Path(project_path) / info["directory"] / subdir
    return Path(project_path) / info["directory"]


# ---------------------------------------------------------------------------
# Frontmatter parsing (minimal — extracts specific fields)
# ---------------------------------------------------------------------------

def extract_frontmatter_field(filepath: Path, field: str) -> Optional[str]:
    """Extract a single field value from YAML frontmatter."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            in_frontmatter = False
            for line in f:
                stripped = line.strip()
                if stripped == "---":
                    if in_frontmatter:
                        return None  # End of frontmatter, field not found
                    in_frontmatter = True
                    continue
                if in_frontmatter and stripped.startswith(f"{field}:"):
                    value = stripped[len(field) + 1:].strip()
                    # Remove quotes
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    if value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]
                    return value
    except (OSError, UnicodeDecodeError):
        pass
    return None


def extract_frontmatter_array(filepath: Path, field: str) -> List[str]:
    """Extract a YAML array field from frontmatter (e.g., finding_refs)."""
    results = []
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            in_frontmatter = False
            in_field = False
            for line in f:
                stripped = line.strip()
                if stripped == "---":
                    if in_frontmatter:
                        break  # End of frontmatter
                    in_frontmatter = True
                    continue
                if not in_frontmatter:
                    continue

                if stripped.startswith(f"{field}:"):
                    # Check for inline array: finding_refs: [a, b]
                    value = stripped[len(field) + 1:].strip()
                    if value.startswith("["):
                        # Inline array
                        inner = value.strip("[]")
                        for item in inner.split(","):
                            item = item.strip().strip('"').strip("'")
                            if item:
                                results.append(item)
                        return results
                    in_field = True
                    continue

                if in_field:
                    if stripped.startswith("- "):
                        item = stripped[2:].strip().strip('"').strip("'")
                        if item:
                            results.append(item)
                    elif stripped and not stripped.startswith("-"):
                        # New field started
                        break
    except (OSError, UnicodeDecodeError):
        pass
    return results


# ---------------------------------------------------------------------------
# Wikilink extraction helpers
# ---------------------------------------------------------------------------

WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")


def extract_entity_id_from_wikilink(wikilink: str) -> str:
    """Extract bare entity ID from a wikilink value.

    Handles:
      - [[02-refined-questions/data/question-foo-abc123]] -> question-foo-abc123
      - [[question-foo-abc123]] -> question-foo-abc123
      - "[[question-foo-abc123]]" -> question-foo-abc123
      - question-foo-abc123 -> question-foo-abc123 (bare ID)
    """
    match = WIKILINK_RE.search(wikilink)
    if match:
        inner = match.group(1)
        # Take last path component
        return inner.rsplit("/", 1)[-1]
    # Already a bare ID
    return wikilink.rsplit("/", 1)[-1]


# ---------------------------------------------------------------------------
# Phase 3: Findings coverage scan
# ---------------------------------------------------------------------------

def scan_phase_3(project_path: str, schema: dict) -> dict:
    """Determine which refined questions already have findings.

    A question is "covered" if at least one finding references it via:
    - batch_ref wikilink matching {question_id}-batch
    - question_ref wikilink matching the question ID
    """
    questions_dir = get_entity_dir(schema, "refined-questions", project_path)
    findings_dir = get_entity_dir(schema, "findings", project_path)

    # Step 1: Discover all refined questions
    if not questions_dir.is_dir():
        return {"success": False, "error": f"Questions directory not found: {questions_dir}"}

    all_questions = sorted([
        f.stem for f in questions_dir.glob("question-*.md") if f.is_file()
    ])

    if not all_questions:
        return {"success": False, "error": "No refined questions found"}

    # Step 2: Scan all findings, build set of covered question IDs
    covered_question_ids: Set[str] = set()

    if findings_dir.is_dir():
        for finding_file in findings_dir.glob("finding-*.md"):
            if not finding_file.is_file():
                continue

            # Check batch_ref: [[03-query-batches/data/question-foo-abc123-batch]]
            batch_ref = extract_frontmatter_field(finding_file, "batch_ref")
            if batch_ref:
                batch_id = extract_entity_id_from_wikilink(batch_ref)
                # batch_id is like "question-foo-abc123-batch" -> question ID is "question-foo-abc123"
                if batch_id.endswith("-batch"):
                    question_id = batch_id[:-6]  # Strip "-batch"
                    if question_id in all_questions or any(q.startswith(question_id) for q in all_questions):
                        covered_question_ids.add(question_id)

            # Check question_ref: [[02-refined-questions/data/question-foo-abc123]]
            question_ref = extract_frontmatter_field(finding_file, "question_ref")
            if question_ref:
                q_id = extract_entity_id_from_wikilink(question_ref)
                if q_id in all_questions:
                    covered_question_ids.add(q_id)

    # Step 3: Determine pending vs completed
    completed = sorted(covered_question_ids)
    pending = sorted([q for q in all_questions if q not in covered_question_ids])

    # Step 4: Recommendation
    if len(pending) == 0:
        recommendation = "COMPLETE"
    elif len(completed) == 0:
        recommendation = "FULL_RUN"
    else:
        recommendation = "RESUME"

    return {
        "success": True,
        "phase": 3,
        "total_questions": len(all_questions),
        "completed_questions": len(completed),
        "pending_questions": pending,
        "completed_question_ids": completed,
        "recommendation": recommendation,
    }


# ---------------------------------------------------------------------------
# Phase 7: Claims coverage scan
# ---------------------------------------------------------------------------

def scan_phase_7(project_path: str, schema: dict) -> dict:
    """Determine which findings already have claims.

    A finding is "covered" if at least one claim references it in finding_refs.
    """
    findings_dir = get_entity_dir(schema, "findings", project_path)
    claims_dir = get_entity_dir(schema, "claims", project_path)

    # Step 1: Discover all findings
    if not findings_dir.is_dir():
        return {"success": False, "error": f"Findings directory not found: {findings_dir}"}

    all_findings = {}  # id -> path
    for f in sorted(findings_dir.glob("finding-*.md")):
        if f.is_file():
            all_findings[f.stem] = str(f)

    if not all_findings:
        return {"success": False, "error": "No findings found"}

    # Step 2: Scan all claims once, collect referenced finding IDs
    covered_finding_ids: Set[str] = set()

    if claims_dir.is_dir():
        for claim_file in claims_dir.glob("claim-*.md"):
            if not claim_file.is_file():
                continue

            finding_refs = extract_frontmatter_array(claim_file, "finding_refs")
            for ref in finding_refs:
                finding_id = extract_entity_id_from_wikilink(ref)
                covered_finding_ids.add(finding_id)

    # Step 3: Determine pending vs completed
    completed_ids = sorted([fid for fid in all_findings if fid in covered_finding_ids])
    pending_ids = sorted([fid for fid in all_findings if fid not in covered_finding_ids])
    pending_paths = [all_findings[fid] for fid in pending_ids]

    # Step 4: Recommendation
    if len(pending_ids) == 0:
        recommendation = "COMPLETE"
    elif len(completed_ids) == 0:
        recommendation = "FULL_RUN"
    else:
        recommendation = "RESUME"

    return {
        "success": True,
        "phase": 7,
        "total_findings": len(all_findings),
        "completed_findings": len(completed_ids),
        "pending_finding_ids": pending_ids,
        "pending_finding_paths": pending_paths,
        "recommendation": recommendation,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan filesystem to determine resumption state for batch phases"
    )
    parser.add_argument("--project-path", required=True, help="Path to research project directory")
    parser.add_argument("--phase", required=True, type=int, choices=[3, 7], help="Phase to scan (3 or 7)")
    parser.add_argument("--json", action="store_true", default=True, help="Output JSON (always on)")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    project_path = os.path.abspath(args.project_path)
    if not os.path.isdir(project_path):
        result = {"success": False, "error": f"Project path not found: {project_path}"}
        print(json.dumps(result))
        sys.exit(1)

    # Load entity schema
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    schema = load_entity_schema(plugin_root or None)

    # Dispatch by phase
    if args.phase == 3:
        result = scan_phase_3(project_path, schema)
    else:
        result = scan_phase_7(project_path, schema)

    print(json.dumps(result))

    if not result.get("success", False):
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
