#!/usr/bin/env python3
"""brief-to-outline.py — export a Claude Design presentation outline from a brief.

Claude Design (claude.ai/design) consumes a prompt plus attachments against an
organization design system. It has no meaning for the brief's `Layout:` vocabulary
(`title-slide`, `is-does-means`, `four-quadrants`, ...); what it needs is an
on-slide vs talk-track split, hero figures, type tags and a design register.
This exporter writes `presentation-outline.md` next to the brief in exactly that
shape, so a consultant hands over an outline instead of a brief and skips the
clarify-then-build round.

Why this is a sibling of `scripts/parse-brief.py` and not its `--emit outline` arm:
that emitter returns a per-slide *summary* (number, headline, layout, slide_kind,
role, has_diagram, citation_count) whose shape is pinned by
`tests/test-parse-brief.sh::pb27-outline-is-an-ordered-summary`. It strips
`fields`, `speaker_notes`, citation URLs, `intent.emphasis` and `source` — i.e.
everything this export needs. Repurposing it would redden that suite. This module
consumes `parse_brief()` directly and leaves the existing payload byte-identical.

Exactly one file owns the layout-to-type mapping, and it is not this one.
`load_type_map()` parses the rows of `## Layout to type mapping` out of
`libraries/presentation-intent.md` at run time, so the library keeps sole
authority. No layout name and no tag string is a literal here. Python owns only
the two resolution rules that table's own Note column states:

  * `four-quadrants` maps to a `/`-separated ordered pair, resolved structurally:
    the first tag (stat-card mode) when any `Quadrant-N` carries a `Number` key,
    else the second (text-card mode).
  * The un-backticked `references slide` row is keyed by `Slide-Kind: references`
    and takes precedence over `Layout`. This does not contradict
    `parse-brief.py`'s "Slide-Kind never overrides" comment, which is about the
    `layout` field, not the type tag.

Copy is frozen. Every `slide_points` line is an on-slide leaf reproduced verbatim,
with `<sup>[N](url)</sup>` reduced to a bare `[N]`; nothing is re-summarised.

Stdlib only. Always prints exactly one {"success", "data", "error"} object on
stdout, on every path including argparse errors, and never a traceback.

Usage:
    brief-to-outline.py --brief <path> [--out <path>] [--include-internal]
"""

import argparse
import importlib.util
import json
import os
import re
import sys

# The cap on on-slide lines per section. The shared vocabulary calls for
# "3-4 short on-slide lines, max"; four is that ceiling.
MAX_SLIDE_POINTS = 4

# `<sup>[N](url)</sup>` -> `[N]`. Deliberately the same shape as parse-brief.py's
# CITATION_RE: a superscript without a URL is prose, not a citation.
CITATION_MARKER_RE = re.compile(r'<sup>\[(\d+)\]\([^)]+\)</sup>')

# A markdown table row in the mapping section: | Layout | tag | Note |
TABLE_ROW_RE = re.compile(r"^\|(?P<cells>.+)\|\s*$")

# The clause-3 sentence that enumerates the closed tag set, so the vocabulary is
# read from the library rather than restated here. It is matched against the whole
# file, never line by line: the clause wraps mid-list in the library, and a
# per-line scan silently returns seven tags instead of eight (dropping `roles`).
TAG_SET_RE = re.compile(r"One of:\s*(?P<tags>(?:`[a-z-]+`\s*,?\s*)+)")

# Keys whose values are not on-slide copy. The first group is the set
# `parse-brief.py::_build_slide` lifts out of `fields` into named model fields —
# structural, presenter-side or diagram data, all reachable as model attributes
# rather than as slide copy. `Bottom-Banner` is deliberately NOT in this group:
# it is lifted too, but it is genuinely on-slide copy and is emitted as a point.
# The second group is the two local exceptions: `Slide-Title` restates the `## `
# heading, and `Icon` is a glyph name rather than copy.
NON_SLIDE_KEYS = frozenset({
    "Layout", "Slide-Kind", "Speaker-Notes", "Source", "Diagram",
    "intent", "visual", "cta",
    "Slide-Title", "Icon",
})

