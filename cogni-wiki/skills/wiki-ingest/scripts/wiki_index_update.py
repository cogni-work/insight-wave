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
                         --category "<heading-text>" \\
                         [--max-summary <chars>]

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
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import _wiki_lock, atomic_write, clamp_summary, fail, ok  # noqa: E402


HEADING_RE = re.compile(r"^(#{2,3})\s+(.*?)\s*$")
SLUG_LINE_RE_TEMPLATE = r"^(\s*-\s*\[\[){slug}(\]\])"

# wiki-setup seeds wiki/index.md with an empty `## Categories` section holding
# this exact placeholder line (skills/wiki-setup/SKILL.md). Once a real page is
# indexed the placeholder is dead weight — script-level callers
# (cogni-knowledge:knowledge-ingest / knowledge-finalize) never run the
# wiki-ingest LLM skill that would otherwise clean it, so it lingered (#306).
SEED_PLACEHOLDER_LINE = "_No pages yet. Run `wiki-ingest` to add your first source._"
SEED_CATEGORY_HEADING = "Categories"

# Slug grammar shared by slug-mode (--slug) and move-mode (--move-slug), kept as
# one constant so the kebab-case contract can't drift between the two paths.
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9\-]*$")


def _validate_slug(slug: str, raw: str) -> None:
    """Fail unless `slug` is kebab-case. `raw` is the user-supplied form, shown
    verbatim in the error so the message points at exactly what they typed."""
    if not SLUG_RE.match(slug):
        fail(f"invalid slug: {raw!r} (expected kebab-case: [a-z0-9][a-z0-9-]*)")


def _read_index_text(index_path: Path) -> str:
    """Read index.md, failing cleanly if it's absent or unreadable. Shared by
    update_index and move_slug so the existence/IO-error contract is identical."""
    if not index_path.is_file():
        fail(f"index.md not found at {index_path}")
    try:
        return index_path.read_text(encoding="utf-8")
    except OSError as e:
        fail(f"could not read index.md: {e}")
        return ""  # unreachable — fail() exits; keeps the type checker happy


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


def _heading_to_key(heading_line: str) -> str:
    """Normalised comparison key for a heading line — the HEADING_RE-captured
    text (or the raw line if it isn't a heading), folded with `.strip().lower()`.

    The single source of truth for "are these the same heading", shared by
    `_heading_matches_category` and `collapse_duplicate_headings` so the two
    paths can't drift on what counts as a match.
    """
    m = HEADING_RE.match(heading_line)
    return (m.group(2) if m else heading_line).strip().lower()


def _heading_matches_category(heading_line: str, category: str) -> bool:
    """Match `## Foo` or `### Foo` against category="Foo" (case-insensitive)."""
    return _heading_to_key(heading_line) == category.strip().lower()


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


def collapse_duplicate_headings(sections: list) -> list:
    """Merge duplicate `## <heading>` sections into the first occurrence.

    Two sections are "the same heading" when their `_heading_to_key` value is
    equal — the same normalised key `_heading_matches_category` compares
    against, so collapse and dispatch agree. The FIRST occurrence survives
    and keeps its body verbatim, including any **curated lead-in** (the
    protected prose between a heading and its first `- [[slug]]` bullet, per the
    #461 Phase-1 contract). Each later duplicate's `- [[slug]]` bullets are
    folded into the survivor via `_insert_alphabetised` (skipping a slug the
    survivor already carries, so the fold is idempotent and never creates a
    duplicate bullet line), and the duplicate's heading shell is dropped. A
    later duplicate's own non-bullet prose is discarded — first lead-in wins;
    a machine-created duplicate from `_create_category` carries only
    `["", bullet, ""]`, so it has no lead-in to lose.

    Pure function. Returns the input list unchanged when every heading is unique
    (no-op on a clean index). The preamble section (heading is None) is never
    merged. This keeps a multi-project portal `index.md` single-instance: a
    second `## <theme>` block created when a prior insert fell through to Case C
    against a heading that didn't case/whitespace-match is collapsed on the next
    write rather than persisting on disk.
    """
    first_idx: dict = {}
    result: list = []
    changed = False
    for heading, body in sections:
        if heading is None:
            result.append((heading, list(body)))
            continue
        key = _heading_to_key(heading)
        if key not in first_idx:
            first_idx[key] = len(result)
            result.append((heading, list(body)))
            continue
        # Duplicate heading: fold its bullets into the first occurrence's body.
        changed = True
        tgt_heading, tgt_body = result[first_idx[key]]
        existing_slugs = {
            slug for ln in tgt_body if (slug := _extract_slug_from_line(ln))
        }
        for line in body:
            slug = _extract_slug_from_line(line)
            if slug and slug not in existing_slugs:
                tgt_body = _insert_alphabetised(tgt_body, line, slug)
                existing_slugs.add(slug)
        result[first_idx[key]] = (tgt_heading, tgt_body)
        # Drop the duplicate heading shell — do not append it to `result`.
    if not changed:
        return sections
    return result


