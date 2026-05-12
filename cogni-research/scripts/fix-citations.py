#!/usr/bin/env python3
"""
fix-citations.py
Version: 3.0.0
Purpose: Normalise legacy inline citation patterns in cogni-research reports to
         the URL-direct superscript shape (`<sup>[N](url)</sup>`), which renders
         as a clean clickable superscript number in Obsidian, GitHub, and Pandoc
         without footnote-reuse counters or anchor-resolution quirks.
Category: post-processing

Why URL-direct superscripts (not anchor links, not native footnotes):
    1. `[text](#anchor)` linking to `<a id="anchor">` is unreliable in Obsidian
       — Obsidian's `#anchor` resolution targets headings, not inline HTML ids.
    2. Native markdown footnotes `[^N]` render correctly but Obsidian appends a
       reuse counter for sources cited more than once: `[4-1]`, `[4-2]`, `[4-3]`
       — visually noisy for high-reuse reports.
    3. `<sup>[N](url)</sup>` is a pure markdown link inside an HTML superscript
       wrapper. Clean rendering everywhere, one click to the source.

Usage:
    fix-citations.py <report.md> [--in-place] [--json]

Stdlib-only. Python 3.8+.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


# (regex, kind) — kind is purely diagnostic; matches feed a single url_map.
URL_FROM_APPENDIX_PATTERNS = [
    (re.compile(r'<a id="ref-(?P<num>\d+)"></a>(?:\*\*)?\[\d+\](?:\*\*)?[^\n]*?\[(?P<url>https?://[^\]\s]+)\]'), "anchor_md_link"),
    (re.compile(r'<a id="ref-(?P<num>\d+)"></a>(?:\*\*)?\[\d+\](?:\*\*)?[^\n]*?(?P<url>https?://\S+)'), "anchor_bare_url"),
    (re.compile(r'^\[\^(?P<num>\d+)\]:[^\n]*?\[(?P<url>https?://[^\]\s]+)\]', re.MULTILINE), "footnote_md_link"),
    (re.compile(r'^\[\^(?P<num>\d+)\]:[^\n]*?(?P<url>https?://\S+)', re.MULTILINE), "footnote_bare_url"),
]

INLINE_PATTERNS = [
    (re.compile(r"<sup>\[\[(\d+)\]\]\(#ref-\d+\)</sup>"), "inline_wikilink_wrapped"),
    (re.compile(r"<sup>\[(\d+)\]\(#ref-\d+\)</sup>"), "inline_anchor_wrapped"),
    (re.compile(r"\[\[(\d+)\]\]\(#ref-\d+\)"), "inline_wikilink_drift"),
    (re.compile(r"\[\[(\d+)\]\([^)\s]+\)\]"), "inline_ieee_legacy"),
    # `[^N]` not at line-start (line-start is a definition, not a citation).
    (re.compile(r"(?<!\n)\[\^(\d+)\](?!:)"), "inline_footnote_drift"),
]

APPENDIX_PATTERNS = [
    (re.compile(r'<a id="ref-(\d+)"></a>(\*\*\[\d+\]\*\*\s+)'), r"\2", "appendix_strip_anchor_bolded"),
    (re.compile(r'<a id="ref-(\d+)"></a>\[(\d+)\]\s+'), r"**[\2]** ", "appendix_strip_anchor_plain"),
    (re.compile(r"^\[\^(\d+)\]:\s+", re.MULTILINE), r"**[\1]** ", "appendix_footnote_to_plain"),
]

REFERENCES_HEADING = re.compile(
    r"(?im)^##\s+(References|Quellen|Literaturverzeichnis|Bibliographie|Bibliografía|Bibliografia|Bibliografie)\s*$"
)
FIRST_REF_ENTRY = re.compile(r"(?m)^\*\*\[\d+\]\*\* ")


def build_url_map(text: str) -> dict[str, str]:
    url_map: dict[str, str] = {}
    for pattern, _ in URL_FROM_APPENDIX_PATTERNS:
        for match in pattern.finditer(text):
            num = match.group("num")
            if num not in url_map:
                url_map[num] = match.group("url").rstrip(").,;:")
    return url_map


def normalise_inline(text: str, url_map: dict[str, str]) -> tuple[str, dict[str, int]]:
    counts: dict[str, int] = {kind: 0 for _, kind in INLINE_PATTERNS}
    counts["inline_no_url"] = 0

    for pattern, kind in INLINE_PATTERNS:
        def _sub(m: re.Match, _kind: str = kind) -> str:
            num = m.group(1)
            url = url_map.get(num)
            if url is None:
                counts["inline_no_url"] += 1
                return f"<sup>[{num}]</sup>"
            counts[_kind] += 1
            return f"<sup>[{num}]({url})</sup>"
        text = pattern.sub(_sub, text)

    return text, counts


def normalise_appendix(text: str) -> tuple[str, dict[str, int]]:
    counts: dict[str, int] = {}
    for pattern, replacement, name in APPENDIX_PATTERNS:
        text, counts[name] = pattern.subn(replacement, text)
    return text, counts


def ensure_references_heading(text: str) -> tuple[str, int]:
    first_entry = FIRST_REF_ENTRY.search(text)
    if first_entry is None:
        return text, 0
    if REFERENCES_HEADING.search(text[: first_entry.start()]):
        return text, 0
    new_text = text[: first_entry.start()] + "## References\n\n" + text[first_entry.start() :]
    return new_text, 1


def transform(text: str) -> tuple[str, dict[str, int]]:
    url_map = build_url_map(text)
    counts: dict[str, int] = {"appendix_urls_indexed": len(url_map)}
    text, inline_counts = normalise_inline(text, url_map)
    counts.update(inline_counts)
    text, appendix_counts = normalise_appendix(text)
    counts.update(appendix_counts)
    text, heading_added = ensure_references_heading(text)
    counts["references_heading_added"] = heading_added
    return text, counts


def derive_output_path(input_path: Path, in_place: bool) -> Path:
    if in_place:
        return input_path
    return input_path.with_name(f"{input_path.stem}-fixed{input_path.suffix}")


def emit_success(output_path: Path, counts: dict[str, int], emit_json: bool) -> None:
    # `total` excludes the index size — only replacements count.
    total = sum(v for k, v in counts.items() if k != "appendix_urls_indexed")
    counts_with_total = {**counts, "total": total}
    if emit_json:
        payload = {"success": True, "data": {"output_path": str(output_path), "replacements": counts_with_total}}
        print(json.dumps(payload, ensure_ascii=False))
        return
    print(f"Wrote: {output_path}")
    print("Replacements:")
    for k, v in counts_with_total.items():
        print(f"  {k}: {v}")


def emit_error(message: str, emit_json: bool) -> None:
    if emit_json:
        print(json.dumps({"success": False, "error": message}, ensure_ascii=False), file=sys.stderr)
    else:
        print(f"Error: {message}", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalise legacy citation patterns to URL-direct superscripts.")
    parser.add_argument("report", help="Path to the report .md file")
    parser.add_argument("--in-place", action="store_true", help="Overwrite the input file")
    parser.add_argument("--json", action="store_true", help="Emit a JSON status payload")
    args = parser.parse_args()

    input_path = Path(args.report)
    try:
        text = input_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        emit_error(f"file not found: {input_path}", args.json)
        return 1
    except UnicodeDecodeError as exc:
        emit_error(f"could not decode {input_path} as utf-8: {exc}", args.json)
        return 1

    out_text, counts = transform(text)
    output_path = derive_output_path(input_path, args.in_place)
    output_path.write_text(out_text, encoding="utf-8")
    emit_success(output_path, counts, args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
