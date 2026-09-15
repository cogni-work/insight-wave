#!/usr/bin/env python3
"""Mechanical preservation gate for copywriter and compression outputs."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

CITES = re.compile(r"\[P\d+-\d+\](?:\([^)]+\))?|<sup>\[\d+\]</sup>|\[(?:portfolio|claim|[a-z-]+)-validated\]")
URLS = re.compile(r"https?://[^\s)>]+")
NUMBERS = re.compile(r"(?<!\w)(?:[$€£]?\d[\d.,]*(?:%|x|×)?|\d{4})(?!\w)")
ASSUMPTIONS = re.compile(r"\{\{asm:[a-z0-9-]+\}\}")
EMBEDS = re.compile(r"!\[\[assets/[^]]+\.svg\]\]")
FIGURES = re.compile(r"\b(?:Figure|Abbildung)\s+\d+\b")
DIAGRAMS = re.compile(r"<diagram-placeholder\b.*?</diagram-placeholder>", re.S)
H2 = re.compile(r"^## .+$", re.M)
WORDS = re.compile(r"\b[\wÀ-ž'-]+\b")


def ordered(pattern: re.Pattern[str], text: str) -> list[str]:
    return pattern.findall(text)


def table_blocks(text: str) -> list[str]:
    lines = text.splitlines()
    return ["\n".join(lines[i:i + 2]) for i, line in enumerate(lines) if line.startswith("| ") and i + 1 < len(lines)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("output")
    parser.add_argument("--mode", choices=("standard", "translate", "compress"), default="standard")
    parser.add_argument("--arc", action="store_true")
    parser.add_argument("--target-lang")
    parser.add_argument("--entities", default="")
    parser.add_argument("--claims", default="")
    args = parser.parse_args()
    findings: list[dict[str, str]] = []

    if args.mode == "compress" and args.arc:
        findings.append({"check": "forbidden-mode", "detail": "compress cannot run with arc mode"})
    if args.mode == "compress" and args.target_lang:
        findings.append({"check": "forbidden-mode", "detail": "compress cannot run with translation"})

    source = Path(args.source).read_text(encoding="utf-8")
    output = Path(args.output).read_text(encoding="utf-8")
    checks = {
        "citations": (ordered(CITES, source), ordered(CITES, output)),
        "urls": (ordered(URLS, source), ordered(URLS, output)),
        "assumptions": (ordered(ASSUMPTIONS, source), ordered(ASSUMPTIONS, output)),
        "embeds": (ordered(EMBEDS, source), ordered(EMBEDS, output)),
        "figures": (ordered(FIGURES, source), ordered(FIGURES, output)),
        "diagrams": (ordered(DIAGRAMS, source), ordered(DIAGRAMS, output)),
        "tables": (table_blocks(source), table_blocks(output)),
    }
    for name, (before, after) in checks.items():
        if before != after:
            findings.append({"check": name, "detail": f"protected {name} changed or reordered"})

    if args.mode != "translate" and ordered(NUMBERS, source) != ordered(NUMBERS, output):
        findings.append({"check": "numbers", "detail": "numbers changed, disappeared, or moved"})
    for kind, values in (("entity", args.entities), ("claim", args.claims)):
        for value in filter(None, (item.strip() for item in values.split("|"))):
            if value not in output:
                findings.append({"check": f"{kind}-preserved", "detail": f"missing {kind}: {value}"})
    if args.arc and len(H2.findall(source)) != len(H2.findall(output)):
        findings.append({"check": "arc-headings", "detail": "arc H2 count changed"})
    if args.mode == "compress" and len(WORDS.findall(output)) >= len(WORDS.findall(source)):
        findings.append({"check": "compression-reduction", "detail": "output is not shorter than source"})

    payload = {"checks": list(checks) + ["numbers", "entities", "claims", "arc-headings", "compression-reduction"], "findings": findings}
    print(json.dumps({"success": not findings, "data": payload, "error": "" if not findings else "copywriter output failed preservation gate"}, ensure_ascii=False))
    return 0 if not findings else 1


if __name__ == "__main__":
    raise SystemExit(main())
