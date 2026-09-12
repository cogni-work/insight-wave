#!/usr/bin/env python3
"""parse-brief.py — Parse a presentation brief into one of three machine-readable views.

Reads the presentation-brief grammar (schema 4.1, and the unfenced 4.0 shape with a
warning) and projects it into `slide-data`, `outline` or `metadata`. The brief is
parsed exactly once into a lossless model; each emit mode is a pure projection of
that model, so consumers share one parse instead of each re-deriving it.

Stdlib only — no PyYAML. The grammar the producer writes is a small closed subset
of YAML (scalars, quoted scalars, two-space nested maps, block lists, short flow
lists, and `|` block scalars), so a vendored parser would be more machinery than
the input needs.

The module has no import-time side effects: every entry point is a module-level
function and all CLI work sits behind `if __name__ == "__main__"`, so a consumer
can load it through `importlib.util.spec_from_file_location` the way
`validate-theme-manifest.py` loads its own sibling generator.

Block scalars are preserved byte-for-byte, leading indent included. A consumer that
wants them dedented can dedent; a consumer handed a dedented value cannot recover
the original.

Usage:
    parse-brief.py --brief <path> --emit slide-data|outline|metadata [--output <path>]

Always prints exactly one {"success", "data", "error"} object on stdout, on every
path, and never a traceback.
"""

import argparse
import json
import re
import sys

BLOCK_INDICATORS = ("|", "|-", "|+")

# Copied character-for-character from the citation regex in
# skills/render-html-slides/scripts/generate-html-slides.py so the two cannot
# drift. A superscript without a URL is prose, not a citation, and must not match.
CITATION_RE = re.compile(r'<sup>\[(\d+)\]\(([^)]+)\)</sup>')

SLIDE_HEADING_RE = re.compile(r"^##\s+Slide\s+(\d+)\s*:\s*(.*)$")
QUADRANT_ALIAS_RE = re.compile(r"^Q([1-9]\d*)$")
STEP_KEY_RE = re.compile(r"^Step-([0-9]+)$")

# The eight keys render-html-slides documents, plus the five 4.1 additions. Every
# slide carries all thirteen; an absent one is null or [], never omitted. This is
# the published contract a consumer (and the suite) can read back off the module.
SLIDE_KEYS = (
    "number", "headline", "layout", "fields", "speaker_notes", "bottom_banner",
    "diagram_mermaid", "citations", "slide_kind", "source", "cta", "intent", "visual",
)


class BriefError(Exception):
    """A brief that cannot be parsed. The message names a 1-based source line."""



def emit(success: bool, data=None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


def _indent_of(line):
    return len(line) - len(line.lstrip(" "))


def _is_skippable(line):
    stripped = line.strip()
    return not stripped or stripped.startswith("#")


def _split_flow(body):
    """Split a flow sequence's inner text on top-level commas."""
    parts, buf, depth, quote = [], "", 0, None
    for ch in body:
        if quote:
            buf += ch
            if ch == quote:
                quote = None
            continue
        if ch in ("'", '"'):
            quote = ch
            buf += ch
        elif ch in "[{":
            depth += 1
            buf += ch
        elif ch in "]}":
            depth -= 1
            buf += ch
        elif ch == "," and depth == 0:
            parts.append(buf)
            buf = ""
        else:
            buf += ch
    if buf.strip():
        parts.append(buf)
    return [p.strip() for p in parts]


def _scalar(text):
    """Resolve one plain or quoted scalar.

    Quoted values stay verbatim strings. Bare int / float / bool / null resolve to
    their JSON types; everything else stays a string, so `688` is a number while
    `42%` and a currency amount are not.
    """
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] and text[0] in ("'", '"'):
        return text[1:-1]
    if text.startswith("[") and text.endswith("]"):
        return [_scalar(p) for p in _split_flow(text[1:-1])]
    if text.startswith("{") and text.endswith("}"):
        out = {}
        for part in _split_flow(text[1:-1]):
            key, sep, value = part.partition(":")
            if sep:
                out[key.strip()] = _scalar(value)
        return out
    if text in ("null", "~", ""):
        return None
    if text == "true":
        return True
    if text == "false":
        return False
    try:
        return int(text)
    except ValueError:
        pass
    try:
        return float(text)
    except ValueError:
        pass
    return text


