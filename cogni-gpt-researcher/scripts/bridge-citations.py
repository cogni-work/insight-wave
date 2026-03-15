#!/usr/bin/env python3
"""
bridge-citations.py
Version: 1.0.0
Purpose: Bridge citation formats between cogni-gpt-researcher and cogni-narrative.
Category: core

Usage:
    bridge-citations.py --project-path <path> [--json]

Reads output/report.md and extracts all [Source: Publisher](URL) citations.
Creates output/narrative-input/ with:
  - report-for-narrative.md — report body with [source-NN-slug.md] markers
  - sources/source-NN-publisher-slug.md — per-source files with YAML frontmatter

cogni-narrative then cites these source files as <sup>[N](source-NN-slug.md)</sup>,
preserving the full audit trail back to original URLs.

Output:
    {"success": true, "data": {"sources_extracted": N, "unique_publishers": N, ...}}
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple


def slugify(text: str) -> str:
    """Convert publisher name to a filesystem-safe slug."""
    slug = text.lower().strip()
    slug = re.sub(r'[^a-z0-9]+', '-', slug)
    slug = slug.strip('-')
    return slug[:60] if slug else 'unknown'


def extract_citations(report_text: str) -> List[Dict[str, str]]:
    """Extract all [Source: Publisher](URL) citations from report text.

    Returns deduplicated list of {publisher, url} dicts in order of first appearance.
    """
    pattern = r'\[Source:\s*([^\]]+)\]\(([^)]+)\)'
    seen_urls = set()
    citations = []

    for match in re.finditer(pattern, report_text):
        publisher = match.group(1).strip()
        url = match.group(2).strip()

        if url not in seen_urls:
            seen_urls.add(url)
            citations.append({
                'publisher': publisher,
                'url': url,
            })

    return citations


def create_source_file(index: int, publisher: str, url: str) -> Tuple[str, str]:
    """Create a source reference file content and filename.

    Returns (filename, content).
    """
    slug = slugify(publisher)
    filename = f"source-{index:02d}-{slug}.md"

    content = f"""---
source_index: {index}
publisher: "{publisher}"
url: "{url}"
---

# Source {index}: {publisher}

URL: {url}
"""
    return filename, content


def bridge_report(report_text: str, citations: List[Dict[str, str]],
                  source_filenames: Dict[str, str]) -> str:
    """Replace [Source: Publisher](URL) citations with [source-NN-slug.md] markers.

    The markers serve as breadcrumbs for cogni-narrative's citation system.
    """
    def replace_citation(match):
        url = match.group(2).strip()
        if url in source_filenames:
            return f"[{source_filenames[url]}]"
        return match.group(0)  # Keep original if not found

    pattern = r'\[Source:\s*([^\]]+)\]\(([^)]+)\)'
    return re.sub(pattern, replace_citation, report_text)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bridge citations for narrative pipeline")
    parser.add_argument("--project-path", required=True, help="Project directory")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    project_path = Path(args.project_path)
    report_path = project_path / "output" / "report.md"

    if not report_path.is_file():
        msg = f"Report not found: {report_path}"
        if args.json:
            print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
        else:
            print(f"ERROR: {msg}", file=sys.stderr)
        sys.exit(1)

    report_text = report_path.read_text(encoding='utf-8')

    # Extract unique citations
    citations = extract_citations(report_text)

    if not citations:
        msg = "No [Source: Publisher](URL) citations found in report"
        if args.json:
            print(json.dumps({
                "success": True,
                "data": {
                    "sources_extracted": 0,
                    "unique_publishers": 0,
                    "narrative_input_dir": str(project_path / "output" / "narrative-input"),
                    "source_files": [],
                    "warning": "No citations found — narrative will have limited source references"
                }
            }))
        else:
            print(f"WARNING: {msg}")
        # Still create the directory with just the report copy
        output_dir = project_path / "output" / "narrative-input"
        output_dir.mkdir(parents=True, exist_ok=True)
        (output_dir / "report-for-narrative.md").write_text(report_text, encoding='utf-8')
        return

    # Create output directory structure
    output_dir = project_path / "output" / "narrative-input"
    sources_dir = output_dir / "sources"
    sources_dir.mkdir(parents=True, exist_ok=True)

    # Create per-source files and build URL-to-filename map
    source_filenames = {}  # url -> filename
    source_files_created = []
    publishers_seen = set()

    for i, cit in enumerate(citations, start=1):
        filename, content = create_source_file(i, cit['publisher'], cit['url'])
        (sources_dir / filename).write_text(content, encoding='utf-8')
        source_filenames[cit['url']] = filename
        source_files_created.append(filename)
        publishers_seen.add(cit['publisher'])

    # Create bridged report with source-file markers
    bridged_report = bridge_report(report_text, citations, source_filenames)
    (output_dir / "report-for-narrative.md").write_text(bridged_report, encoding='utf-8')

    # Output result
    result = {
        "success": True,
        "data": {
            "sources_extracted": len(citations),
            "unique_publishers": len(publishers_seen),
            "narrative_input_dir": str(output_dir),
            "source_files": source_files_created,
        }
    }

    if args.json:
        print(json.dumps(result))
    else:
        print(f"Bridged {len(citations)} citations from {len(publishers_seen)} publishers")
        print(f"Created {len(source_files_created)} source files in {sources_dir}")
        print(f"Bridged report: {output_dir / 'report-for-narrative.md'}")


if __name__ == "__main__":
    main()
