#!/usr/bin/env python3
"""Lint a design brief against its machine-checkable rules.

The design brief is the one file text-to-narrative hands to Claude Design. Its
copy is selected from a finished narrative and never rewritten, its length is
capped by the target's density ceilings, and it carries the Rendering Contract
and the Sources block so the renderer needs nothing else. This script grades all
of that mechanically; the judged gates stay in the skill's Phase 7 prose.

Usage:
    check-design-brief.py --brief design-brief.md --narrative insight-summary.md [--ceilings PATH]
                          [--max-units N] [--json] [--list-checks]

Every ceiling is read at run time from the skill's references/density-ceilings.md
(`## {target}` table) — the reference keeps sole authority and no number is a
literal here; a table missing a key the target needs is exit 2 naming the key.
`--max-units` lowers the unit ceiling on slides (units_max_default), infographic
(blocks_max / blocks_max_dense) and web (sections_max); the document target's
count is fixed at four sections, so the flag is ignored there and the envelope
says so. A ceilings file that cannot be read, a target section that carries
no rows, an unreadable brief or narrative, and an empty brief are all exit 2:
the brief cannot be graded, which is a different outcome from a brief that fails.

Checks (name — what fails it):
  frontmatter-type       type is not `design-brief` or version is not "1.1"
  target-enum            target not in slides|document|infographic|web, language not en|de
  contract-present       no localized `# Rendering Contract` between the title and unit 1
  contract-clauses       fewer than five `- ` clauses under the contract heading
  unit-numbering         units not `## <Kind> N:` from 1 without gaps, kind wrong for target
  slides-open-bluf       slides only: unit 1 is not `type: bluf` (the deck must open on
                         the Executive TL;DR, never a standalone cover)
  slides-close-sources   slides only: the last unit is not `type: sources` (the deck must
                         close on the source register built from the Sources block)
  density-frontmatter    density.ceilings differs from the reference row for the target
  density-<target>       a unit or preamble field exceeds the target's ceilings
  copy-frozen-numbers    a number on the brief — units, preamble, title, subtitle,
                         governing_thought, key_figures — does not occur in the narrative
  citations-resolve      a `[N]` marker has no `[N] ` Sources entry, or a `<sup>` survives
  key-figures-src        a key_figures / hero_numbers entry lacks a resolvable `(src: [N])`
  no-styling-keys        a styling key (Background:, Text-Color:, fill:, ...) appears
  evidence-status        slides only: an optional evidence_status value is not one of
                         direct|triangulated|proxy|interpretation|mixed
  visual-intent          a copy-bearing slides unit carries no visual_intent block; the block
                         is not a mapping; it carries an unknown key; a required subkey
                         (message_pattern, relationship, focal_point) is missing or empty;
                         message_pattern, preferred_expression or asset_signal is out of
                         enum; or any visual_intent appears on the document target

Exit 0 when no check fails, 1 when any does, 2 when the brief cannot be graded.
Envelope on stdout: {"success": bool, "data": {...}, "error": str}.

Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys

TARGETS = ("slides", "document", "infographic", "web")
LANGUAGES = ("en", "de")
BRIEF_TYPE = "design-brief"
BRIEF_VERSION = "1.1"
UNIT_KIND = {"slides": "Slide", "document": "Section", "infographic": "Block", "web": "Section"}
CONTRACT_HEADINGS = {"en": "# Rendering Contract", "de": "# Rendering-Vertrag"}
CONTRACT_MIN_CLAUSES = 5
TYPE_ENUM = ("cover", "bluf", "two-column", "table", "timeline", "quote", "metric", "roles", "sources")
EVIDENCE_STATUSES = ("direct", "triangulated", "proxy", "interpretation", "mixed")
PROFILES = ("standard", "dense")

# The visual_intent block — the relationship the audience must perceive, never how it is drawn.
# references/visual-intent.md is the sole authority; these tuples must stay set-equal to its lists.
VISUAL_INTENT_REQUIRED = ("message_pattern", "relationship", "focal_point")
VISUAL_INTENT_OPTIONAL = ("preferred_expression", "asset_signal", "avoid")
MESSAGE_PATTERNS = ("comparison", "shift", "convergence", "hierarchy", "sequence", "positioning",
                   "composition", "causality", "distribution", "system", "trajectory", "decision")
PREFERRED_EXPRESSIONS = ("none", "metric", "comparison", "timeline", "positioning-map", "ecosystem-map",
                        "flow", "spectrum", "matrix", "architecture", "geography", "chart", "table", "quote")
ASSET_SIGNALS = ("none", "data-chart", "diagram", "geography", "logos", "photography")
VISUAL_INTENT_ENUMS = {
    "message_pattern": MESSAGE_PATTERNS,
    "preferred_expression": PREFERRED_EXPRESSIONS,
    "asset_signal": ASSET_SIGNALS,
}

UNIT_RE = re.compile(r"^## (Slide|Section|Block) (\d+): (.*)$", re.M)
KEY_RE = re.compile(r"^([a-z_]+):(.*)$")
NUMBER_RE = re.compile(r"\d+(?:[.,]\d+)*")
MARKER_RE = re.compile(r"\[(\d+)\]")
SRC_RE = re.compile(r"\(src: \[(\d+)\]\)\s*$")
SOURCES_ENTRY_RE = re.compile(r"^\s*(?:-\s*)?\[(\d+)\]\s")
SUP_RE = re.compile(r"<sup>.*?</sup>", re.S)
STYLING_KEY_RE = re.compile(
    r"^\s*(Background|Text-Color|Icon-Color|Role|Intensity|Mood|Fill|Border-Color|fill|color|background|textColor):",
    re.M,
)
SENTENCE_END_RE = re.compile(r"[.!?](?:\s|$)")

DEFAULT_CEILINGS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "references", "density-ceilings.md")
REQUIRED_KEYS = {
    "slides": ("headline_chars_max", "slide_points_max_lines", "slide_point_words_max", "slide_point_words_max_table",
               "talk_track_words_min", "talk_track_words_max", "units_min", "units_max_default"),
    "document": ("target_length_default", "band_lower", "band_upper", "summary_words_min", "summary_words_max",
                 "summary_sentences_min", "summary_sentences_max", "sections"),
    "infographic": ("headline_words_max", "subline_words_max", "hero_numbers_min", "hero_numbers_max", "hero_label_words_max",
                    "blocks_min", "blocks_max", "blocks_max_dense", "point_words_max", "words_max", "words_max_dense"),
    "web": ("hero_headline_words_max", "hero_subline_words_max", "section_headline_words_max", "headline_chars_max",
            "section_body_words_max", "bullet_words_max", "quote_words_max", "attribution_words_max", "sections_min", "sections_max"),
}


class CheckError(Exception):
    """The brief cannot be graded — exit 2, never a finding."""


# --------------------------------------------------------------------------- io


def read(path: str, what: str) -> str:
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError as exc:
        raise CheckError(f"cannot read {what} {path}: {exc.strerror}") from exc


def words(text: str) -> int:
    """Whitespace tokens, with `[N]` citation markers excluded — they render as superscripts."""
    return len(MARKER_RE.sub("", text).split())


def sentences(text: str) -> int:
    return len(SENTENCE_END_RE.findall(text.strip()))


# ---------------------------------------------------------------- frontmatter


def _scalar(raw: str):
    raw = raw.strip()
    if raw.startswith("[") and raw.endswith("]"):
        inner = raw[1:-1].strip()
        return [_scalar(x) for x in inner.split(",")] if inner else []
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "\"'":
        return raw[1:-1]
    if re.fullmatch(r"-?\d+", raw):
        return int(raw)
    if re.fullmatch(r"-?\d+\.\d+", raw):
        return float(raw)
    return raw


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """A small YAML subset: scalars, quoted strings, inline lists, nested mappings and
    `- ` lists by two-space indentation. Returns (mapping, body-after-frontmatter)."""
    if not text.startswith("---\n"):
        raise CheckError("brief carries no frontmatter")
    end = text.find("\n---", 4)
    if end < 0:
        raise CheckError("frontmatter is not closed")
    block = text[4:end]
    body = text[end + 4:]
    lines = [ln.rstrip() for ln in block.splitlines()]

    def parse_block(idx: int, indent: int):
        result: dict | list | None = None
        while idx < len(lines):
            line = lines[idx]
            if not line.strip() or line.lstrip().startswith("#"):
                idx += 1
                continue
            cur = len(line) - len(line.lstrip(" "))
            if cur < indent:
                break
            if cur > indent:
                raise CheckError(f"frontmatter indentation error at line: {line.strip()!r}")
            stripped = line.strip()
            if stripped.startswith("- "):
                if result is None:
                    result = []
                if not isinstance(result, list):
                    raise CheckError(f"frontmatter mixes list and mapping at: {stripped!r}")
                result.append(_scalar(stripped[2:]))
                idx += 1
                continue
            m = KEY_RE.match(stripped)
            if not m:
                raise CheckError(f"frontmatter line is not key: value — {stripped!r}")
            if result is None:
                result = {}
            if not isinstance(result, dict):
                raise CheckError(f"frontmatter mixes list and mapping at: {stripped!r}")
            key, value = m.group(1), m.group(2).strip()
            if value:
                result[key] = _scalar(value)
                idx += 1
            else:
                child, idx = parse_block(idx + 1, indent + 2)
                result[key] = child if child is not None else {}
        return result, idx

    parsed, _ = parse_block(0, 0)
    if not isinstance(parsed, dict):
        raise CheckError("frontmatter is not a mapping")
    return parsed, body


# ------------------------------------------------------------------- ceilings


def load_ceilings(path: str, target: str) -> dict:
    """The `## {target}` pipe table of the ceilings reference, parsed at run time."""
    text = read(path, "ceilings reference")
    section = None
    rows: dict = {}
    for line in text.splitlines():
        m = re.match(r"^## ([a-z]+)\s*$", line)
        if m:
            section = m.group(1)
            continue
        if section != target:
            continue
        m = re.match(r"^\| `([a-z_]+)` \| ([0-9.]+) \|", line)
        if m:
            raw = m.group(2)
            rows[m.group(1)] = float(raw) if "." in raw else int(raw)
    if not rows:
        raise CheckError(f"ceilings reference {path} carries no rows for target {target!r}")
    missing = [k for k in REQUIRED_KEYS.get(target, ()) if k not in rows]
    if missing:
        raise CheckError(f"ceilings reference {path} lacks {', '.join(missing)} for target {target!r}")
    return rows


# ----------------------------------------------------------------- brief model


def parse_fields(segment: str) -> dict:
    """Column-0 `key:` fields of one segment: inline scalar, `- ` list, indented
    mapping, or a prose block running to the next key. A key seen twice
    (`note:`) accumulates into a list."""
    fields: dict = {}
    lines = segment.splitlines()
    i = 0
    while i < len(lines):
        m = KEY_RE.match(lines[i])
        if not m:
            i += 1
            continue
        key, inline = m.group(1), m.group(2).strip()
        i += 1
        if inline:
            value = inline
        else:
            items, prose, mapping = [], [], {}
            while i < len(lines):
                ln = lines[i]
                if KEY_RE.match(ln) or UNIT_RE.match(ln) or ln.startswith("**Sources**") or ln.startswith("# "):
                    break
                if ln.startswith("- "):
                    items.append(ln[2:].strip())
                elif ln.startswith("  ") and ":" in ln:
                    k, _, v = ln.strip().partition(":")
                    mapping[k.strip()] = v.strip()
                elif ln.strip():
                    prose.append(ln.strip())
                elif prose and not items and not mapping:
                    # a blank line ends a prose block only when a key follows
                    j = i + 1
                    while j < len(lines) and not lines[j].strip():
                        j += 1
                    if j >= len(lines) or KEY_RE.match(lines[j]) or UNIT_RE.match(lines[j]) or lines[j].startswith("**Sources**") or lines[j].startswith("# "):
                        i = j
                        break
                    prose.append("")
                i += 1
            value = items if items else mapping if mapping else " ".join(p for p in prose if p)
        if key in fields:
            fields[key] = (fields[key] if isinstance(fields[key], list) and key == "note" else [fields[key]]) + [value]
        else:
            fields[key] = value
    return fields


class Brief:
    def __init__(self, path: str, narrative_path: str, ceilings_path: str, max_units: int | None):
        self.path = path
        text = read(path, "brief")
        if not text.strip():
            raise CheckError(f"brief {path} is empty")
        self.fm, body = parse_frontmatter(text)
        self.target = str(self.fm.get("target", ""))
        self.language = str(self.fm.get("language", ""))
        self.max_units = max_units
        self.findings: list[dict] = []
        self.checks_run: list[str] = []
        self.notes: list[str] = []

        # Sources block: everything from the `**Sources**` line on.
        src_at = body.find("\n**Sources**")
        self.body = body[:src_at] if src_at >= 0 else body
        self.sources_block = body[src_at:] if src_at >= 0 else ""
        self.sources = {int(m.group(1)) for m in (SOURCES_ENTRY_RE.match(ln) for ln in self.sources_block.splitlines()) if m}

        # Units and the segments around them.
        matches = list(UNIT_RE.finditer(self.body))
        self.preamble = self.body[: matches[0].start()] if matches else self.body
        self.units: list[dict] = []
        for n, m in enumerate(matches):
            end = matches[n + 1].start() if n + 1 < len(matches) else len(self.body)
            seg = self.body[m.end():end]
            self.units.append({
                "kind": m.group(1), "number": int(m.group(2)), "headline": m.group(3).strip(),
                "fields": parse_fields(seg), "raw": seg,
            })
        # Trailer keys (note:, cta:) live in the last unit's segment; hoist them.
        self.trailer: dict = {}
        if self.units:
            for key in ("note", "cta"):
                if key in self.units[-1]["fields"]:
                    self.trailer[key] = self.units[-1]["fields"].pop(key)
        self.pre = parse_fields(self.preamble)

        narrative = read(narrative_path, "narrative")
        nfm_end = narrative.find("\n---", 4) if narrative.startswith("---\n") else -1
        narrative_body = narrative[nfm_end + 4:] if nfm_end >= 0 else narrative
        self.narrative_headings = re.findall(r"^## (.+?)\s*$", narrative_body, re.M)
        self.narrative_numbers = set(NUMBER_RE.findall(SUP_RE.sub("", narrative_body)))

        self.ceilings = load_ceilings(ceilings_path, self.target) if self.target in TARGETS else {}

    # ---- helpers
    def fail(self, check: str, unit, detail: str) -> None:
        self.findings.append({"check": check, "severity": "fail", "unit": unit, "detail": detail})

    def on_brief_copy(self) -> list[tuple[object, str]]:
        """(unit-or-None, text) pairs of copy the renderer puts on the page — never
        talk_track or notes."""
        out: list[tuple[object, str]] = []
        for key in ("executive_summary", "headline", "subline", "cta"):
            if isinstance(self.pre.get(key), str):
                out.append((None, self.pre[key]))
        hero = self.pre.get("hero")
        if isinstance(hero, dict):
            out.extend((None, v) for v in hero.values())
        for item in self.pre.get("hero_numbers", []) if isinstance(self.pre.get("hero_numbers"), list) else []:
            out.append((None, SRC_RE.sub("", item).replace(" — ", " ")))
        for u in self.units:
            out.append((u["number"], u["headline"]))
            f = u["fields"]
            for key in ("slide_points", "points", "bullets"):
                for item in f.get(key, []) if isinstance(f.get(key), list) else []:
                    out.append((u["number"], item))
            for key in ("body", "quote", "attribution"):
                if isinstance(f.get(key), str):
                    out.append((u["number"], f[key]))
        if isinstance(self.trailer.get("cta"), str):
            out.append((None, self.trailer["cta"]))
        return out

    def frontmatter_copy(self) -> list[tuple[object, str]]:
        """Copy the renderer surfaces from the frontmatter and the title block: the title,
        the subtitle line, governing_thought and every key_figures entry."""
        out: list[tuple[object, str]] = []
        for key in ("title", "governing_thought"):
            if isinstance(self.fm.get(key), str):
                out.append((key, self.fm[key]))
        kf = self.fm.get("key_figures")
        for entry in kf if isinstance(kf, list) else []:
            out.append(("key_figures", SRC_RE.sub("", str(entry))))
        for ln in self.preamble.splitlines():
            if ln.startswith("# ") and ln not in CONTRACT_HEADINGS.values():
                out.append(("title", ln[2:]))
            elif ln.startswith("*") and ln.endswith("*") and len(ln) > 2:
                out.append(("subtitle", ln[1:-1]))
        return out

    def brief_word_count(self) -> int:
        return sum(words(t) for _, t in self.on_brief_copy())


# --------------------------------------------------------------------- checks


def check_frontmatter_type(b: Brief) -> None:
    if b.fm.get("type") != BRIEF_TYPE:
        b.fail("frontmatter-type", None, f"type is {b.fm.get('type')!r}, expected {BRIEF_TYPE!r}")
    if str(b.fm.get("version")) != BRIEF_VERSION:
        b.fail("frontmatter-type", None, f"version is {b.fm.get('version')!r}, expected {BRIEF_VERSION!r}")


def check_target_enum(b: Brief) -> None:
    if b.target not in TARGETS:
        b.fail("target-enum", None, f"target {b.target!r} is not one of {', '.join(TARGETS)}")
    if b.language not in LANGUAGES:
        b.fail("target-enum", None, f"language {b.language!r} is not one of {', '.join(LANGUAGES)}")
    density = b.fm.get("density")
    profile = density.get("profile") if isinstance(density, dict) else None
    if profile not in PROFILES:
        b.fail("target-enum", None, f"density.profile {profile!r} is not one of {', '.join(PROFILES)}")
    elif profile == "dense" and b.target != "infographic":
        b.fail("target-enum", None, "density.profile dense is only defined for the infographic target")


def check_contract_present(b: Brief) -> None:
    heading = CONTRACT_HEADINGS.get(b.language)
    if heading is None:
        return
    wrong = [h for lang, h in CONTRACT_HEADINGS.items() if lang != b.language and h in b.body]
    if heading not in b.preamble:
        where = "after unit 1" if heading in b.body else ("in the wrong language" if wrong else "absent")
        b.fail("contract-present", None, f"{heading!r} must sit between the title and unit 1; it is {where}")


def check_contract_clauses(b: Brief) -> None:
    heading = CONTRACT_HEADINGS.get(b.language)
    if heading is None or heading not in b.preamble:
        return
    after = b.preamble[b.preamble.index(heading) + len(heading):]
    clauses = 0
    for ln in after.splitlines()[1:]:
        if ln.startswith("- "):
            clauses += 1
        elif ln.strip() and clauses:
            break
        elif ln.startswith("#") or KEY_RE.match(ln):
            break
    if clauses < CONTRACT_MIN_CLAUSES:
        b.fail("contract-clauses", None, f"{clauses} clauses under {heading!r}, at least {CONTRACT_MIN_CLAUSES} required")


def check_unit_numbering(b: Brief) -> None:
    kind = UNIT_KIND.get(b.target)
    if not b.units:
        b.fail("unit-numbering", None, "the brief carries no `## <Kind> N:` unit")
        return
    for i, u in enumerate(b.units, start=1):
        if kind and u["kind"] != kind:
            b.fail("unit-numbering", u["number"], f"unit kind {u['kind']!r}, expected {kind!r} for target {b.target}")
        if u["number"] != i:
            b.fail("unit-numbering", u["number"], f"unit numbered {u['number']} at position {i}; units run from 1 without gaps")
    climax = b.fm.get("climax")
    if climax is not None and not (isinstance(climax, int) and 1 <= climax <= len(b.units)):
        b.fail("unit-numbering", None, f"climax {climax!r} does not name a unit between 1 and {len(b.units)}")


def check_slides_open_bluf(b: Brief) -> None:
    """Slides open on the answer: unit 1 is the Executive TL;DR as `bluf`, never a
    standalone `cover`. Silent on every other target, which still uses `cover`."""
    if b.target != "slides" or not b.units:
        return
    first = b.units[0]
    t = first["fields"].get("type")
    if t != "bluf":
        b.fail("slides-open-bluf", first["number"],
               f"slide 1 is type {t!r}; the deck opens on the Executive TL;DR as 'bluf'")


def check_slides_close_sources(b: Brief) -> None:
    """Slides close on the source register: the last unit is `sources`, so the sources
    slide the Rendering Contract mandates is addressable by the brief and cannot be
    pruned silently by `--max-units`."""
    if b.target != "slides" or not b.units:
        return
    last = b.units[-1]
    t = last["fields"].get("type")
    if t != "sources":
        b.fail("slides-close-sources", last["number"],
               f"the last slide is type {t!r}; the deck closes on a 'sources' unit "
               "built from the Sources block")


def check_density_frontmatter(b: Brief) -> None:
    if not b.ceilings:
        return
    density = b.fm.get("density")
    carried = density.get("ceilings") if isinstance(density, dict) else None
    if not isinstance(carried, dict):
        b.fail("density-frontmatter", None, "density.ceilings block missing")
        return
    for key, value in b.ceilings.items():
        if key not in carried:
            b.fail("density-frontmatter", None, f"density.ceilings lacks {key}")
        elif carried[key] != value:
            b.fail("density-frontmatter", None, f"density.ceilings.{key} is {carried[key]}, reference says {value}")
    for key in carried:
        if key not in b.ceilings:
            b.fail("density-frontmatter", None, f"density.ceilings carries {key}, which the reference does not define")


def _type_ok(b: Brief, u: dict, check: str) -> None:
    t = u["fields"].get("type")
    if t not in TYPE_ENUM:
        b.fail(check, u["number"], f"type {t!r} is not one of {', '.join(TYPE_ENUM)}")


def check_density_slides(b: Brief) -> None:
    c, chk = b.ceilings, "density-slides"
    cap = b.max_units if b.max_units is not None else c["units_max_default"]
    if not (c["units_min"] <= len(b.units) <= cap):
        b.fail(chk, None, f"{len(b.units)} slides; between {c['units_min']} and {cap} required")
    for u in b.units:
        f, n = u["fields"], u["number"]
        _type_ok(b, u, chk)
        if len(u["headline"]) > c["headline_chars_max"]:
            b.fail(chk, n, f"headline is {len(u['headline'])} characters, ceiling {c['headline_chars_max']}")
        points = f.get("slide_points")
        if f.get("type") == "sources":
            # The sources unit is built by the renderer from the trailing **Sources**
            # block; it carries no authored bullets, so the slide_points floor does not
            # apply to it. Every other slides unit still owes one.
            points = points if isinstance(points, list) else []
        elif not isinstance(points, list) or not points:
            b.fail(chk, n, "slide_points list missing")
            points = []
        if len(points) > c["slide_points_max_lines"]:
            b.fail(chk, n, f"{len(points)} slide_points lines, ceiling {c['slide_points_max_lines']}")
        per_line = c["slide_point_words_max_table"] if f.get("type") == "table" else c["slide_point_words_max"]
        for p in points:
            if words(p) > per_line:
                b.fail(chk, n, f"slide_points line has {words(p)} words, ceiling {per_line}: {p[:40]!r}")
        talk = f.get("talk_track")
        talk_words = words(talk) if isinstance(talk, str) else 0
        if talk_words > c["talk_track_words_max"]:
            b.fail(chk, n, f"talk_track has {talk_words} words, ceiling {c['talk_track_words_max']}")
        if "element" in f and talk_words < c["talk_track_words_min"]:
            b.fail(chk, n, f"element slide talk_track has {talk_words} words, floor {c['talk_track_words_min']}")


def check_density_document(b: Brief) -> None:
    c, chk = b.ceilings, "density-document"
    if b.max_units is not None:
        b.notes.append("--max-units ignored: the document target carries exactly four sections")
    summary = b.pre.get("executive_summary")
    if not isinstance(summary, str) or not summary:
        b.fail(chk, None, "executive_summary missing")
    else:
        if not (c["summary_words_min"] <= words(summary) <= c["summary_words_max"]):
            b.fail(chk, None, f"executive_summary has {words(summary)} words; {c['summary_words_min']}-{c['summary_words_max']} required")
        if not (c["summary_sentences_min"] <= sentences(summary) <= c["summary_sentences_max"]):
            b.fail(chk, None, f"executive_summary has {sentences(summary)} sentences; {c['summary_sentences_min']}-{c['summary_sentences_max']} required")
    if len(b.units) != c["sections"]:
        b.fail(chk, None, f"{len(b.units)} sections; exactly {c['sections']} required")
    total = 0
    for u in b.units:
        body = u["fields"].get("body")
        if not isinstance(body, str) or not body:
            b.fail(chk, u["number"], "body missing")
            continue
        total += words(body)
        idx = u["number"] - 1
        if idx < len(b.narrative_headings) and u["headline"] != b.narrative_headings[idx]:
            b.fail(chk, u["number"], f"headline {u['headline']!r} is not the narrative's heading {b.narrative_headings[idx]!r}")
    target = b.fm.get("target_length") or c["target_length_default"]
    try:
        target = int(target)
    except (TypeError, ValueError):
        target = c["target_length_default"]
    lo, hi = target * c["band_lower"], target * c["band_upper"]
    if b.units and not (lo <= total <= hi):
        b.fail(chk, None, f"section bodies total {total} words; {int(lo)}-{int(hi)} required for target_length {target}")


def check_density_infographic(b: Brief) -> None:
    c, chk = b.ceilings, "density-infographic"
    dense = isinstance(b.fm.get("density"), dict) and b.fm["density"].get("profile") == "dense"
    blocks_max = c["blocks_max_dense"] if dense else c["blocks_max"]
    if b.max_units is not None:
        blocks_max = min(blocks_max, b.max_units)
    words_max = c["words_max_dense"] if dense else c["words_max"]
    for key, cap in (("headline", c["headline_words_max"]), ("subline", c["subline_words_max"])):
        v = b.pre.get(key)
        if not isinstance(v, str) or not v:
            b.fail(chk, None, f"{key} missing")
        elif words(v) > cap:
            b.fail(chk, None, f"{key} has {words(v)} words, ceiling {cap}")
    heroes = b.pre.get("hero_numbers")
    heroes = heroes if isinstance(heroes, list) else []
    if not (c["hero_numbers_min"] <= len(heroes) <= c["hero_numbers_max"]):
        b.fail(chk, None, f"{len(heroes)} hero_numbers; {c['hero_numbers_min']}-{c['hero_numbers_max']} required")
    for h in heroes:
        label = SRC_RE.sub("", h).split(" — ", 1)
        if len(label) == 2 and words(label[1]) > c["hero_label_words_max"]:
            b.fail(chk, None, f"hero label has {words(label[1])} words, ceiling {c['hero_label_words_max']}: {label[1]!r}")
    if not (c["blocks_min"] <= len(b.units) <= blocks_max):
        b.fail(chk, None, f"{len(b.units)} blocks; {c['blocks_min']}-{blocks_max} required")
    for u in b.units:
        _type_ok(b, u, chk)
        for p in u["fields"].get("points", []) if isinstance(u["fields"].get("points"), list) else []:
            if words(p) > c["point_words_max"]:
                b.fail(chk, u["number"], f"point has {words(p)} words, ceiling {c['point_words_max']}: {p[:40]!r}")
    if not isinstance(b.trailer.get("cta"), str):
        b.fail(chk, None, "cta missing")
    total = b.brief_word_count()
    if total > words_max:
        b.fail(chk, None, f"{total} on-brief words, ceiling {words_max}")


def check_density_web(b: Brief) -> None:
    c, chk = b.ceilings, "density-web"
    hero = b.pre.get("hero")
    if not isinstance(hero, dict) or not hero.get("headline"):
        b.fail(chk, None, "hero block with headline missing")
    else:
        if words(hero["headline"]) > c["hero_headline_words_max"]:
            b.fail(chk, None, f"hero.headline has {words(hero['headline'])} words, ceiling {c['hero_headline_words_max']}")
        if len(hero["headline"]) > c["headline_chars_max"]:
            b.fail(chk, None, f"hero.headline is {len(hero['headline'])} characters, ceiling {c['headline_chars_max']}")
        if hero.get("subline") and words(hero["subline"]) > c["hero_subline_words_max"]:
            b.fail(chk, None, f"hero.subline has {words(hero['subline'])} words, ceiling {c['hero_subline_words_max']}")
    sections_max = c["sections_max"] if b.max_units is None else min(c["sections_max"], b.max_units)
    if not (c["sections_min"] <= len(b.units) <= sections_max):
        b.fail(chk, None, f"{len(b.units)} sections; {c['sections_min']}-{sections_max} required")
    for u in b.units:
        f, n = u["fields"], u["number"]
        _type_ok(b, u, chk)
        if words(u["headline"]) > c["section_headline_words_max"]:
            b.fail(chk, n, f"headline has {words(u['headline'])} words, ceiling {c['section_headline_words_max']}")
        if len(u["headline"]) > c["headline_chars_max"]:
            b.fail(chk, n, f"headline is {len(u['headline'])} characters, ceiling {c['headline_chars_max']}")
        body = f.get("body")
        if not isinstance(body, str) or not body:
            b.fail(chk, n, "body missing")
        elif words(body) > c["section_body_words_max"]:
            b.fail(chk, n, f"body has {words(body)} words, ceiling {c['section_body_words_max']}")
        for item in f.get("bullets", []) if isinstance(f.get("bullets"), list) else []:
            if words(item) > c["bullet_words_max"]:
                b.fail(chk, n, f"bullet has {words(item)} words, ceiling {c['bullet_words_max']}: {item[:40]!r}")
        if isinstance(f.get("quote"), str) and words(f["quote"]) > c["quote_words_max"]:
            b.fail(chk, n, f"quote has {words(f['quote'])} words, ceiling {c['quote_words_max']}")
        if isinstance(f.get("attribution"), str) and words(f["attribution"]) > c["attribution_words_max"]:
            b.fail(chk, n, f"attribution has {words(f['attribution'])} words, ceiling {c['attribution_words_max']}")
    if not isinstance(b.trailer.get("cta"), str):
        b.fail(chk, None, "cta missing")


DENSITY_CHECKS = {
    "slides": check_density_slides,
    "document": check_density_document,
    "infographic": check_density_infographic,
    "web": check_density_web,
}


def check_density_target(b: Brief) -> None:
    fn = DENSITY_CHECKS.get(b.target)
    if fn and b.ceilings:
        fn(b)


def check_copy_frozen_numbers(b: Brief) -> None:
    spoken = [(u["number"], u["fields"]["talk_track"]) for u in b.units if isinstance(u["fields"].get("talk_track"), str)]
    for unit, text in b.frontmatter_copy() + b.on_brief_copy() + spoken:
        for token in NUMBER_RE.findall(MARKER_RE.sub("", text)):
            if token not in b.narrative_numbers:
                b.fail("copy-frozen-numbers", unit, f"number {token!r} does not occur in the narrative: {text[:50]!r}")


def check_citations_resolve(b: Brief) -> None:
    if SUP_RE.search(b.body):
        b.fail("citations-resolve", None, "a `<sup>` marker survives; the brief reduces citations to `[N]`")
    if not b.sources_block.strip():
        b.fail("citations-resolve", None, "`**Sources**` block missing")
    seen = set()
    for m in MARKER_RE.finditer(b.body):
        n = int(m.group(1))
        if n not in b.sources and n not in seen:
            seen.add(n)
            b.fail("citations-resolve", None, f"citation [{n}] has no `[{n}] ` entry in the Sources block")


def check_key_figures_src(b: Brief) -> None:
    entries = []
    kf = b.fm.get("key_figures")
    if isinstance(kf, list):
        entries += [("key_figures", e) for e in kf]
    hn = b.pre.get("hero_numbers")
    if isinstance(hn, list):
        entries += [("hero_numbers", e) for e in hn]
    for where, entry in entries:
        m = SRC_RE.search(str(entry))
        if not m:
            b.fail("key-figures-src", None, f"{where} entry lacks a trailing (src: [N]): {str(entry)[:50]!r}")
        elif int(m.group(1)) not in b.sources:
            b.fail("key-figures-src", None, f"{where} entry cites [{m.group(1)}], which the Sources block lacks")


def check_no_styling_keys(b: Brief) -> None:
    for m in STYLING_KEY_RE.finditer(b.body):
        b.fail("no-styling-keys", None, f"styling key {m.group(1)!r} appears; styling comes only from the design system")


def check_evidence_status(b: Brief) -> None:
    if b.target != "slides":
        return
    for u in b.units:
        evidence_status = u["fields"].get("evidence_status")
        if evidence_status is not None and evidence_status not in EVIDENCE_STATUSES:
            b.fail(
                "evidence-status",
                u["number"],
                f"evidence_status {evidence_status!r} is not one of {', '.join(EVIDENCE_STATUSES)}",
            )


def _visual_intent_exempt(u: dict) -> bool:
    """True for the trailing source register, which asserts no relationship of its own.

    The renderer builds that unit from the narrative's **Sources** block verbatim, so it names
    no visual intent. It is recognisable two ways, and each is sufficient on its own: it carries
    `type: sources`, or it carries no `slide_points`. The exemption is the disjunction, so it
    holds whichever of the two shapes a brief happens to use.
    """
    f = u["fields"]
    return f.get("type") == "sources" or "slide_points" not in f


def check_visual_intent(b: Brief) -> None:
    if b.target not in TARGETS:
        return
    last = b.units[-1] if b.units else None
    allowed = VISUAL_INTENT_REQUIRED + VISUAL_INTENT_OPTIONAL
    for u in b.units:
        f, n = u["fields"], u["number"]
        vi = f.get("visual_intent")
        if b.target == "document":
            if vi is not None:
                b.fail("visual-intent", n, "visual_intent is not allowed on the document target")
            continue
        if vi is None:
            if b.target == "slides" and not (u is last and _visual_intent_exempt(u)):
                b.fail("visual-intent", n, "visual_intent block missing; every copy-bearing slides unit owes one")
            continue
        if not isinstance(vi, dict):
            b.fail("visual-intent", n, "visual_intent is not a mapping; it needs indented message_pattern, relationship and focal_point")
            continue
        for key in vi:
            if key not in allowed:
                b.fail("visual-intent", n, f"visual_intent carries unknown key {key!r}")
        for key in VISUAL_INTENT_REQUIRED:
            if not vi.get(key):
                b.fail("visual-intent", n, f"visual_intent is missing required {key}")
        for key, enum in VISUAL_INTENT_ENUMS.items():
            value = vi.get(key)
            if value and value not in enum:
                b.fail("visual-intent", n, f"visual_intent {key} is {value!r}, which is not one of {', '.join(enum)}")


CHECKS = (
    ("frontmatter-type", check_frontmatter_type),
    ("target-enum", check_target_enum),
    ("contract-present", check_contract_present),
    ("contract-clauses", check_contract_clauses),
    ("unit-numbering", check_unit_numbering),
    ("slides-open-bluf", check_slides_open_bluf),
    ("slides-close-sources", check_slides_close_sources),
    ("density-frontmatter", check_density_frontmatter),
    ("density-<target>", check_density_target),
    ("copy-frozen-numbers", check_copy_frozen_numbers),
    ("citations-resolve", check_citations_resolve),
    ("key-figures-src", check_key_figures_src),
    ("no-styling-keys", check_no_styling_keys),
    ("evidence-status", check_evidence_status),
    ("visual-intent", check_visual_intent),
)


# ----------------------------------------------------------------------- main


def emit(success: bool, data: dict | None, error: str, code: int) -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}, ensure_ascii=False))
    return code


class _EnvelopeParser(argparse.ArgumentParser):
    def error(self, message):
        emit(False, None, f"argument error: {message}", 2)
        raise SystemExit(2)


def main() -> int:
    parser = _EnvelopeParser(description="Lint a design brief against its machine-checkable rules.")
    parser.add_argument("--brief", help="path to the design brief")
    parser.add_argument("--narrative", help="path to the narrative the brief was condensed from")
    parser.add_argument("--ceilings", default=DEFAULT_CEILINGS, help="density ceilings reference (default: the skill's)")
    parser.add_argument("--max-units", type=int, default=None,
                        help="caller's unit cap: slides, infographic blocks and web sections; ignored on document")
    parser.add_argument("--json", action="store_true", help="accepted for symmetry; output is always the JSON envelope")
    parser.add_argument("--list-checks", action="store_true", help="list every check and exit")
    args = parser.parse_args()

    if args.list_checks:
        return emit(True, {"checks": [name for name, _ in CHECKS], "targets": list(TARGETS), "types": list(TYPE_ENUM)}, "", 0)
    if not args.brief or not args.narrative:
        return emit(False, None, "--brief and --narrative are required", 2)

    try:
        brief = Brief(args.brief, args.narrative, args.ceilings, args.max_units)
        for name, fn in CHECKS:
            fn(brief)
            brief.checks_run.append(name.replace("<target>", brief.target) if brief.target in TARGETS else name)
    except CheckError as exc:
        return emit(False, None, str(exc), 2)
    except Exception as exc:  # never surface a traceback
        return emit(False, None, f"checker error: {exc}", 2)

    fails = sum(1 for f in brief.findings if f["severity"] == "fail")
    data = {
        "target": brief.target,
        "brief": brief.path,
        "checks_run": brief.checks_run,
        "findings": brief.findings,
        "fails": fails,
        "warns": 0,
        "unit_count": len(brief.units),
        "brief_word_count": brief.brief_word_count(),
        "notes": brief.notes,
    }
    return emit(fails == 0, data, "", 0 if fails == 0 else 1)


if __name__ == "__main__":
    sys.exit(main())