def _parse_block_scalar(lines, i, end, parent_indent, indicator):
    """Collect a `|` block scalar, preserving each source line byte-for-byte.

    The block runs to the first non-blank line indented at or below the parent key;
    a blank line never terminates it. Leading indent is retained deliberately — see
    the module docstring.
    """
    content, last_nonblank = [], -1
    while i < end:
        line = lines[i]
        if line.strip():
            if _indent_of(line) <= parent_indent:
                break
            last_nonblank = len(content)
        content.append(line)
        i += 1
    if indicator == "|+":
        kept = content
    else:
        kept = content[: last_nonblank + 1]
    if not kept:
        return ("" if indicator == "|-" else "\n"), i
    text = "\n".join(kept)
    if indicator != "|-":
        text += "\n"
    return text, i


def _first_content(lines, i, end):
    while i < end and _is_skippable(lines[i]):
        i += 1
    return i if i < end else None


def _parse_value_below(lines, i, end, parent_indent):
    """Parse whatever a bare `key:` introduces — a nested map, a list, or nothing."""
    probe = _first_content(lines, i, end)
    if probe is None:
        return None, i
    child_indent = _indent_of(lines[probe])
    if child_indent <= parent_indent:
        return None, i
    if lines[probe].strip().startswith("- "):
        return _parse_list(lines, probe, end, child_indent)
    return _parse_map(lines, probe, end, child_indent)


def _parse_list(lines, i, end, indent):
    items = []
    while i < end:
        line = lines[i]
        if _is_skippable(line):
            i += 1
            continue
        if _indent_of(line) < indent:
            break
        stripped = line.strip()
        if not stripped.startswith("- "):
            break
        rest = stripped[2:]
        key, sep, _ = rest.partition(":")
        key = key.strip()
        # A quoted item is always a scalar, even when its text contains a colon,
        # and a bare key never contains a space or a quote.
        is_map_item = bool(sep) and bool(key) and " " not in key \
            and key[0] not in ("'", '"') and "'" not in key and '"' not in key
        if not is_map_item:
            items.append(_scalar(rest))
            i += 1
            continue
        # A list item that opens a map: re-indent its first line to the item's own
        # column, then absorb every following line indented past the dash.
        item_indent = indent + 2
        block = [" " * item_indent + rest]
        i += 1
        while i < end and (_is_skippable(lines[i]) or _indent_of(lines[i]) > indent):
            block.append(lines[i])
            i += 1
        parsed, _ = _parse_map(block, 0, len(block), item_indent)
        items.append(parsed)
    return items, i


def _parse_map(lines, i, end, indent):
    result = {}
    while i < end:
        line = lines[i]
        if _is_skippable(line):
            i += 1
            continue
        current = _indent_of(line)
        if current < indent:
            break
        if current > indent:
            i += 1
            continue
        stripped = line.strip()
        if stripped.startswith("- "):
            break
        key, sep, rest = stripped.partition(":")
        if not sep:
            i += 1
            continue
        key, rest = key.strip(), rest.strip()
        if rest in BLOCK_INDICATORS:
            # Only a value that is exactly an indicator opens a block scalar, so a
            # scalar whose text merely contains a pipe stays prose.
            result[key], i = _parse_block_scalar(lines, i + 1, end, current, rest)
        elif rest == "":
            result[key], i = _parse_value_below(lines, i + 1, end, current)
        else:
            result[key] = _scalar(rest)
            i += 1
    return result, i


def parse_yaml_subset(lines):
    """Parse a list of source lines as the brief's YAML subset."""
    start = _first_content(lines, 0, len(lines))
    if start is None:
        return {}
    parsed, _ = _parse_map(lines, start, len(lines), _indent_of(lines[start]))
    return parsed


def _scan_sections(lines):
    """Split the document on `##` headings that sit outside a fence.

    Returns (frontmatter_lines, sections). Raises BriefError naming the opening
    line of any fence still unclosed at EOF — a structurally broken brief must fail
    loudly at a locatable line rather than parse to something plausible.
    """
    index = 0
    frontmatter = []
    if lines and lines[0].strip() == "---":
        for j in range(1, len(lines)):
            if lines[j].strip() == "---":
                frontmatter = lines[1:j]
                index = j + 1
                break

    sections, current = [], None
    fence_open_line = None
    for n in range(index, len(lines)):
        line = lines[n]
        if line.startswith("```"):
            fence_open_line = None if fence_open_line is not None else n + 1
        elif fence_open_line is None and line.startswith("## "):
            current = {"heading": line, "lines": []}
            sections.append(current)
            continue
        if current is not None:
            current["lines"].append(line)
    if fence_open_line is not None:
        raise BriefError(
            "unclosed fenced block opened at line {0}".format(fence_open_line))
    return frontmatter, sections


