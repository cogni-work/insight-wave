#!/usr/bin/env python3
"""
convert_to_md.py — convert a non-markdown source file to markdown for ingest.

Issue #208: wiki-ingest's Step 2 today only handles `.md` files in `raw/`,
PDFs (via the Read tool's pages parameter), URLs (via WebFetch), and pasted
text. Multi-format consulting sources (`.docx` interviews, `.pptx` decks,
`.xlsx` models, `.html` web archives, `.epub` training material) require
manual pre-conversion before the user can ingest them.

This helper closes that gap with stdlib-first detection plus an optional
shell-out to `markitdown` when available. The original under `raw/` is
preserved verbatim — the converted markdown is written alongside as
`<source-stem>.converted.md` so the ground-truth source remains the file
referenced by `sources:` frontmatter; re-ingest can re-convert if a future
markitdown release improves extraction.

cogni-wiki stays stdlib-only by default. markitdown is an optional
dependency that enables richer extraction for binary office formats; its
absence is not an error for the formats stdlib can handle (`.md`, `.pdf`,
`.html`, `.txt`).

Usage:
    convert_to_md.py --source raw/report.docx
    convert_to_md.py --source raw/page.html --no-markitdown
    convert_to_md.py --source raw/notes.md            # no-op, returns source path
    convert_to_md.py --source raw/report.docx --force # ignore the cache

Output contract (stdout, single-line JSON):
    {
      "success": true,
      "data": {
        "source_path": "raw/report.docx",
        "converted_path": "raw/report.converted.md",
        "backend": "markitdown",
        "cached": false
      },
      "error": ""
    }

Backends:
  - noop-markdown          source is already `.md` / `.markdown` — `converted_path` == `source_path`
  - noop-pdf               source is `.pdf` — wiki-ingest Step 2 handles PDFs via the Read tool
  - stdlib-passthrough     source is `.txt` — copied verbatim into the converted file
  - stdlib-html            source is `.html` / `.htm` — tags stripped via `html.parser`
  - markitdown             shelled out to the `markitdown` CLI when installed
  - cache-hit              `<source>.converted.md` is newer than the source — re-used unchanged

Idempotency: a converted file whose mtime is newer than (or equal to) the
source's mtime is treated as up-to-date and re-used without invoking the
backend. `--force` overrides. The PDF and markdown no-ops are always
idempotent because they never write a converted file.

stdlib-only (Python 3.8+, macOS / Linux). markitdown is optional.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import List

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import atomic_write  # noqa: E402


MARKDOWN_EXTS = {".md", ".markdown"}
PDF_EXTS = {".pdf"}
TEXT_EXTS = {".txt"}
HTML_EXTS = {".html", ".htm"}
# Formats markitdown handles when available; stdlib has no fallback for these.
MARKITDOWN_ONLY_EXTS = {
    ".docx", ".doc",
    ".pptx", ".ppt",
    ".xlsx", ".xls",
    ".epub",
    ".rst",
    ".csv", ".tsv",
    ".json", ".xml",
    ".yaml", ".yml",
    ".ipynb",
}


def fail(msg: str, **extra) -> None:
    print(json.dumps({"success": False, "data": dict(extra), "error": msg}))
    sys.exit(1)


def ok(**data) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


class _HTMLToText(HTMLParser):
    """Stdlib-only HTML→text fallback. Coarse — preserves heading levels and
    paragraph breaks; drops attributes, scripts, and styles. Good enough for
    web-archive ingest when markitdown isn't installed."""

    _SKIP_TAGS = {"script", "style", "noscript", "head"}
    _BLOCK_TAGS = {"p", "li", "tr", "div", "section", "article", "blockquote"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._chunks: List[str] = []
        self._skip_depth = 0
        self._heading: int = 0  # active heading level, 0 if none

    def handle_starttag(self, tag, attrs):
        if tag in self._SKIP_TAGS:
            self._skip_depth += 1
            return
        if len(tag) == 2 and tag[0] == "h" and tag[1].isdigit():
            self._heading = int(tag[1])
            self._chunks.append("\n\n" + "#" * self._heading + " ")
            return
        if tag == "br":
            self._chunks.append("\n")
            return
        if tag in self._BLOCK_TAGS:
            self._chunks.append("\n\n")
            return

    def handle_endtag(self, tag):
        if tag in self._SKIP_TAGS:
            if self._skip_depth > 0:
                self._skip_depth -= 1
            return
        if len(tag) == 2 and tag[0] == "h" and tag[1].isdigit():
            self._heading = 0
            self._chunks.append("\n\n")
            return
        if tag in self._BLOCK_TAGS:
            self._chunks.append("\n\n")

    def handle_data(self, data):
        if self._skip_depth == 0:
            self._chunks.append(data)

    def text(self) -> str:
        raw = "".join(self._chunks)
        # Collapse runs of >2 newlines to exactly 2 (paragraph break).
        out_lines: List[str] = []
        blank_run = 0
        for line in raw.splitlines():
            stripped = line.strip()
            if stripped:
                out_lines.append(stripped)
                blank_run = 0
            else:
                blank_run += 1
                if blank_run == 1:
                    out_lines.append("")
        return "\n".join(out_lines).strip() + "\n"


def _converted_path_for(source: Path) -> Path:
    # Sit alongside the source so frontmatter-relative paths still resolve.
    # `<stem>.converted.md` keeps the original extension visible in the name.
    return source.with_suffix(source.suffix + ".converted.md")


def _is_cache_fresh(source: Path, converted: Path) -> bool:
    if not converted.is_file():
        return False
    try:
        return converted.stat().st_mtime >= source.stat().st_mtime
    except OSError:
        return False


def _convert_html_stdlib(source: Path) -> str:
    raw = source.read_text(encoding="utf-8", errors="replace")
    parser = _HTMLToText()
    parser.feed(raw)
    parser.close()
    return parser.text()


def _convert_via_markitdown(source: Path) -> str:
    # markitdown's CLI prints the converted markdown to stdout.
    # We pass the input as a positional argument so it works for binary formats.
    proc = subprocess.run(
        ["markitdown", str(source)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"markitdown exited {proc.returncode}: {proc.stderr.strip() or '<no stderr>'}"
        )
    return proc.stdout


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a non-markdown source to markdown for wiki-ingest"
    )
    parser.add_argument("--source", required=True, help="Path to the source file under raw/")
    parser.add_argument(
        "--no-markitdown",
        action="store_true",
        help="Skip the markitdown CLI even if installed (use stdlib backends only)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-run conversion even if the cached .converted.md is newer than the source",
    )
    args = parser.parse_args()

    source = Path(args.source).expanduser()
    if not source.is_file():
        fail(f"source not found: {source}", source_path=str(source))

    ext = source.suffix.lower()

    if ext in MARKDOWN_EXTS:
        ok(
            source_path=str(source),
            converted_path=str(source),
            backend="noop-markdown",
            cached=False,
        )
        return

    if ext in PDF_EXTS:
        # PDFs are read by wiki-ingest Step 2 via the Read tool's pages param.
        # We deliberately do not invoke markitdown here — the existing pipeline
        # is fine for consulting workloads (per issue #208 non-goals).
        ok(
            source_path=str(source),
            converted_path=str(source),
            backend="noop-pdf",
            cached=False,
        )
        return

    converted = _converted_path_for(source)

    if not args.force and _is_cache_fresh(source, converted):
        ok(
            source_path=str(source),
            converted_path=str(converted),
            backend="cache-hit",
            cached=True,
        )
        return

    have_markitdown = (not args.no_markitdown) and bool(shutil.which("markitdown"))

    backend: str
    content: str

    try:
        if ext in TEXT_EXTS and not have_markitdown:
            content = source.read_text(encoding="utf-8", errors="replace")
            backend = "stdlib-passthrough"
        elif ext in HTML_EXTS and not have_markitdown:
            content = _convert_html_stdlib(source)
            backend = "stdlib-html"
        elif have_markitdown and ext in (TEXT_EXTS | HTML_EXTS | MARKITDOWN_ONLY_EXTS):
            content = _convert_via_markitdown(source)
            backend = "markitdown"
        elif ext in MARKITDOWN_ONLY_EXTS:
            fail(
                f"format {ext!r} requires markitdown — install with `pip install markitdown` "
                f"or convert {source.name} to markdown manually",
                source_path=str(source),
                backend="unsupported",
            )
            return
        else:
            fail(
                f"unsupported source extension {ext!r}",
                source_path=str(source),
                backend="unsupported",
            )
            return
    except RuntimeError as e:
        fail(str(e), source_path=str(source), backend="markitdown-error")
        return
    except OSError as e:
        fail(f"could not read source: {e}", source_path=str(source))
        return

    atomic_write(converted, content)

    ok(
        source_path=str(source),
        converted_path=str(converted),
        backend=backend,
        cached=False,
    )


if __name__ == "__main__":
    main()
