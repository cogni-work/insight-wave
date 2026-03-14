#!/usr/bin/env python3
"""
deduplicate-concepts.py
Version: 1.0.0
Purpose: Deduplicate domain-concept entities by merging duplicates with same normalized name
Category: core

Usage:
    deduplicate-concepts.py --project-path <path> [options]

Required Arguments:
    --project-path <path>  Project directory path (research project root)

Optional Arguments:
    --dry-run              Show what would be done without making changes
    --json                 Output JSON format
    --verbose              Show detailed processing info

Process:
    1. Scan all concept-*.md files in 05-domain-concepts/data/
    2. Extract and normalize concept names
    3. Group by normalized name to identify duplicates
    4. For each duplicate group:
       - Keep file with highest confidence score
       - Merge all finding_refs into keeper
       - Update Related Findings section in keeper
       - Delete non-keeper files
    5. Output summary

Exit Codes:
    0   - Success
    1   - Validation error
    2   - Usage/argument error

JSON Output (success):
    {
        "success": true,
        "concepts_before": 69,
        "concepts_after": 65,
        "duplicate_groups": 4,
        "merged_files": ["...", "..."],
        "deleted_files": ["...", "..."]
    }
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Add shared utils to path
SCRIPT_DIR = Path(__file__).resolve().parent
BUNDLED_UTILS = SCRIPT_DIR / "shared_utils"
if BUNDLED_UTILS.is_dir():
    sys.path.insert(0, str(BUNDLED_UTILS))
else:
    REPO_ROOT = SCRIPT_DIR.parent.parent
    SHARED_UTILS = REPO_ROOT / "cogni-workplace" / "python"
    sys.path.insert(0, str(SHARED_UTILS))

from entity_index import normalize_entity_name


def normalize_concept_name(name: str) -> str:
    """Normalize concept name for deduplication (same as entity_index but without spaces).

    Args:
        name: Concept name to normalize

    Returns:
        Normalized name (lowercase, alphanumeric only, no spaces)
    """
    if not name:
        return ""

    # Use entity_index normalize then remove spaces for exact matching
    normalized = normalize_entity_name(name)
    # Remove all spaces for concept matching
    return normalized.replace(" ", "")


def parse_frontmatter(content: str) -> Tuple[Dict[str, Any], str]:
    """Parse YAML frontmatter from markdown content.

    Args:
        content: Full file content

    Returns:
        Tuple of (frontmatter_dict, body_content)
    """
    frontmatter = {}
    body = content

    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            yaml_content = parts[1].strip()
            body = parts[2].strip()

            # Parse YAML manually (simple key: value and array)
            current_key = None
            current_array = []

            for line in yaml_content.split("\n"):
                line = line.rstrip()

                # Array item
                if line.startswith("  - "):
                    if current_key:
                        # Extract value, handling quotes
                        value = line[4:].strip()
                        if value.startswith('"') and value.endswith('"'):
                            value = value[1:-1]
                        current_array.append(value)
                    continue

                # If we were building an array, save it
                if current_key and current_array:
                    frontmatter[current_key] = current_array
                    current_array = []
                    current_key = None

                # Key: value or key: (start of array)
                if ":" in line and not line.startswith(" "):
                    key, _, value = line.partition(":")
                    key = key.strip()
                    value = value.strip()

                    if value:
                        # Handle quoted values
                        if value.startswith('"') and value.endswith('"'):
                            value = value[1:-1]
                        # Handle arrays on same line [a, b, c]
                        elif value.startswith("[") and value.endswith("]"):
                            items = value[1:-1].split(",")
                            value = [i.strip().strip('"') for i in items if i.strip()]
                        frontmatter[key] = value
                    else:
                        # Start of array block
                        current_key = key

            # Save final array if any
            if current_key and current_array:
                frontmatter[current_key] = current_array

    return frontmatter, body


def extract_finding_refs_from_body(body: str) -> List[str]:
    """Extract finding references from Related Findings section.

    Args:
        body: Markdown body content

    Returns:
        List of wikilink references
    """
    refs = []

    # Find Related Findings section (various headings)
    patterns = [
        r"##\s*(?:Related Findings|Zugehörige Ergebnisse)\s*\n(.*?)(?=\n##|\Z)",
    ]

    for pattern in patterns:
        match = re.search(pattern, body, re.DOTALL | re.IGNORECASE)
        if match:
            section = match.group(1)
            # Extract wikilinks
            wikilinks = re.findall(r'\[\[(.*?)\]\]', section)
            for link in wikilinks:
                # Normalize to just the path part (before |)
                path = link.split("|")[0].strip()
                refs.append(path)

    return refs


def merge_finding_refs(keeper_refs: List[str], other_refs: List[str]) -> List[str]:
    """Merge finding references, removing duplicates.

    Args:
        keeper_refs: References from keeper file
        other_refs: References from duplicate file

    Returns:
        Merged list of unique references
    """
    # Normalize refs for comparison - extract finding ID regardless of path format
    def normalize_ref(ref: str) -> str:
        # Remove wikilink brackets
        ref = ref.replace("[[", "").replace("]]", "")
        # Extract just the filename/stem
        stem = Path(ref).stem
        # Handle any aliased wikilinks (path|alias)
        if "|" in stem:
            stem = stem.split("|")[0]
        return stem.lower()

    seen = set()
    merged = []

    for ref in keeper_refs + other_refs:
        norm = normalize_ref(ref)
        if norm and norm not in seen:
            seen.add(norm)
            merged.append(ref)

    return merged


def update_frontmatter_refs(content: str, new_refs: List[str]) -> str:
    """Update finding_refs in frontmatter.

    Args:
        content: Full file content
        new_refs: New list of finding references

    Returns:
        Updated content
    """
    # Build new finding_refs block
    refs_yaml = "finding_refs:\n"
    for ref in new_refs:
        # Ensure wikilink format
        if not ref.startswith("[["):
            ref = f"[[{ref}]]"
        refs_yaml += f'  - "{ref}"\n'

    # Replace existing finding_refs block
    pattern = r'finding_refs:\n(?:  - "[^"]*"\n)+'
    if re.search(pattern, content):
        content = re.sub(pattern, refs_yaml, content)
    else:
        # Insert before created_at if no finding_refs
        content = re.sub(
            r'(created_at:)',
            f'{refs_yaml}\\1',
            content
        )

    return content


def update_related_findings_section(content: str, refs: List[str]) -> str:
    """Update Related Findings section in body.

    Args:
        content: Full file content
        refs: List of finding references

    Returns:
        Updated content
    """
    # Build new section content
    section_items = []
    for ref in refs:
        # Create wikilink with display name
        path = ref.replace("[[", "").replace("]]", "")
        basename = Path(path).stem
        # Make display name readable
        display = basename.replace("finding-", "").replace("-", " ").title()
        section_items.append(f"- [[{path}|{display}]]")

    new_section = "\n".join(section_items)

    # Replace existing section
    patterns = [
        (r'(##\s*Related Findings\s*\n).*?(?=\n##|\Z)', f'\\1\n{new_section}\n'),
        (r'(##\s*Zugehörige Ergebnisse\s*\n).*?(?=\n##|\Z)', f'\\1\n{new_section}\n'),
    ]

    for pattern, replacement in patterns:
        if re.search(pattern, content, re.DOTALL | re.IGNORECASE):
            content = re.sub(pattern, replacement, content, flags=re.DOTALL | re.IGNORECASE)
            break

    return content


def deduplicate_concepts(
    project_path: str,
    dry_run: bool = False,
    verbose: bool = False
) -> Dict[str, Any]:
    """Main deduplication logic.

    Args:
        project_path: Path to research project
        dry_run: If True, don't make changes
        verbose: If True, print detailed info

    Returns:
        Summary dict with results
    """
    concepts_dir = Path(project_path) / "05-domain-concepts" / "data"

    if not concepts_dir.exists():
        return {
            "success": False,
            "error": f"Concepts directory not found: {concepts_dir}"
        }

    # Step 1: Scan all concept files
    concept_files = list(concepts_dir.glob("concept-*.md"))
    concepts_before = len(concept_files)

    if verbose:
        print(f"[INFO] Found {concepts_before} concept files")

    # Step 2: Build normalization map
    norm_map: Dict[str, List[Dict]] = {}  # normalized_name -> list of file info

    for filepath in concept_files:
        try:
            content = filepath.read_text(encoding="utf-8")
            frontmatter, body = parse_frontmatter(content)

            concept_name = frontmatter.get("concept", "")
            if not concept_name:
                # Try dc:title as fallback
                concept_name = frontmatter.get("dc:title", filepath.stem)

            normalized = normalize_concept_name(concept_name)

            if not normalized:
                if verbose:
                    print(f"[WARN] Empty normalized name for: {filepath.name}")
                continue

            confidence = float(frontmatter.get("confidence", 0.90))
            finding_refs = frontmatter.get("finding_refs", [])
            body_refs = extract_finding_refs_from_body(body)

            info = {
                "path": filepath,
                "name": concept_name,
                "normalized": normalized,
                "confidence": confidence,
                "finding_refs": finding_refs,
                "body_refs": body_refs,
                "content": content,
            }

            if normalized not in norm_map:
                norm_map[normalized] = []
            norm_map[normalized].append(info)

        except Exception as e:
            if verbose:
                print(f"[ERROR] Failed to parse {filepath.name}: {e}")

    # Step 3: Identify duplicate groups
    duplicate_groups = {
        norm: files
        for norm, files in norm_map.items()
        if len(files) > 1
    }

    if verbose:
        print(f"[INFO] Found {len(duplicate_groups)} duplicate groups")
        for norm, files in duplicate_groups.items():
            print(f"  - '{norm}': {len(files)} files")
            for f in files:
                print(f"      {f['path'].name} (confidence: {f['confidence']})")

    # Step 4: Process each duplicate group
    merged_files = []
    deleted_files = []

    for normalized, files in duplicate_groups.items():
        # Sort by confidence (highest first)
        files.sort(key=lambda x: x["confidence"], reverse=True)

        keeper = files[0]
        duplicates = files[1:]

        if verbose:
            print(f"\n[INFO] Processing group '{normalized}':")
            print(f"  Keeping: {keeper['path'].name} (confidence: {keeper['confidence']})")

        # Merge all finding_refs
        all_refs = list(keeper["finding_refs"])
        for dup in duplicates:
            all_refs = merge_finding_refs(all_refs, dup["finding_refs"])
            all_refs = merge_finding_refs(all_refs, dup["body_refs"])

            if verbose:
                print(f"  Merging: {dup['path'].name} ({len(dup['finding_refs'])} refs)")

        # Update keeper file
        if not dry_run:
            updated_content = keeper["content"]
            updated_content = update_frontmatter_refs(updated_content, all_refs)
            updated_content = update_related_findings_section(updated_content, all_refs)

            keeper["path"].write_text(updated_content, encoding="utf-8")
            merged_files.append(str(keeper["path"]))

            if verbose:
                print(f"  Updated keeper with {len(all_refs)} merged refs")

        # Delete duplicates
        for dup in duplicates:
            if not dry_run:
                dup["path"].unlink()
            deleted_files.append(str(dup["path"]))

            if verbose:
                action = "Would delete" if dry_run else "Deleted"
                print(f"  {action}: {dup['path'].name}")

    # Calculate final count
    if dry_run:
        concepts_after = concepts_before - len(deleted_files)
    else:
        concepts_after = len(list(concepts_dir.glob("concept-*.md")))

    return {
        "success": True,
        "concepts_before": concepts_before,
        "concepts_after": concepts_after,
        "duplicate_groups": len(duplicate_groups),
        "merged_files": merged_files,
        "deleted_files": deleted_files,
        "dry_run": dry_run,
    }


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Deduplicate domain-concept entities"
    )
    parser.add_argument(
        "--project-path",
        required=True,
        help="Project directory path"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON format"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed processing info"
    )

    args = parser.parse_args()

    # Validate project path
    project_path = Path(args.project_path).resolve()
    if not project_path.exists():
        error = {"success": False, "error": f"Project path not found: {project_path}"}
        if args.json:
            print(json.dumps(error, indent=2))
        else:
            print(f"ERROR: {error['error']}", file=sys.stderr)
        sys.exit(1)

    # Run deduplication
    result = deduplicate_concepts(
        str(project_path),
        dry_run=args.dry_run,
        verbose=args.verbose and not args.json
    )

    # Output result
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if result["success"]:
            action = "Would process" if args.dry_run else "Processed"
            print(f"\n{action} deduplication:")
            print(f"  Concepts before: {result['concepts_before']}")
            print(f"  Concepts after:  {result['concepts_after']}")
            print(f"  Duplicate groups: {result['duplicate_groups']}")
            print(f"  Files deleted: {len(result['deleted_files'])}")

            if result['deleted_files'] and not args.dry_run:
                print("\nDeleted files:")
                for f in result['deleted_files']:
                    print(f"  - {Path(f).name}")
        else:
            print(f"ERROR: {result.get('error', 'Unknown error')}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
