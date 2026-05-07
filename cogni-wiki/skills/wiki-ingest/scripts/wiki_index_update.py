#!/usr/bin/env python3
"""
wiki_index_update.py — deterministically insert or update a page's entry in
wiki/index.md, preserving alphabetical order within the chosen category.

The wiki-ingest skill previously told the orchestrator to "read index.md,
pick a heading, insert a line, keep it alphabetised" — four steps of pure
prose discipline. At 7 pages the rule worked by accident; at 164 pages the
probability of silent drift (forgotten line, duplicate line on re-ingest,
broken ordering) is high. This helper moves the invariants into code so the
skill can invoke a single deterministic command instead of reciting a
checklist.

Usage:
    wiki_index_update.py --wiki-root <path> \\
                         --slug <slug> \\
                         --summary "<one-sentence summary>" \\
                         --category "<heading-text>"

    wiki_index_update.py --wiki-root <path> --reflow-only \\
                         [--dry-run]

Reflow-only mode (v0.0.32+, #222) re-sorts every category's bullet block
alphabetically by slug without inserting or updating any line. Used by
`wiki-lint --fix=alphabetisation`. Idempotent: a clean index produces
`{"action": "noop", ...}`. Pure function in `reflow_categories(text)` so
in-process callers can avoid the subprocess hop.

Behaviour (slug mode):
    1. Insert the line `- [[{slug}]] — {summary}` under the heading matching
       `--category` (matches either `##` or `###` exactly).
    2. If the category heading does not exist, create it as a `##` heading
       at the end of the file.
    3. If a line for `{slug}` already exists under any heading, **update it
       in place** (same position) rather than appending a duplicate. This is
       the re-ingest case — same contract as backlink_audit.py's
       `--apply-plan` idempotency.
    4. Keep the section alphabetised by slug after every insert.
    5. Write atomically via `tempfile` + `os.replace` so a crash mid-write
       cannot leave a half-updated index.

Output contract:
    {
      "success": true,
      "data": {
        "action": "inserted" | "updated",
        "category": "<heading-text>",
        "category_created": true | false,
        "line": "- [[slug]] — summary",
        "index_path": "<absolute path>"
      },
      "error": ""
    }

    On failure: {"success": false, "data": {}, "error": "..."} with exit 1.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import _wiki_lock  # noqa: E402


HEADING_RE = re.compile(r"^(#{2,3})\s+(.*?)\s*$")
SLUG_LINE_RE_TEMPLATE = r"^(\s*-\s*\[\[){slug}(\]\])"


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def _atomic_write(path: Path, content: str) -> None:
    """Write `content` to `path` atomically."""
    parent = path.parent
    fd, tmp = tempfile.mkstemp(prefix=".index-update-", dir=str(parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def _split_sections(text: str) -> list:
    """Split index.md into a list of (heading_line_or_None, lines_under_it).

    The first element has heading=None and holds any preamble before the
    first `##`/`###` heading (title, intro paragraph, etc.). Every
    subsequent element captures one heading and the lines that belong to
    that heading (up to but not including the next heading).
    """
    lines = text.splitlines(keepends=False)
    sections: list = [(None, [])]
    for line in lines:
        if HEADING_RE.match(line):
            sections.append((line, []))
        else:
            sections[-1][1].append(line)
    return sections


def _join_sections(sections: list) -> str:
    """Inverse of _split_sections. Preserves the original trailing-newline."""
    out_lines: list = []
    for i, (heading, body) in enumerate(sections):
        if heading is not None:
            out_lines.append(heading)
        out_lines.extend(body)
    return "\n".join(out_lines) + "\n"


def _heading_matches_category(heading_line: str, category: str) -> bool:
    """Match `## Foo` or `### Foo` against category="Foo" (case-insensitive)."""
    m = HEADING_RE.match(heading_line)
    if not m:
        return False
    return m.group(2).strip().lower() == category.strip().lower()


def _slug_line_regex(slug: str) -> re.Pattern:
    """Regex matching a bullet line that links to `[[{slug}]]`."""
    return re.compile(SLUG_LINE_RE_TEMPLATE.format(slug=re.escape(slug)))


def _strip_trailing_blanks(body: list) -> tuple:
    """Return (body_without_trailing_blanks, stripped_blanks).

    Keeps section reshuffling from accumulating stray blank lines at the
    end of each heading's body.
    """
    trailing: list = []
    while body and body[-1].strip() == "":
        trailing.append(body.pop())
    return body, trailing


def _find_slug_line_globally(sections: list, slug: str) -> tuple:
    """Return (section_index, line_index) of an existing slug line, or (-1, -1)."""
    slug_re = _slug_line_regex(slug)
    for sec_idx, (_heading, body) in enumerate(sections):
        for line_idx, line in enumerate(body):
            if slug_re.match(line):
                return sec_idx, line_idx
    return -1, -1


def _extract_slug_from_line(line: str) -> str:
    """Extract the slug out of a `- [[slug]] — …` line; empty string if none."""
    m = re.match(r"^\s*-\s*\[\[([a-z0-9][a-z0-9\-]*)\]\]", line)
    return m.group(1) if m else ""


def _insert_alphabetised(body: list, new_line: str, slug: str) -> list:
    """Insert `new_line` into a section's body, keeping `- [[slug]] —` lines
    alphabetised by slug. Non-bullet lines (blank lines, prose paragraphs
    between headings) are preserved in their original positions by only
    reshuffling the contiguous block of bullet-lines we encounter.

    Strategy: find the contiguous run of `- [[...]]` lines, merge in the new
    line, sort by slug, write back. This handles the common case (all
    bullets together) cleanly and leaves any intercalated prose alone.
    """
    body, trailing = _strip_trailing_blanks(list(body))
    # Find the contiguous bullet block (start, end-exclusive).
    first_bullet = -1
    last_bullet = -1
    for i, line in enumerate(body):
        if _extract_slug_from_line(line):
            if first_bullet == -1:
                first_bullet = i
            last_bullet = i
    if first_bullet == -1:
        # No bullets in this section yet. Append the new line at the end,
        # preceded by a blank line if the section had non-blank content.
        if body and body[-1].strip() != "":
            body.append("")
        body.append(new_line)
        body.extend(trailing)
        return body
    bullets = body[first_bullet:last_bullet + 1]
    # Strip any interleaved blanks inside the bullet block so we can resort
    # cleanly; if there were blanks, they were likely layout glue and will
    # be re-emitted as a single post-block blank line.
    bullet_lines = [b for b in bullets if _extract_slug_from_line(b)]
    bullet_lines.append(new_line)
    bullet_lines.sort(key=lambda ln: _extract_slug_from_line(ln))
    new_body = body[:first_bullet] + bullet_lines + body[last_bullet + 1:]
    new_body.extend(trailing)
    return new_body


def _replace_line_in_place(body: list, line_idx: int, new_line: str) -> list:
    """Return a new body with body[line_idx] replaced by `new_line`."""
    out = list(body)
    out[line_idx] = new_line
    return out


def _create_category(sections: list, category: str, new_line: str) -> list:
    """Append a new `## {category}` section containing just `new_line`."""
    # Ensure there is blank-line separation between the existing tail and the
    # new heading so the markdown renders cleanly.
    if sections:
        last_heading, last_body = sections[-1]
        last_body = list(last_body)
        while last_body and last_body[-1].strip() == "":
            last_body.pop()
        last_body.append("")  # single trailing blank before the new heading
        sections[-1] = (last_heading, last_body)
    new_heading = f"## {category}"
    sections.append((new_heading, ["", new_line, ""]))
    return sections


def reflow_categories(text: str) -> tuple:
    """Re-sort every category's contiguous bullet block alphabetically by slug.

    Returns ``(new_text, changed)`` where ``changed`` is True iff any section's
    bullet ordering was modified. Pure function; safe to call inside a
    `_wiki_lock` block without subprocess overhead. Non-bullet lines (prose,
    blank lines outside the bullet block) are preserved in place. Sections
    without any `- [[slug]]` lines are passed through unchanged.

    The contiguous-block strategy mirrors ``_insert_alphabetised`` so reflow
    and insert agree on what counts as a sortable bullet block.
    """
    sections = _split_sections(text)
    changed = False
    for sec_idx, (heading, body) in enumerate(sections):
        body = list(body)
        body, trailing = _strip_trailing_blanks(body)
        first_bullet = -1
        last_bullet = -1
        for i, line in enumerate(body):
            if _extract_slug_from_line(line):
                if first_bullet == -1:
                    first_bullet = i
                last_bullet = i
        if first_bullet == -1:
            # Re-attach trailing blanks unchanged.
            sections[sec_idx] = (heading, body + trailing)
            continue
        bullets = body[first_bullet:last_bullet + 1]
        bullet_lines = [b for b in bullets if _extract_slug_from_line(b)]
        sorted_lines = sorted(bullet_lines, key=lambda ln: _extract_slug_from_line(ln))
        if sorted_lines != bullet_lines:
            changed = True
        new_body = body[:first_bullet] + sorted_lines + body[last_bullet + 1:]
        new_body.extend(trailing)
        sections[sec_idx] = (heading, new_body)
    if not changed:
        return text, False
    return _join_sections(sections), True


def update_index(index_path: Path, slug: str, summary: str, category: str) -> dict:
    """Do the actual edit. Pure function of (file contents, args)."""
    if not index_path.is_file():
        fail(f"index.md not found at {index_path}")

    try:
        text = index_path.read_text(encoding="utf-8")
    except OSError as e:
        fail(f"could not read index.md: {e}")
        return {}

    new_line = f"- [[{slug}]] — {summary}"
    sections = _split_sections(text)

    # Case A: slug already has a line somewhere — update it in place.
    sec_idx, line_idx = _find_slug_line_globally(sections, slug)
    if sec_idx != -1:
        heading, body = sections[sec_idx]
        new_body = _replace_line_in_place(body, line_idx, new_line)
        sections[sec_idx] = (heading, new_body)
        new_text = _join_sections(sections)
        _atomic_write(index_path, new_text)
        return {
            "action": "updated",
            "category": None if heading is None else HEADING_RE.match(heading).group(2).strip(),
            "category_created": False,
            "line": new_line,
            "index_path": str(index_path),
        }

    # Case B: find the target category heading; insert alphabetised.
    for sec_idx, (heading, body) in enumerate(sections):
        if heading is not None and _heading_matches_category(heading, category):
            new_body = _insert_alphabetised(body, new_line, slug)
            sections[sec_idx] = (heading, new_body)
            new_text = _join_sections(sections)
            _atomic_write(index_path, new_text)
            return {
                "action": "inserted",
                "category": HEADING_RE.match(heading).group(2).strip(),
                "category_created": False,
                "line": new_line,
                "index_path": str(index_path),
            }

    # Case C: category doesn't exist — create it with this line.
    sections = _create_category(sections, category, new_line)
    new_text = _join_sections(sections)
    _atomic_write(index_path, new_text)
    return {
        "action": "inserted",
        "category": category.strip(),
        "category_created": True,
        "line": new_line,
        "index_path": str(index_path),
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Insert/update a page's entry in wiki/index.md, preserving alphabetical order."
    )
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")
    parser.add_argument("--slug", help="Slug of the page whose line we're adding/updating (slug mode)")
    parser.add_argument("--summary", help="One-sentence summary shown after the slug wikilink (slug mode)")
    parser.add_argument("--category", help="Category heading text without the leading ##/### (slug mode)")
    parser.add_argument(
        "--reflow-only",
        action="store_true",
        help=(
            "Re-sort every category's bullet block alphabetically by slug. "
            "No insert/update. Used by wiki-lint --fix=alphabetisation."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="With --reflow-only: report whether reordering would happen, without writing.",
    )
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    index_path = wiki_root / "wiki" / "index.md"

    if not (wiki_root / "wiki").is_dir():
        fail(f"wiki/ not found under {wiki_root}")

    if args.reflow_only:
        if not index_path.is_file():
            fail(f"index.md not found at {index_path}")
        with _wiki_lock(wiki_root):
            try:
                text = index_path.read_text(encoding="utf-8")
            except OSError as e:
                fail(f"could not read index.md: {e}")
                return
            new_text, changed = reflow_categories(text)
            if changed and not args.dry_run:
                _atomic_write(index_path, new_text)
        ok({
            "action": "reflowed" if changed else "noop",
            "changed": changed,
            "applied": bool(changed and not args.dry_run),
            "dry_run": bool(args.dry_run),
            "index_path": str(index_path),
        })
        return

    # Slug mode requires --slug, --summary, --category.
    if not (args.slug and args.summary and args.category):
        fail("--slug, --summary, --category are required (or pass --reflow-only)")

    slug = args.slug.strip().lower()
    if not re.match(r"^[a-z0-9][a-z0-9\-]*$", slug):
        fail(f"invalid slug: {args.slug!r} (expected kebab-case: [a-z0-9][a-z0-9-]*)")

    summary = args.summary.strip()
    if not summary:
        fail("--summary must be a non-empty string")

    category = args.category.strip()
    if not category:
        fail("--category must be a non-empty string")

    with _wiki_lock(wiki_root):
        result = update_index(index_path, slug, summary, category)
    ok(result)


if __name__ == "__main__":
    main()