def strip_seed_placeholder(text: str) -> str:
    """Remove the wiki-setup seed placeholder from index.md text (#306).

    wiki-setup seeds index.md with:

        ## Categories

        _No pages yet. Run `wiki-ingest` to add your first source._

    On the first real category insert the placeholder is dead weight. Removes
    the placeholder line wherever it appears, and drops an empty `## Categories`
    heading that has no bullet entries left under it. Confined to the exact seed
    string so a user's real `## Categories` heading carrying content is never
    touched. Idempotent — a no-op once the seed is gone.
    """
    if SEED_PLACEHOLDER_LINE not in text:
        return text
    sections = _split_sections(text)
    new_sections: list = []
    for heading, body in sections:
        # Confine the cleanup to the wiki-setup seed `## Categories` section.
        # A different heading that happens to contain the literal placeholder
        # string (e.g. a user pasted it as a note) is left untouched.
        if heading is not None and _heading_matches_category(
            heading, SEED_CATEGORY_HEADING
        ):
            body = [ln for ln in body if ln.strip() != SEED_PLACEHOLDER_LINE]
            # Drop the heading only when nothing but blank lines remains, so a
            # real `## Categories` carrying bullets OR prose is preserved (the
            # docstring's "real heading with content is never touched" promise).
            if not any(ln.strip() for ln in body):
                continue
        new_sections.append((heading, body))
    return _join_sections(new_sections)


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
    text = _read_index_text(index_path)

    # #306: shed the wiki-setup seed placeholder on the first real insert/update
    # so script-level callers stop inheriting the dead `## Categories` /
    # `_No pages yet…_` block. Idempotent once the seed is gone.
    text = strip_seed_placeholder(text)

    new_line = f"- [[{slug}]] — {summary}"
    sections = _split_sections(text)
    # #485 Phase 1: keep portal `## <theme>` sections single-instance — fold any
    # pre-existing duplicate heading into its first occurrence before dispatch,
    # so Case B always finds the merged section and Case C never adds a third.
    sections = collapse_duplicate_headings(sections)

    # Case A: slug already has a line somewhere — update it in place.
    sec_idx, line_idx = _find_slug_line_globally(sections, slug)
    if sec_idx != -1:
        heading, body = sections[sec_idx]
        new_body = _replace_line_in_place(body, line_idx, new_line)
        sections[sec_idx] = (heading, new_body)
        new_text = _join_sections(sections)
        atomic_write(index_path, new_text)
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
            atomic_write(index_path, new_text)
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
    atomic_write(index_path, new_text)
    return {
        "action": "inserted",
        "category": category.strip(),
        "category_created": True,
        "line": new_line,
        "index_path": str(index_path),
    }


