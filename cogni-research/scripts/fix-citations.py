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
       — visually noisy for high-reuse reports (the Poland why-change report
       cites source 7 three times, source 6 twice, etc.).
    3. `<sup>[N](url)</sup>` (chicago shape) is a pure markdown link inside an
       HTML superscript wrapper. Clean rendering everywhere, one click to the
       source, no anchor resolution, no reuse counters.

The references appendix is preserved with full publisher / title / URL so the
reader has context at the end of the document. The `<a id="ref-N">` anchors are
stripped since they're no longer needed.

Usage:
    fix-citations.py <report.md> [--in-place] [--json]

Transformations (all idempotent):
    Inline body, in priority order — each pattern resolves N to a URL via the
    appendix mapping built in pass 1:
        <sup>[[N]](#ref-N)</sup>   -> <sup>[N](url)</sup>
        <sup>[N](#ref-N)</sup>     -> <sup>[N](url)</sup>
        [[N]](#ref-N)              -> <sup>[N](url)</sup>   (wikilink drift)
        [[N](url)]                 -> <sup>[N](url)</sup>   (legacy IEEE)
        [^N]                       -> <sup>[N](url)</sup>   (footnote drift)

    Appendix entries — strip the HTML anchor, keep everything else, optionally
    bold the visible [N] for prominence:
        <a id="ref-N"></a>[N] REST   -> **[N]** REST
        <a id="ref-N"></a>**[N]** REST -> **[N]** REST    (already bolded)
        [^N]: REST                   -> **[N]** REST     (footnote-definition drift)

Stdlib-only. Python 3.8+.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


URL_FROM_APPENDIX_PATTERNS = [
    # <a id="ref-1"></a>[1] Pub, "Title". [https://...](https://...)
    re.compile(r'<a id="ref-(?P<num>\d+)"></a>(?:\*\*)?\[\d+\](?:\*\*)?[^\n]*?\[(?P<url>https?://[^\]\s]+)\]'),
    # <a id="ref-1"></a>[1] ... https://...  (bare URL fallback)
    re.compile(r'<a id="ref-(?P<num>\d+)"></a>(?:\*\*)?\[\d+\](?:\*\*)?[^\n]*?(?P<url>https?://\S+)'),
    # [^1]: Pub, "Title". [https://...](https://...)  (already-footnoted variant)
    re.compile(r'^\[\^(?P<num>\d+)\]:[^\n]*?\[(?P<url>https?://[^\]\s]+)\]', re.MULTILINE),
    # [^1]: Pub, "Title". https://...
    re.compile(r'^\[\^(?P<num>\d+)\]:[^\n]*?(?P<url>https?://\S+)', re.MULTILINE),
]


def build_url_map(text: str) -> dict[str, str]:
    url_map: dict[str, str] = {}
    for pattern in URL_FROM_APPENDIX_PATTERNS:
        for match in pattern.finditer(text):
            num = match.group("num")
            url = match.group("url").rstrip(").,;:")
            if num not in url_map:
                url_map[num] = url
    return url_map


def normalise_inline(text: str, url_map: dict[str, str]) -> tuple[str, dict[str, int]]:
    counts = {
        "inline_wikilink_wrapped": 0,
        "inline_anchor_wrapped": 0,
        "inline_wikilink_drift": 0,
        "inline_ieee_legacy": 0,
        "inline_footnote_drift": 0,
        "inline_no_url": 0,
    }

    def replace(name: str):
        def _sub(m: re.Match) -> str:
            num = m.group(1)
            url = url_map.get(num)
            if url is None:
                counts["inline_no_url"] += 1
                # No URL → render as plain superscript without a link. The
                # reader can still find ref [N] in the appendix manually.
                return f"<sup>[{num}]</sup>"
            counts[name] += 1
            return f"<sup>[{num}]({url})</sup>"
        return _sub

    text = re.sub(r"<sup>\[\[(\d+)\]\]\(#ref-\d+\)</sup>", replace("inline_wikilink_wrapped"), text)
    text = re.sub(r"<sup>\[(\d+)\]\(#ref-\d+\)</sup>", replace("inline_anchor_wrapped"), text)
    text = re.sub(r"\[\[(\d+)\]\]\(#ref-\d+\)", replace("inline_wikilink_drift"), text)
    text = re.sub(r"\[\[(\d+)\]\([^)\s]+\)\]", replace("inline_ieee_legacy"), text)
    # Footnote drift: `[^N]` not at line-start (avoid matching definitions).
    text = re.sub(r"(?<!\n)\[\^(\d+)\](?!:)", replace("inline_footnote_drift"), text)

    return text, counts


APPENDIX_PATTERNS = [
    # <a id="ref-1"></a>**[1]** REST  ->  **[1]** REST
    (re.compile(r'<a id="ref-(\d+)"></a>(\*\*\[\d+\]\*\*\s+)'), r"\2", "appendix_strip_anchor_bolded"),
    # <a id="ref-1"></a>[1] REST  ->  **[1]** REST
    (re.compile(r'<a id="ref-(\d+)"></a>\[(\d+)\]\s+'), r"**[\2]** ", "appendix_strip_anchor_plain"),
    # [^1]: REST  ->  **[1]** REST   (footnote definition drift)
    (re.compile(r'^\[\^(\d+)\]:\s+', re.MULTILINE), r"**[\1]** ", "appendix_footnote_to_plain"),
]


def normalise_appendix(text: str) -> tuple[str, dict[str, int]]:
    counts: dict[str, int] = {}
    for pattern, replacement, name in APPENDIX_PATTERNS:
        text, n = pattern.subn(replacement, text)
        counts[name] = n
    return text, counts


def ensure_references_heading(text: str) -> tuple[str, int]:
    """Make sure a `## References` heading precedes the **[N]** entries when
    they exist. Idempotent — no-op if a heading already exists upstream of the
    first entry."""
    first_entry = re.search(r"(?m)^\*\*\[\d+\]\*\* ", text)
    if first_entry is None:
        return text, 0
    head_upstream = text[: first_entry.start()]
    if re.search(r"(?im)^##\s+(References|Quellen|Literaturverzeichnis|Bibliographie|Bibliografía|Bibliografia|Bibliografie)\s*$", head_upstream):
        return text, 0
    # Insert a `## References` heading directly above the first entry, with
    # blank lines on either side.
    insertion = "## References\n\n"
    new_text = text[: first_entry.start()] + insertion + text[first_entry.start() :]
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
    counts["total"] = sum(v for k, v in counts.items() if k != "appendix_urls_indexed")
    return text, counts


def derive_output_path(input_path: Path, in_place: bool) -> Path:
    if in_place:
        return input_path
    return input_path.with_name(f"{input_path.stem}-fixed{input_path.suffix}")


def emit_success(output_path: Path, counts: dict[str, int], emit_json: bool) -> None:
    if emit_json:
        payload = {"success": True, "data": {"output_path": str(output_path), "replacements": counts}}
        print(json.dumps(payload, ensure_ascii=False))
        return
    print(f"Wrote: {output_path}")
    print("Replacements:")
    for k, v in counts.items():
        print(f"  {k}: {v}")


def emit_error(message: str, emit_json: bool) -> None:
    if emit_json:
        print(json.dumps({"success": False, "error": message}, ensure_ascii=False))
    else:
        print(f"Error: {message}", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalise legacy citation patterns to URL-direct superscripts.")
    parser.add_argument("report", help="Path to the report .md file")
    parser.add_argument("--in-place", action="store_true", help="Overwrite the input file")
    parser.add_argument("--json", action="store_true", help="Emit a JSON status payload")
    args = parser.parse_args()

    input_path = Path(args.report)
    if not input_path.is_file():
        emit_error(f"file not found: {input_path}", args.json)
        return 1

    try:
        text = input_path.read_text(encoding="utf-8")
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
