#!/usr/bin/env python3
"""Repair megatrend entity files: fix finding_refs YAML indentation and
add clickable display-name wikilinks to the Evidenzbasis/Key Findings section.

Usage:
    python3 repair-megatrend-frontmatter.py <megatrends_data_dir> [--dry-run]

The script expects a directory containing megatrend-*.md files and a sibling
04-findings/data/ directory at the project root (two levels up from data/).
"""

import os
import re
import sys


def parse_frontmatter(text):
    """Split a markdown file into (frontmatter_str, body_str).
    Returns raw frontmatter string (without delimiters) and body after closing ---."""
    if not text.startswith("---"):
        return None, text
    second = text.index("---", 3)
    fm = text[3:second].strip()
    body = text[second + 3:]
    return fm, body


def fix_finding_refs_indentation(fm_lines):
    """Normalize finding_refs items: all items must start with '  - ' (2-space indent)."""
    fixed = []
    in_finding_refs = False
    changes = 0
    for line in fm_lines:
        if line.startswith("finding_refs:"):
            in_finding_refs = True
            fixed.append(line)
            continue
        if in_finding_refs:
            stripped = line.lstrip()
            # End of finding_refs block: non-list, non-comment, non-empty line
            if stripped and not stripped.startswith("- ") and not stripped.startswith("#"):
                in_finding_refs = False
                fixed.append(line)
                continue
            # Fix list items at wrong indentation
            if stripped.startswith("- "):
                correct = "  " + stripped
                if line != correct:
                    changes += 1
                fixed.append(correct)
                continue
            # Comment lines inside finding_refs — normalize to 2-space too
            if stripped.startswith("#"):
                correct = "  " + stripped
                if line != correct:
                    changes += 1
                fixed.append(correct)
                continue
            # Empty line or [] — pass through
            fixed.append(line)
        else:
            fixed.append(line)
    return fixed, changes


def extract_finding_ids(fm_text):
    """Extract finding IDs from wikilinks in finding_refs."""
    return re.findall(r'\[\[04-findings/data/(finding-[^\]]+)\]\]', fm_text)


def read_finding_title(findings_dir, finding_id):
    """Read dc:title from a finding file's YAML frontmatter."""
    path = os.path.join(findings_dir, finding_id + ".md")
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except OSError:
        return None

    fm, _ = parse_frontmatter(content)
    if fm is None:
        return None

    # Extract dc:title from frontmatter lines
    for line in fm.split("\n"):
        line_stripped = line.strip()
        if line_stripped.startswith("dc:title:"):
            value = line_stripped[len("dc:title:"):].strip()
            # Remove surrounding quotes
            if (value.startswith('"') and value.endswith('"')) or \
               (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]
            return value
    return None


def build_findings_bullet_list(finding_ids, findings_dir):
    """Build markdown bullet list of display-name wikilinks."""
    lines = []
    for fid in finding_ids:
        title = read_finding_title(findings_dir, fid)
        if title:
            display = title
        else:
            # Fallback: humanize the slug
            display = fid.replace("-", " ").title()
        lines.append(f"- [[04-findings/data/{fid}|{display}]]")
    return "\n".join(lines)


def replace_evidenzbasis_comment(body, bullet_list):
    """Replace the HTML comment placeholder in Evidenzbasis/Key Findings section."""
    # Match the comment line (possibly with surrounding whitespace)
    pattern = r"<!-- See finding_refs in frontmatter[^\n]*-->"
    if re.search(pattern, body):
        return re.sub(pattern, bullet_list, body), True
    return body, False


def process_file(filepath, findings_dir, dry_run=False):
    """Process a single megatrend file. Returns dict of changes made."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    fm_raw, body = parse_frontmatter(content)
    if fm_raw is None:
        return {"file": os.path.basename(filepath), "error": "no frontmatter"}

    changes = {}

    # Fix indentation
    fm_lines = fm_raw.split("\n")
    fixed_lines, indent_fixes = fix_finding_refs_indentation(fm_lines)
    if indent_fixes > 0:
        changes["indent_fixes"] = indent_fixes
    fm_fixed = "\n".join(fixed_lines)

    # Extract finding IDs from fixed frontmatter
    finding_ids = extract_finding_ids(fm_fixed)
    changes["finding_count"] = len(finding_ids)

    # Build bullet list
    bullet_list = build_findings_bullet_list(finding_ids, findings_dir)

    # Replace comment in body
    new_body, replaced = replace_evidenzbasis_comment(body, bullet_list)
    if replaced:
        changes["evidenzbasis_replaced"] = True

    # Rebuild file
    new_content = "---\n" + fm_fixed + "\n---" + new_body

    if new_content != content:
        changes["modified"] = True
        if not dry_run:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
    else:
        changes["modified"] = False

    changes["file"] = os.path.basename(filepath)
    return changes


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <megatrends_data_dir> [--dry-run]", file=sys.stderr)
        sys.exit(1)

    data_dir = os.path.normpath(sys.argv[1])
    dry_run = "--dry-run" in sys.argv

    if not os.path.isdir(data_dir):
        print(f"ERROR: Not a directory: {data_dir}", file=sys.stderr)
        sys.exit(1)

    # Determine project root (data_dir is <project>/06-megatrends/data/)
    project_root = os.path.dirname(os.path.dirname(data_dir))
    findings_dir = os.path.join(project_root, "04-findings", "data")

    if not os.path.isdir(findings_dir):
        print(f"WARNING: Findings directory not found: {findings_dir}", file=sys.stderr)
        print("Titles will use fallback display names.", file=sys.stderr)

    # Find all megatrend files
    files = sorted([
        os.path.join(data_dir, f)
        for f in os.listdir(data_dir)
        if f.startswith("megatrend-") and f.endswith(".md")
    ])

    if not files:
        print("No megatrend files found.", file=sys.stderr)
        sys.exit(1)

    print(f"Processing {len(files)} megatrend files...")
    if dry_run:
        print("(DRY RUN — no files will be modified)\n")

    total_indent_fixes = 0
    total_modified = 0

    for filepath in files:
        result = process_file(filepath, findings_dir, dry_run)
        name = result["file"]

        if "error" in result:
            print(f"  SKIP {name}: {result['error']}")
            continue

        parts = []
        if result.get("indent_fixes", 0) > 0:
            parts.append(f"{result['indent_fixes']} indent fixes")
            total_indent_fixes += result["indent_fixes"]
        if result.get("evidenzbasis_replaced"):
            parts.append(f"evidenzbasis updated ({result['finding_count']} findings)")
        if result.get("modified"):
            total_modified += 1
            status = "MODIFIED"
        else:
            status = "OK (no changes)"

        detail = ", ".join(parts) if parts else "no changes needed"
        print(f"  {status}: {name} — {detail}")

    print(f"\nSummary: {total_modified}/{len(files)} files modified, "
          f"{total_indent_fixes} indentation fixes applied")


if __name__ == "__main__":
    main()