def _section_body(section):
    """Return (body_lines, was_fenced) for one section."""
    body = section["lines"]
    for n, line in enumerate(body):
        if line.startswith("```"):
            for m in range(n + 1, len(body)):
                if body[m].startswith("```"):
                    return body[n + 1:m], True
            break
    # No fence: the 4.0 shape. The body is everything up to a `---` separator.
    plain = []
    for line in body:
        if line.strip() == "---":
            break
        plain.append(line)
    return plain, False


def _normalize_quadrants(fields, warnings, number):
    """Rename `Q1`..`Q4` to the `Quadrant-N` names the renderer reads.

    The sub-map passes through verbatim. No `Number` is synthesized for an alias
    that carries none — inventing one would render a statistic nobody wrote.
    """
    if not any(QUADRANT_ALIAS_RE.match(key) for key in fields):
        return fields
    out = {}
    for key, value in fields.items():
        match = QUADRANT_ALIAS_RE.match(key)
        if not match:
            out[key] = value
            continue
        canonical = "Quadrant-" + match.group(1)
        if canonical in fields:
            warnings.append(
                "slide {0}: dropped alias {1} because {2} is also present".format(
                    number, key, canonical))
            continue
        warnings.append(
            "slide {0}: normalized alias {1} to {2}".format(number, key, canonical))
        out[canonical] = value
    return out


def _order_steps(fields):
    """Emit `Step-N` keys in ascending numeric order, so Step-10 follows Step-2."""
    steps = [(int(m.group(1)), k) for k in fields if (m := STEP_KEY_RE.match(k))]
    if not steps:
        return fields
    step_keys = {k for _, k in steps}
    ordered = {k: v for k, v in fields.items() if k not in step_keys}
    for _, key in sorted(steps):
        ordered[key] = fields[key]
    return ordered


def _citations(body_lines):
    seen, found = set(), []
    for match in CITATION_RE.finditer("\n".join(body_lines)):
        pair = (int(match.group(1)), match.group(2))
        if pair not in seen:
            seen.add(pair)
            found.append({"n": pair[0], "url": pair[1]})
    return found


def _bottom_banner(fields):
    banner = fields.get("Bottom-Banner")
    if isinstance(banner, dict):
        return banner.get("Text")
    return banner


def _build_slide(unit, match, warnings):
    number = int(match.group(1))
    body, fenced = unit["body_lines"], unit["fenced"]
    if not fenced:
        warnings.append(
            "slide {0}: parsed an unfenced body (schema 4.0 shape)".format(number))
    fields = _order_steps(_normalize_quadrants(dict(unit["fields"]), warnings, number))
    return {
        "number": number,
        "headline": match.group(2).strip(),
        # The layout is the Layout field. Slide-Kind never overrides it.
        "layout": fields.get("Layout"),
        "fields": fields,
        "speaker_notes": fields.get("Speaker-Notes"),
        "bottom_banner": _bottom_banner(fields),
        "diagram_mermaid": fields.get("Diagram"),
        "citations": _citations(body),
        "slide_kind": fields.get("Slide-Kind"),
        "source": fields.get("Source"),
        "cta": fields.get("cta"),
        "intent": fields.get("intent"),
        "visual": fields.get("visual"),
    }


