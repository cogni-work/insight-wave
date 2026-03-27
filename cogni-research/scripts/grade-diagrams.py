#!/usr/bin/env python3
"""Grade Mermaid diagram quality in a cogni-research report.

Reads report.md and optionally diagram-plan.json, then produces
diagram-grading.json with per-diagram and overall pass/fail results.

Usage:
    python3 grade-diagrams.py --report <path>/report.md [--plan <path>/diagram-plan.json] [--max-diagrams 3] [--output <path>/diagram-grading.json]
"""

import argparse
import json
import re
import sys
from pathlib import Path


# Valid Mermaid diagram type declarations
VALID_TYPES = {
    "flowchart": r"flowchart\s+(LR|TD|TB|RL|BT)",
    "sequenceDiagram": r"sequenceDiagram",
    "classDiagram": r"classDiagram",
    "stateDiagram-v2": r"stateDiagram-v2",
    "stateDiagram": r"stateDiagram\b",
    "mindmap": r"mindmap",
    "pie": r"pie",
    "timeline": r"timeline",
}

# Patterns to approximate node count per diagram type
NODE_PATTERNS = {
    "flowchart": [
        r'(\w+)\[',       # A[label]
        r'(\w+)\{',       # A{label}
        r'(\w+)\(\(',     # A((label))
        r'(\w+)\(',       # A(label)
        r'(\w+)\[\[',     # A[[label]]
        r'(\w+)\[\/',     # A[/label/]
        r'(\w+)\[\\',     # A[\label\]
        r'(\w+)\>\s',     # A> label
    ],
    "sequenceDiagram": [
        r'participant\s+\w+',
        r'actor\s+\w+',
    ],
    "classDiagram": [
        r'class\s+\w+',
    ],
    "stateDiagram": [
        r'state\s+"[^"]*"\s+as\s+\w+',
        r'state\s+\w+',
        r'\[\*\]',
    ],
    "mindmap": [
        # Indented lines in mindmap are nodes
        r'^\s{2,}\S',
    ],
    "pie": [
        r'"[^"]+"\s*:\s*\d',
    ],
    "timeline": [
        r'^\s+\w',
    ],
}


def extract_mermaid_blocks(content: str) -> list[dict]:
    """Extract all fenced mermaid code blocks with their positions."""
    pattern = r'```mermaid\s*\n(.*?)```'
    blocks = []
    for match in re.finditer(pattern, content, re.DOTALL):
        block_content = match.group(1).strip()
        start_line = content[:match.start()].count('\n') + 1
        end_line = content[:match.end()].count('\n') + 1

        # Find text after the closing ```
        after_block = content[match.end():]

        blocks.append({
            "content": block_content,
            "start_line": start_line,
            "end_line": end_line,
            "after_block": after_block,
        })
    return blocks


def detect_diagram_type(block_content: str) -> str | None:
    """Detect the Mermaid diagram type from the first declaration line."""
    for type_name, pattern in VALID_TYPES.items():
        if re.search(pattern, block_content, re.MULTILINE):
            return type_name
    return None


def has_theme_directive(block_content: str) -> bool:
    """Check if the block contains the neutral theme directive."""
    return "%%{init:" in block_content and "'theme':'neutral'" in block_content.replace(" ", "")


def count_nodes(block_content: str, diagram_type: str) -> int:
    """Approximate node count for the diagram."""
    if diagram_type is None:
        return 0

    # Normalize type for pattern lookup
    type_key = diagram_type
    if type_key.startswith("stateDiagram"):
        type_key = "stateDiagram"

    patterns = NODE_PATTERNS.get(type_key, [])
    if not patterns:
        # Fallback: count non-empty, non-directive, non-declaration lines
        lines = [l.strip() for l in block_content.split('\n')
                 if l.strip() and not l.strip().startswith('%%') and not detect_diagram_type(l)]
        return len(lines)

    nodes = set()
    for pattern in patterns:
        for match in re.finditer(pattern, block_content, re.MULTILINE):
            nodes.add(match.group(0))
    return max(len(nodes), 1)


def check_balanced(block_content: str) -> bool:
    """Basic check for balanced brackets and braces."""
    stack = []
    pairs = {'(': ')', '[': ']', '{': '}'}
    # Skip content inside quotes
    in_quote = False
    for char in block_content:
        if char == '"':
            in_quote = not in_quote
            continue
        if in_quote:
            continue
        if char in pairs:
            stack.append(pairs[char])
        elif char in pairs.values():
            if not stack or stack[-1] != char:
                return False
            stack.pop()
    return len(stack) == 0


def extract_caption(after_block: str) -> dict:
    """Look for *Figure N: ...* caption after a mermaid block."""
    # Get the first few non-empty lines after the block
    lines = after_block.split('\n')
    for line in lines[:5]:  # Check up to 5 lines
        stripped = line.strip()
        if not stripped:
            continue
        # Match *Figure N: description*
        caption_match = re.match(r'^\*Figure\s+(\d+):\s*(.+?)\*$', stripped)
        if caption_match:
            return {
                "present": True,
                "figure_number": int(caption_match.group(1)),
                "text": caption_match.group(2).strip(),
                "word_count": len(caption_match.group(2).strip().split()),
            }
        # If we hit non-empty non-caption text, stop looking
        break

    return {"present": False, "figure_number": None, "text": "", "word_count": 0}