# Speaker-notes sections are split STRUCTURALLY, on the `>>` section-header
# prefix, and taken ordinally: first section is the talk track, second is the
# background. No marker string is a literal here.
#
# This is the same property the sibling renderer keys on —
# `skills/render-html-slides/scripts/generate-html-slides.py` treats any
# `line.startswith(">>")` as a section header and holds no marker list at all.
# `references/09-validation-checklist.md` check 5 requires BOTH sections, in that
# order, and FAILs a slide carrying only one, so the ordinal rule is
# validator-backed. Matching on language-specific literals instead would have
# worked for the two languages someone wrote down and silently produced an empty
# talk_track for any third — EXAMPLE_BRIEF.md carries only the German pair.
SECTION_MARKER_PREFIX = ">>"

# Meta-instructions that travel with every outline, verbatim.
TRAILING_NOTES = (
    "copy is frozen — reproduce every line verbatim",
    "render citations as footnotes and keep the URLs",
    "attach theme.md only when no organization design system is configured",
)


_HERE = os.path.dirname(os.path.abspath(__file__))


class OutlineError(Exception):
    """An outline that cannot be produced. The message says why."""


def emit(success: bool, data=None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


def _walk_up(start, relpath):
    """Find `relpath` by walking up from `start`. Returns a path or None.

    The same idiom `skills/pick-theme/scripts/discover-themes.py` uses to reach a
    sibling module, so the exporter runs from any working directory.
    """
    current = os.path.abspath(start)
    while True:
        candidate = os.path.join(current, relpath)
        if os.path.isfile(candidate):
            return candidate
        parent = os.path.dirname(current)
        if parent == current:
            return None
        current = parent


def _locate(*parts):
    """Find a plugin-relative file, from the repo root or from a plugin root.

    Two probes: the repo layout (`<X>/cogni-workspace/<parts>`) and the installed
    plugin layout, where `$CLAUDE_PLUGIN_ROOT` already IS `cogni-workspace/` and
    the walk-up never sees that component. The error names the canonical path so
    a miss says which file is missing, not merely that a walk failed.
    """
    rel = os.path.join(*parts)
    path = _walk_up(_HERE, os.path.join("cogni-workspace", rel))
    if path is None:
        path = _walk_up(_HERE, rel)
    if path is None:
        raise OutlineError("cannot locate cogni-workspace/{0}".format(
            rel.replace(os.sep, "/")))
    return path


def load_parser():
    """Load parse-brief.py as a module and return it."""
    path = _locate("scripts", "parse-brief.py")
    spec = importlib.util.spec_from_file_location("_parse_brief", path)
    if spec is None or spec.loader is None:
        raise OutlineError("cannot load parse-brief.py at {0}".format(path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def locate_library():
    """Locate libraries/presentation-intent.md — the mapping's sole authority."""
    return _locate("libraries", "presentation-intent.md")


def _unbacktick(cell):
    return cell.strip().strip("`").strip()


def load_type_map(library_path):
    """Parse the layout-to-type mapping out of the library at run time.

    Returns {"layouts": {layout: [tag, ...]}, "references_tag": tag,
             "tags": [tag, ...]}. The exporter holds no layout name and no tag
    string as a literal, so the library cannot drift from the code.
    """
    with open(library_path, "r", encoding="utf-8") as handle:
        text = handle.read()
    lines = text.splitlines()

    tags = []
    match = TAG_SET_RE.search(text)
    if match:
        tags = [t for t in map(_unbacktick, match.group("tags").split(",")) if t]

    in_section = False
    layouts, references_tag = {}, None
    for line in lines:
        if line.startswith("## "):
            in_section = line.strip() == "## Layout to type mapping"
            continue
        if not in_section:
            continue
        row = TABLE_ROW_RE.match(line)
        if not row:
            continue
        cells = [c.strip() for c in row.group("cells").split("|")]
        if len(cells) < 2:
            continue
        left, right = cells[0], cells[1]
        if not left or left.startswith("---") or right.startswith("---"):
            continue
        if left == "Layout":  # the header row
            continue
        resolved = [part for part in map(_unbacktick, right.split("/")) if part]
        if not resolved:
            continue
        if left.startswith("`"):
            layouts[_unbacktick(left)] = resolved
        else:
            # The un-backticked `references slide` row: tagged by Slide-Kind,
            # not laid out, and with no layout name of its own.
            references_tag = resolved[0]

    if not layouts:
        raise OutlineError(
            "no layout rows found in {0} — the mapping table moved or changed shape".format(
                library_path))
    if references_tag is None:
        raise OutlineError(
            "no references-slide row found in {0}".format(library_path))
    if not tags:
        raise OutlineError(
            "no tag vocabulary found in {0} — the 'One of:' clause moved".format(
                library_path))
    return {"layouts": layouts, "references_tag": references_tag, "tags": tags}


def _quadrant_numbers(fields):
    """Every `Quadrant-N.Number` present. Stat-card mode iff this is non-empty."""
    found = []
    for key, value in fields.items():
        if not key.startswith("Quadrant-"):
            continue
        if isinstance(value, dict) and value.get("Number") is not None:
            found.append(value["Number"])
    return found


def resolve_type(slide, type_map):
    """The `type:` tag for one slide, per the library's own two Note-column rules."""
    if slide.get("slide_kind") == "references":
        return type_map["references_tag"]
    layout = slide.get("layout")
    resolved = type_map["layouts"].get(layout)
    if not resolved:
        return None
    if len(resolved) == 1:
        return resolved[0]
    # An ordered pair: stat-card mode first, text-card mode second.
    fields = slide.get("fields") or {}
    return resolved[0] if _quadrant_numbers(fields) else resolved[1]


def reduce_citations(text):
    """`<sup>[N](url)</sup>` -> `[N]`, leaving the copy otherwise untouched."""
    return CITATION_MARKER_RE.sub(r"[\1]", text)


def _leaves(value, key=None):
    """Every on-slide scalar under `value`, in document order."""
    if key is not None and key in NON_SLIDE_KEYS:
        return []
    if isinstance(value, dict):
        out = []
        for sub_key, sub_value in value.items():
            out.extend(_leaves(sub_value, sub_key))
        return out
    if isinstance(value, list):
        out = []
        for item in value:
            out.extend(_leaves(item))
        return out
    if value is None or isinstance(value, bool):
        return []
    text = str(value).strip()
    return [text] if text else []


def _lanes(value, key=None):
    """Split one on-slide field into round-robin lanes.

    A field's scalar leaves share one lane, but a LIST-valued sub-key gets its
    own. `Context-Box` is the motivating shape: its `Headline` is a label and its
    `Bullets` are the slide's actual evidence lines — the only ones carrying
    citations. Sharing one lane, the headline always wins depth 0 and the bullets
    are never reached on a slide whose field count already equals the cap, so no
    cited line ever reaches the outline.
    """
    if key is not None and key in NON_SLIDE_KEYS:
        return []
    if isinstance(value, list):
        out = []
        for item in value:
            out.extend(_leaves(item))
        return [out] if out else []
    if isinstance(value, dict):
        own, extra = [], []
        for sub_key, sub_value in value.items():
            if isinstance(sub_value, list):
                extra.extend(_lanes(sub_value, sub_key))
            else:
                own.extend(_leaves(sub_value, sub_key))
        return ([own] if own else []) + extra
    leaves = _leaves(value, key)
    return [leaves] if leaves else []


def _field_lines(slide):
    """The slide's on-slide lanes, in document order, deduped across the slide."""
    grouped, seen = [], set()
    for key, value in (slide.get("fields") or {}).items():
        for lane in _lanes(value, key):
            lines = []
            for leaf in lane:
                reduced = reduce_citations(leaf).strip()
                if reduced and reduced not in seen:
                    seen.add(reduced)
                    lines.append(reduced)
            if lines:
                grouped.append(lines)
    return grouped


def slide_points(slide):
    """Up to MAX_SLIDE_POINTS on-slide lines, spread across the slide's fields.

    Selection is round-robin over the top-level on-slide fields, not a positional
    truncation of one flat list. A slide whose first field carries four leaves
    would otherwise consume the entire budget and drop every later field: on this
    corpus that lost all four quadrant labels of a four-quadrant slide, and the
    third layer of an is-does-means slide. Round-robin takes one line from every
    field before taking a second from any, so four lines represent the whole
    slide instead of its first box.

    Every emitted line is still one leaf reproduced verbatim, with
    `<sup>[N](url)</sup>` reduced to a bare `[N]` — never a join of several
    leaves, which would no longer appear in the brief and would break the
    copy-is-frozen contract the outline itself asserts.
    """
    grouped = _field_lines(slide)
    points = []
    for depth in range(max((len(group) for group in grouped), default=0)):
        for lines in grouped:
            if depth < len(lines):
                points.append(lines[depth])
                if len(points) >= MAX_SLIDE_POINTS:
                    return points
    return points


def dropped_count(slide):
    """On-slide lines the cap left out. Surfaced as a warning, never silently."""
    return max(0, sum(len(g) for g in _field_lines(slide)) - len(slide_points(slide)))


def _trim(block):
    """Strip trailing whitespace per line, then drop leading/trailing blanks."""
    lines = [line.rstrip() for line in block]
    start, end = 0, len(lines)
    while start < end and not lines[start].strip():
        start += 1
    while end > start and not lines[end - 1].strip():
        end -= 1
    return lines[start:end]


def split_sections(speaker_notes):
    """Split Speaker-Notes into its `>>`-headed sections, in document order."""
    sections = []
    current = None
    for line in str(speaker_notes or "").splitlines():
        if line.strip().startswith(SECTION_MARKER_PREFIX):
            current = []
            sections.append(current)
            continue
        if current is not None:
            current.append(line)
    return sections


def split_notes(speaker_notes, source):
    """Split Speaker-Notes into (talk_track, notes), ordinally by section.

    Section 1 is the talk track, section 2 the background. A slide whose notes
    carry no `>>` header at all keeps every line as talk track, which is the
    same fallback the marker-matching form had.

    `Source` is appended to `notes` even when a slide carries no Speaker-Notes,
    so a cited slide never loses its provenance.
    """
    sections = split_sections(speaker_notes)
    if sections:
        talk = sections[0]
        know = sections[1] if len(sections) > 1 else []
    elif speaker_notes:
        talk, know = str(speaker_notes).splitlines(), []
    else:
        talk, know = [], []

    talk, know = _trim(talk), _trim(know)
    if source:
        know = know + ([""] if know else []) + ["Source: {0}".format(str(source).strip())]
    return talk, know


def key_figures(slides):
    """Hero numbers, each marked with its slide's own first citation.

    Collected from every `Hero-Stat-Box.Number` and every stat-mode
    `Quadrant-N.Number` — never the frontmatter `key_figures:` list, which
    disagrees with the slides (it says `73% Infrastruktur veraltet` while
    Slide 5 says `42%`).
    """
    figures, seen = [], set()
    for slide in slides:
        fields = slide.get("fields") or {}
        numbers = []
        hero = fields.get("Hero-Stat-Box")
        if isinstance(hero, dict) and hero.get("Number") is not None:
            numbers.append(hero["Number"])
        numbers.extend(_quadrant_numbers(fields))
        citations = slide.get("citations") or []
        marker = " (src: [{0}])".format(citations[0]["n"]) if citations else ""
        for number in numbers:
            text = str(number).strip()
            if not text or text in seen:
                continue
            seen.add(text)
            figures.append("{0}{1}".format(text, marker))
    return figures


def climax_line(slides):
    """The emphasis slide, rendered with its headline.

    Derived from the per-slide `intent.emphasis` scan rather than the
    frontmatter `climax:` integer, so it is provably not a copy of it.
    """
    for slide in slides:
        intent = slide.get("intent")
        if isinstance(intent, dict) and intent.get("emphasis") == "climax":
            return "Slide {0} — {1}".format(slide["number"], slide["headline"])
    return None


def _render_block(key, value):
    """One `design:` sub-key line, two-space indented under its parent."""
    if isinstance(value, list):
        return "  {0}: [{1}]".format(key, ", ".join(str(item) for item in value))
    return "  {0}: {1}".format(key, value)


def build_outline(model, include_internal, type_map):
    """Render the outline markdown. One `## ` section per included slide."""
    frontmatter = model.get("frontmatter") or {}
    slides = [s for s in model.get("slides") or []
              if include_internal or s.get("slide_kind") != "internal-prep"]

    out = ["---"]
    design = frontmatter.get("design")
    if isinstance(design, dict) and design:
        out.append("design:")
        for key, value in design.items():
            out.append(_render_block(key, value))
    figures = key_figures(slides)
    if figures:
        out.append("key_figures:")
        out.extend("  - {0}".format(figure) for figure in figures)
    climax = climax_line(slides)
    if climax:
        out.append("climax: {0}".format(climax))
    out.append("---")
    out.append("")

    untyped, truncated = [], []
    for slide in slides:
        tag = resolve_type(slide, type_map)
        if tag is None:
            untyped.append(slide["number"])
        dropped = dropped_count(slide)
        if dropped:
            truncated.append((slide["number"], dropped))
        out.append("## {0}".format(slide["headline"]))
        out.append("")
        out.append("type: {0}".format(tag if tag else "unknown"))
        out.append("")
        points = slide_points(slide)
        if points:
            out.append("slide_points:")
            out.extend("- {0}".format(point) for point in points)
            out.append("")
        talk, notes = split_notes(slide.get("speaker_notes"), slide.get("source"))
        if talk:
            out.append("talk_track:")
            out.extend(talk)
            out.append("")
        if notes:
            out.append("notes:")
            out.extend(notes)
            out.append("")

    for note in TRAILING_NOTES:
        out.append("note: {0}".format(note))
    out.append("")
    return "\n".join(out), slides, figures, untyped, truncated


class _EnvelopeParser(argparse.ArgumentParser):
    """argparse that fails through the JSON envelope, never a usage traceback."""

    def error(self, message):
        emit(False, error="argument error: {0}".format(message))
        raise SystemExit(1)


def main() -> int:
    parser = _EnvelopeParser(
        description="Export a Claude Design presentation outline from a brief.")
    parser.add_argument("--brief", required=True, help="path to the presentation brief")
    parser.add_argument("--out", default=None,
                        help="output path (default: presentation-outline.md next to the brief)")
    parser.add_argument("--include-internal", action="store_true",
                        help="include Slide-Kind: internal-prep slides")
    args = parser.parse_args()

    brief_path = os.path.abspath(args.brief)
    if not os.path.isfile(brief_path):
        return emit(False, error="brief not found: {0}".format(args.brief))

    out_path = os.path.abspath(args.out) if args.out else os.path.join(
        os.path.dirname(brief_path), "presentation-outline.md")

    parser_module = load_parser()
    model = parser_module.parse_brief(brief_path)
    type_map = load_type_map(locate_library())
    # `build_outline` owns the internal-prep filter and returns the slide list it
    # actually rendered, so the envelope reports the same set the file contains
    # rather than re-deriving it from a second copy of the predicate.
    text, slides, figures, untyped, truncated = build_outline(
        model, args.include_internal, type_map)

    out_dir = os.path.dirname(out_path)
    if out_dir and not os.path.isdir(out_dir):
        os.makedirs(out_dir, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        handle.write(text)

    warnings = list(model.get("warnings") or [])
    if untyped:
        warnings.append("no type tag resolved for slide(s): {0}".format(
            ", ".join(str(n) for n in untyped)))
    if truncated:
        # Never silent: the outline asserts the copy is frozen, so a slide whose
        # on-slide copy did not fit MAX_SLIDE_POINTS has to say so.
        warnings.append(
            "slide_points capped at {0}; on-slide lines not carried: {1}".format(
                MAX_SLIDE_POINTS,
                ", ".join("slide {0} (-{1})".format(n, d) for n, d in truncated)))

    return emit(True, {
        "outline_path": out_path,
        "sections": len(slides),
        "key_figures": figures,
        "include_internal": args.include_internal,
        "warnings": warnings,
    })


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OutlineError, OSError, ValueError) as exc:
        raise SystemExit(emit(False, error=str(exc)))
    except Exception as exc:  # never a traceback on stdout
        raise SystemExit(emit(False, error="{0}: {1}".format(type(exc).__name__, exc)))