def parse_document(path):
    """Scan any brief type into frontmatter plus its `##` units, type-agnostic.

    This is the half of the parse that does not know what a slide is: every
    `##` section becomes one unit carrying its heading, its body lines, whether
    that body was fenced, and the body parsed as the YAML subset. `parse_brief`
    builds the slides model on top of it, and `check-brief.py` reads it directly
    for the web, storyboard and infographic briefs, whose unit headings differ
    but whose document shape is the same. One scan, so the consumers cannot
    disagree about where a unit starts or whether a fence was closed.
    """
    with open(path, "r", encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    frontmatter_lines, sections = _scan_sections(lines)
    units = []
    for section in sections:
        body, fenced = _section_body(section)
        units.append({
            "heading": section["heading"].strip(),
            "body_lines": body,
            "fenced": fenced,
            "fields": parse_yaml_subset(body),
        })
    return {
        "lines": lines,
        "frontmatter": parse_yaml_subset(frontmatter_lines),
        "sections": units,
    }


def parse_brief(path):
    """Parse a brief file into the lossless model every emit mode projects."""
    document = parse_document(path)
    frontmatter = document["frontmatter"]
    warnings = []

    slides, cta_summary, generation_metadata, unowned = [], None, None, []
    for unit in document["sections"]:
        heading = unit["heading"]
        slide_match = SLIDE_HEADING_RE.match(heading)
        if slide_match:
            slides.append(_build_slide(unit, slide_match, warnings))
            continue
        if heading == "## CTA Summary" and unit["fenced"]:
            cta_summary = unit["fields"]
        elif heading == "## Generation Metadata" and unit["fenced"]:
            generation_metadata = unit["fields"]
        else:
            # An unfenced trailing section is prose the parser does not own.
            unowned.append(heading[3:].strip())

    if generation_metadata is None:
        warnings.append("no Generation Metadata section; emitting null")

    return {
        "version": frontmatter.get("version"),
        "frontmatter": frontmatter,
        "slides": slides,
        "cta_summary": cta_summary,
        "generation_metadata": generation_metadata,
        "unowned_sections": unowned,
        "warnings": warnings,
    }


def emit_slide_data(model):
    return {
        "version": model["version"],
        "slides": model["slides"],
        "warnings": model["warnings"],
    }


def emit_outline(model):
    """A per-slide summary for the Claude Design exporter — never a slide-data dump."""
    entries = []
    for slide in model["slides"]:
        intent = slide["intent"] if isinstance(slide["intent"], dict) else {}
        entries.append({
            "number": slide["number"],
            "headline": slide["headline"],
            "layout": slide["layout"],
            "slide_kind": slide["slide_kind"],
            "role": intent.get("role"),
            "has_diagram": slide["diagram_mermaid"] is not None,
            "citation_count": len(slide["citations"]),
        })
    return {
        "version": model["version"],
        "entries": entries,
        "warnings": model["warnings"],
    }


def emit_metadata(model):
    return {
        "version": model["version"],
        "frontmatter": model["frontmatter"],
        "generation_metadata": model["generation_metadata"],
        "cta_summary": model["cta_summary"],
        "unowned_sections": model["unowned_sections"],
        "warnings": model["warnings"],
    }


EMITTERS = {
    "slide-data": emit_slide_data,
    "outline": emit_outline,
    "metadata": emit_metadata,
}


class _EnvelopeParser(argparse.ArgumentParser):
    """Argument parser that reports usage errors through the JSON envelope."""

    def error(self, message):
        emit(False, None, "argument error: {0}".format(message))
        raise SystemExit(1)


def main() -> int:
    parser = _EnvelopeParser(
        description="Parse a presentation brief into slide-data, an outline, or metadata.")
    parser.add_argument("--brief", help="Path to the presentation brief")
    # --emit is validated by hand rather than with choices= so an unlisted value
    # still answers with an envelope instead of an argparse usage message.
    parser.add_argument("--emit", help="One of: slide-data, outline, metadata")
    parser.add_argument("--output", help="Optional path to write the payload to")
    args = parser.parse_args()

    if not args.brief:
        return emit(False, None, "--brief is required")
    if args.emit not in EMITTERS:
        return emit(False, None, "--emit must be one of: {0}".format(", ".join(EMITTERS)))

    try:
        model = parse_brief(args.brief)
    except BriefError as exc:
        return emit(False, None, str(exc))
    except OSError as exc:
        return emit(False, None, "cannot read brief: {0}".format(exc))
    except Exception as exc:  # never surface a traceback
        return emit(False, None, "unparseable brief: {0}".format(exc))

    payload = EMITTERS[args.emit](model)

    if args.output:
        try:
            with open(args.output, "w", encoding="utf-8") as handle:
                json.dump(payload, handle, indent=2, ensure_ascii=False)
                handle.write("\n")
        except OSError as exc:
            return emit(False, None, "cannot write output: {0}".format(exc))

    return emit(True, payload, "")


if __name__ == "__main__":
    sys.exit(main())