def load_diagram_plan(plan_path: Path) -> list[dict] | None:
    """Load diagram-plan.json if it exists."""
    if not plan_path.exists():
        return None
    try:
        with open(plan_path) as f:
            data = json.load(f)
        return data.get("diagrams", [])
    except (json.JSONDecodeError, KeyError):
        return None


def grade_report(report_path: Path, plan_path: Path | None, max_diagrams: int) -> dict:
    """Grade all diagrams in a report."""
    content = report_path.read_text(encoding="utf-8")
    blocks = extract_mermaid_blocks(content)

    # Load diagram plan
    planned_diagrams = None
    if plan_path:
        planned_diagrams = load_diagram_plan(plan_path)

    diagrams = []
    figure_numbers = []
    types_used = []

    for i, block in enumerate(blocks):
        diagram_type = detect_diagram_type(block["content"])
        theme = has_theme_directive(block["content"])
        node_count = count_nodes(block["content"], diagram_type)
        balanced = check_balanced(block["content"])
        caption = extract_caption(block["after_block"])

        if caption["present"]:
            figure_numbers.append(caption["figure_number"])
        if diagram_type:
            types_used.append(diagram_type)

        # Check if this diagram was planned
        planned = False
        if planned_diagrams:
            for pd in planned_diagrams:
                planned_type = pd.get("diagram_type", "")
                if planned_type.lower() in (diagram_type or "").lower():
                    planned = True
                    break

        diagrams.append({
            "index": i,
            "type": diagram_type,
            "type_valid": diagram_type is not None,
            "has_theme_directive": theme,
            "node_count": node_count,
            "node_count_ok": node_count <= 20,
            "node_count_warning": node_count > 15,
            "balanced_syntax": balanced,
            "caption_present": caption["present"],
            "caption_figure_number": caption["figure_number"],
            "caption_text": caption["text"],
            "caption_sufficient": caption["word_count"] >= 5,
            "start_line": block["start_line"],
            "end_line": block["end_line"],
            "planned": planned,
        })

    # Sequential numbering check
    expected_sequence = list(range(1, len(figure_numbers) + 1))
    sequential_numbering = figure_numbers == expected_sequence

    # Diversity
    unique_types = list(set(types_used))
    all_flowcharts = all(t.startswith("flowchart") for t in types_used) if types_used else False

    # Plan compliance
    plan_exists = planned_diagrams is not None
    planned_count = len(planned_diagrams) if planned_diagrams else 0

    # Overall checks
    all_types_valid = all(d["type_valid"] for d in diagrams)
    all_captions_present = all(d["caption_present"] for d in diagrams)
    all_captions_sufficient = all(d["caption_sufficient"] for d in diagrams)
    all_nodes_ok = all(d["node_count_ok"] for d in diagrams)
    all_balanced = all(d["balanced_syntax"] for d in diagrams)
    within_limit = len(blocks) <= max_diagrams
    has_diagrams = len(blocks) >= 1

    result = {
        "report_path": str(report_path),
        "diagram_count": len(blocks),
        "max_diagrams_limit": max_diagrams,
        "within_limit": within_limit,
        "plan_exists": plan_exists,
        "planned_count": planned_count,
        "diagrams": diagrams,
        "figure_numbers": figure_numbers,
        "sequential_numbering": sequential_numbering,
        "unique_types": unique_types,
        "type_diversity": len(unique_types),
        "all_flowcharts": all_flowcharts,
        "overall": {
            "has_diagrams": has_diagrams,
            "syntax_pass": all_types_valid and all_balanced,
            "caption_pass": all_captions_present and all_captions_sufficient,
            "numbering_pass": sequential_numbering,
            "node_count_pass": all_nodes_ok,
            "within_limit_pass": within_limit,
            "diversity_note": "all_flowcharts" if all_flowcharts else "diverse",
        },
        "pass": (
            has_diagrams
            and all_types_valid
            and all_balanced
            and all_captions_present
            and sequential_numbering
            and all_nodes_ok
            and within_limit
        ),
    }

    return result


def main():
    parser = argparse.ArgumentParser(description="Grade Mermaid diagrams in a research report")
    parser.add_argument("--report", required=True, type=Path, help="Path to report.md")
    parser.add_argument("--plan", type=Path, default=None, help="Path to diagram-plan.json")
    parser.add_argument("--max-diagrams", type=int, default=3, help="Maximum allowed diagrams")
    parser.add_argument("--output", type=Path, default=None, help="Output path for diagram-grading.json")
    args = parser.parse_args()

    if not args.report.exists():
        print(f"Error: report not found at {args.report}", file=sys.stderr)
        sys.exit(1)

    result = grade_report(args.report, args.plan, args.max_diagrams)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Diagram grading written to {args.output}")
    else:
        print(json.dumps(result, indent=2))

    # Exit with non-zero if overall grading failed
    if not result["pass"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