def move_slug(index_path: Path, slug: str, to_category: str) -> dict:
    """Relocate an existing `[[slug]]` entry from its current heading to
    `to_category`, keeping it alphabetised. Non-destructive and idempotent.

    Contract (issue #438 Part A):
    - Find the slug line via `_find_slug_line_globally`. Missing slug → fail.
    - If the line already sits directly under a heading matching `to_category`,
      return ``action: "noop"`` (idempotent — a second call is a no-op).
    - Otherwise remove the line from its source section, re-insert it
      alphabetised under `to_category` (reusing `_insert_alphabetised` /
      `_create_category`), and drop the source heading **only** when nothing
      but blank lines remains under it — the same empty-heading discipline
      `strip_seed_placeholder` uses, so a curated per-theme prose lead-in
      under the source heading is preserved.
    - Never adds or drops a wikilink — only the line's *summary text* moves
      with it, verbatim.
    - Duplicate slugs: `_find_slug_line_globally` returns the **first** match,
      so if a slug somehow appears under two headings only the first occurrence
      relocates. That is intentional — duplicate slugs are a separate defect
      `wiki-health` / `wiki-lint` already surface, and this mode does not try to
      reconcile them.

    A distinct mode from `update_index`: Case A there updates a slug line *in
    place and ignores the category*, which is exactly why a relocation needs
    its own entry point rather than overloading the insert/update path every
    current caller depends on.
    """
    text = _read_index_text(index_path)

    sections = _split_sections(text)
    # #485 Phase 1: collapse any duplicate `## <theme>` heading before locating
    # the slug, so a relocation against a portal that already drifted into two
    # same-theme sections operates on the merged (single-instance) section.
    sections = collapse_duplicate_headings(sections)
    sec_idx, line_idx = _find_slug_line_globally(sections, slug)
    if sec_idx == -1:
        fail(f"slug not found in index: {slug}")
        return {}

    heading, body = sections[sec_idx]

    # Idempotent no-op: already directly under the target heading.
    if heading is not None and _heading_matches_category(heading, to_category):
        return {
            "action": "noop",
            "category": HEADING_RE.match(heading).group(2).strip(),
            "slug": slug,
            "index_path": str(index_path),
        }

    moved_line = body[line_idx]
    new_body = body[:line_idx] + body[line_idx + 1:]
    sections[sec_idx] = (heading, new_body)

    # Drop the source heading only when no non-blank content remains under it
    # (mirrors strip_seed_placeholder; preserves a curated lead-in if present).
    source_heading_dropped = False
    if heading is not None and not any(ln.strip() for ln in new_body):
        del sections[sec_idx]
        source_heading_dropped = True

    # Re-insert alphabetised under the target category (Case B / Case C).
    category_created = False
    placed = False
    for i, (h, b) in enumerate(sections):
        if h is not None and _heading_matches_category(h, to_category):
            sections[i] = (h, _insert_alphabetised(b, moved_line, slug))
            placed = True
            break
    if not placed:
        sections = _create_category(sections, to_category, moved_line)
        category_created = True

    new_text = _join_sections(sections)
    atomic_write(index_path, new_text)
    return {
        "action": "moved",
        "category": to_category.strip(),
        "category_created": category_created,
        "source_heading_dropped": source_heading_dropped,
        "line": moved_line,
        "slug": slug,
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
    parser.add_argument("--move-slug", help="Slug of an existing entry to relocate to --to-category (move mode)")
    parser.add_argument("--to-category", help="Target category heading for --move-slug (move mode)")
    parser.add_argument(
        "--max-summary",
        type=int,
        default=None,
        help="Defensive word-boundary clamp ceiling for --summary (chars); omit to store verbatim.",
    )
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

    # Move mode (#438): relocate an existing entry between headings. Mutually
    # exclusive with slug-mode (--slug/--summary/--category) and --reflow-only
    # so the three write paths never overlap.
    if args.move_slug:
        if args.reflow_only:
            fail("--move-slug cannot be combined with --reflow-only")
        if args.slug or args.summary or args.category:
            fail("--move-slug is mutually exclusive with --slug/--summary/--category")
        if not (args.to_category and args.to_category.strip()):
            fail("--move-slug requires a non-empty --to-category")
        if not index_path.is_file():
            fail(f"index.md not found at {index_path}")
        mv_slug = args.move_slug.strip().lower()
        _validate_slug(mv_slug, args.move_slug)
        to_category = args.to_category.strip()
        with _wiki_lock(wiki_root):
            result = move_slug(index_path, mv_slug, to_category)
        ok(result)
        return

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
                atomic_write(index_path, new_text)
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
    _validate_slug(slug, args.slug)

    summary = args.summary.strip()
    if not summary:
        fail("--summary must be a non-empty string")
    if args.max_summary is not None:
        summary = clamp_summary(summary, args.max_summary)

    category = args.category.strip()
    if not category:
        fail("--category must be a non-empty string")

    with _wiki_lock(wiki_root):
        result = update_index(index_path, slug, summary, category)
    ok(result)


if __name__ == "__main__":
    main()
