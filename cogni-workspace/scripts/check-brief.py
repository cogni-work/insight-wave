#!/usr/bin/env python3
"""check-brief.py — lint a brief against the machine-checkable half of its checklist.

WHY THIS EXISTS. Brief validation used to be four prose checklists the model
executed against its own output. A model checking its own work for a misspelled
layout name, a 40-word IS box or a `<sup>` marker in a headline is the weakest
possible guard, and every finding it misses is silent. This script runs those
items deterministically, on top of the shared parser in `parse-brief.py`, so a
brief that fails a structural rule fails loudly before a renderer ever sees it.

WHAT IT DOES NOT DO. The reasoning layers — is this an assertion headline, is
the deck MECE, does the arc flow — stay prose in the checklists. A scripted proxy
for "is this an assertion" would produce false fails and erode trust in the
whole checker, so nothing here pretends to judge quality.

PROFILES. `--type slides` runs the full slides checklist. `--type web`,
`storyboard` and `infographic` run the core checks shared by the four
checklists — frontmatter, type/version pin with legacy values accepted, unit
heading and numbering, one fence per unit, forbidden visual fields, CTA Summary
and metadata presence — and leave each type's own rules to its checklist.

SEVERITY. Every check is a `fail` except the three that would redden briefs the
repo treats as correct: `notes-words` (a target range, not a hard gate),
`metadata-block` (the reference example deliberately carries none, and a parser
suite pins that) and the neither-citations-nor-references arm of
`deck-references-last`. Those are `warn`; `--strict` promotes them.

ONE PARSER. Every read goes through `parse-brief.py`, loaded here the way
`brief-render-qa.py` loads it: `parse_document` for the type-agnostic units
every profile checks, and for slides additionally `parse_brief` for the slides
model. The slides profile therefore reads the file twice, through one parser —
the checker reads exactly what the renderers read and cannot drift from them on
where a unit starts.

THE LAYOUT ENUM is a literal here on purpose. It lives in four homes — this
tuple, the `## Layout N:` headings in `libraries/pptx-layouts.md`, the
`LAYOUT_RENDERERS` keys in `render-html-slides`, and the closed set the slides
checklist states — and `tests/test-brief-layout-sync.sh` pins all four equal.
Deriving it at run time from one of the others would make that pin compare a
home with itself.

Usage:
    check-brief.py --type slides|web|storyboard|infographic <brief>
                   [--max-slides N] [--strict] [--list-checks]

Exit 0 when no check fails, 1 when at least one does, 2 on an error (unreadable
or unparseable brief, unknown type). Always prints exactly one
{"success", "data", "error"} object on stdout and never a traceback.
"""

import argparse
import importlib.util
import json
import os
import re
import sys

LAYOUT_ENUM = (
    "title-slide",
    "stat-card-with-context",
    "four-quadrants",
    "two-columns-equal",
    "is-does-means",
    "three-options",
    "timeline-steps",
    "layered-architecture",
    "process-flow",
    "gantt-chart",
    "closing-slide",
)

# The nine keys every brief type carries at every version. `theme` and
# `theme_path` are optional pass-through keys and `arc_id` is conditional, so
# none of the three is required here.
CORE_KEYS = (
    "type", "version", "customer", "provider", "language", "generated",
    "arc_type", "governing_thought", "confidence_score",
)
SLIDES_41_KEYS = ("max_slides", "slides", "design", "key_figures")

# Styling keys no brief may carry — the renderer reads the theme. Case-sensitive
# on purpose: the lowercase nested `intent.role` is a permitted 4.1 key.
COLOR_KEYS_SLIDES = ("Background", "Text-Color", "Icon-Color", "Role", "Intensity", "Mood")
COLOR_KEYS_WEB = COLOR_KEYS_SLIDES + ("fill", "color", "background", "textColor")
COLOR_KEYS_INFOGRAPHIC = COLOR_KEYS_SLIDES + ("Fill", "Border-Color")

PROFILES = {
    "slides": {
        "type": "presentation-brief", "versions": ("4.1",), "legacy": ("4.0",),
        "unit_re": re.compile(r"^## Slide (\d+)()\s*:"), "fixed_units": (),
        "colors": COLOR_KEYS_SLIDES,
    },
    "web": {
        "type": "web-brief", "versions": ("1.1",), "legacy": ("1.0",),
        "unit_re": re.compile(r"^## Section (\d+)()\s*:"),
        "fixed_units": ("## Header", "## Footer"), "colors": COLOR_KEYS_WEB,
    },
    "storyboard": {
        "type": "storyboard-brief", "versions": ("2.1",), "legacy": ("2.0",),
        "unit_re": re.compile(r"^## Poster (\d+)()\s*:"), "fixed_units": (),
        "colors": COLOR_KEYS_WEB,
    },
    "infographic": {
        "type": "infographic-brief", "versions": ("1.0", "1.1", "1.2"), "legacy": (),
        "unit_re": re.compile(r"^## Block (\d+)([a-z]?)\s*:"),
        "fixed_units": ("## Title Block", "## CTA Block", "## Footer Block"),
        "colors": COLOR_KEYS_INFOGRAPHIC,
    },
}
# The two hand-drawn render agents accept 1.0 and 1.1 only, and the dispatcher
# refuses to route a 1.2 brief to them. The v1.2 delta is editorial-only, so a
# hand-drawn brief declaring it is a pairing the pipeline will reject.
HAND_DRAWN_PRESETS = ("sketchnote", "whiteboard")
HAND_DRAWN_CEILING = ("1.0", "1.1")

# Per-layout field vocabulary, keyed by the YAML keys a brief writes. Required
# entries use dotted paths; alternatives are listed as "A|B".
REQUIRED_FIELDS = {
    "title-slide": ("Title", "Subtitle"),
    "closing-slide": ("Title", "Subtitle"),
    "stat-card-with-context": (
        "Slide-Title", "Hero-Stat-Box.Number", "Hero-Stat-Box.Label",
        "Context-Box.Headline", "Context-Box.Bullets"),
    "four-quadrants": ("Slide-Title",) + tuple(
        p for n in range(1, 5)
        for p in ("Quadrant-{0}.Label".format(n), "Quadrant-{0}.Number|Quadrant-{0}.Bullets".format(n))),
    "two-columns-equal": (
        "Slide-Title", "Left-Column.Headline", "Left-Column.Bullets|Left-Column.Image",
        "Right-Column.Headline", "Right-Column.Bullets|Right-Column.Image"),
    "is-does-means": (
        "Slide-Title", "IS-Box.Label", "IS-Box.Text", "DOES-Box.Label", "DOES-Box.Text",
        "MEANS-Box.Label", "MEANS-Box.Text"),
    "three-options": ("Slide-Title",) + tuple(
        p for n in range(1, 4)
        for p in ("Option-{0}.Name".format(n), "Option-{0}.Features".format(n))),
    "timeline-steps": ("Slide-Title",) + tuple(
        p for n in range(1, 5)
        for p in ("Step-{0}.Number".format(n), "Step-{0}.Label".format(n),
                  "Step-{0}.Description".format(n))),
    "layered-architecture": ("Slide-Title", "Diagram"),
    "process-flow": ("Slide-Title", "Diagram"),
    "gantt-chart": ("Slide-Title", "Diagram"),
}
# Top-level keys every slide may carry regardless of layout.
COMMON_TOP_KEYS = frozenset((
    "Layout", "Slide-Kind", "intent", "visual", "cta", "Speaker-Notes", "Source",
    "Bottom-Banner", "Slide-Title",
))
LAYOUT_TOP_KEYS = {
    "title-slide": frozenset(("Title", "Subtitle", "Metadata", "Logo")),
    "closing-slide": frozenset(("Title", "Subtitle", "Metadata", "Logo")),
    "stat-card-with-context": frozenset(("Hero-Stat-Box", "Context-Box", "Impact-Box")),
    "four-quadrants": frozenset("Quadrant-{0}".format(n) for n in range(1, 5)),
    "two-columns-equal": frozenset(("Left-Column", "Right-Column")),
    "is-does-means": frozenset(("IS-Box", "DOES-Box", "MEANS-Box")),
    "three-options": frozenset("Option-{0}".format(n) for n in range(1, 4)),
    "timeline-steps": frozenset(),  # Step-N keys are matched by pattern
    "layered-architecture": frozenset(("Diagram",)),
    "process-flow": frozenset(("Diagram", "Detail-Grid")),
    "gantt-chart": frozenset(("Diagram",)),
}
STEP_KEY_RE = re.compile(r"^Step-[0-9]+$")

IDM_LABELS = {"de": ("IST", "MACHT", "BEDEUTET"), "en": ("IS", "DOES", "MEANS")}
IDM_BUDGET = {"IS-Box": 15, "DOES-Box": 20, "MEANS-Box": 15}
BULLET_WORDS_MAX = 10
BULLETS_PER_FIELD_MAX = 5
BANNER_WORDS_MAX = 12
HEADLINE_MAX = 110
HEADLINE_MAX_IDM = 143
NOTES_WORDS_MIN = 150
NOTES_WORDS_MAX = 450
DECK_MIN_CONTENT = 5
DECK_MAX_DEFAULT = 15
CONSECUTIVE_RUN = 3

JARGON = ("Power Position", "Why Change", "Why Now", "Why You", "Why Pay",
          "Unconsidered Need", "Buying Center")
JARGON_RE = re.compile(r"\bPP[123]\b")
CTA_TYPES = ("explore", "evaluate", "commit", "share")
CONTRACT_HEADINGS = {"en": "# Rendering Contract", "de": "# Rendering-Vertrag"}
CONTRACT_MIN_CLAUSES = 5
SUP_RE = re.compile(r"<sup>.*?</sup>", re.S)
BARE_CITE_RE = re.compile(r"\[\d+\]\(https?://[^)]+\)")
NODE_RE = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*(?:\[|\(|\{|>)")


class CheckError(Exception):
    """A brief this checker cannot grade at all — exit 2, never a finding."""


# ---------------------------------------------------------------------------
# Loading the shared parser
# ---------------------------------------------------------------------------

def _locate(name):
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, name)
    if not os.path.isfile(path):
        raise CheckError("cannot find {0} next to check-brief.py".format(name))
    return path


def _load_parse_brief():
    path = _locate("parse-brief.py")
    spec = importlib.util.spec_from_file_location("_parse_brief", path)
    if spec is None or spec.loader is None:
        raise CheckError("cannot load parse-brief.py at {0}".format(path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def _words(text):
    """Count words the way a presenter reads them: markers stripped, punctuation
    that stands alone (`+`, `—`) not counted."""
    if not isinstance(text, str):
        return 0
    cleaned = SUP_RE.sub("", text)
    return sum(1 for tok in cleaned.split() if re.search(r"[A-Za-z0-9À-ɏ]", tok))


def _get(mapping, dotted):
    node = mapping
    for part in dotted.split("."):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node


def _present(mapping, spec):
    """A dotted path, or an `A|B` alternative, resolves to a non-empty value."""
    for alt in spec.split("|"):
        value = _get(mapping, alt)
        if value not in (None, "", [], {}):
            return True
    return False


def _leaves(value, path=()):
    """Yield (path, text) for every string leaf of a nested value."""
    if isinstance(value, dict):
        for key, sub in value.items():
            yield from _leaves(sub, path + (str(key),))
    elif isinstance(value, list):
        for index, sub in enumerate(value):
            yield from _leaves(sub, path + (str(index),))
    elif isinstance(value, str):
        yield path, value


def _keys(value, path=()):
    """Yield (path, key) for every mapping key at any depth."""
    if isinstance(value, dict):
        for key, sub in value.items():
            yield path, str(key)
            yield from _keys(sub, path + (str(key),))
    elif isinstance(value, list):
        for index, sub in enumerate(value):
            yield from _keys(sub, path + (str(index),))


def _banner_text(fields):
    banner = fields.get("Bottom-Banner")
    if isinstance(banner, dict):
        return banner.get("Text")
    return banner


def _mermaid_nodes(text):
    """Distinct node ids in a Mermaid graph, subgraph headers excluded."""
    ids = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("subgraph") or stripped in ("end", ""):
            continue
        for match in NODE_RE.finditer(stripped):
            if match.group(1) not in ids and match.group(1) not in ("graph", "flowchart"):
                ids.append(match.group(1))
    return ids


# ---------------------------------------------------------------------------
# Context: one parsed brief plus its findings
# ---------------------------------------------------------------------------

class Context:
    def __init__(self, brief_type, path, max_slides, strict):
        self.type = brief_type
        self.profile = PROFILES[brief_type]
        self.path = path
        self.max_slides_arg = max_slides
        self.strict = strict
        self.findings = []
        self.checks_run = []
        pb = _load_parse_brief()
        self.pb = pb
        try:
            self.doc = pb.parse_document(path)
        except pb.BriefError as exc:
            raise CheckError(str(exc))
        except OSError as exc:
            raise CheckError("cannot read brief: {0}".format(exc))
        self.frontmatter = self.doc["frontmatter"] or {}
        self.lines = self.doc["lines"]
        self.units = []
        for unit in self.doc["sections"]:
            match = self.profile["unit_re"].match(unit["heading"])
            if match:
                self.units.append({
                    "number": int(match.group(1)),
                    "suffix": match.group(2),
                    "heading": unit["heading"],
                    "title": unit["heading"].split(":", 1)[1].strip() if ":" in unit["heading"] else "",
                    "fenced": unit["fenced"],
                    "fields": unit["fields"],
                })
        self.model = pb.parse_brief(path) if brief_type == "slides" else None
        self.slides = self.model["slides"] if self.model else []
        self.version = str(self.frontmatter.get("version")) if self.frontmatter.get("version") is not None else None

    # -- findings -------------------------------------------------------------
    def fail(self, check, unit, message):
        self.findings.append({"check": check, "severity": "fail", "unit": unit, "message": message})

    def warn(self, check, unit, message):
        severity = "fail" if self.strict else "warn"
        self.findings.append({"check": check, "severity": severity, "unit": unit, "message": message})

    # -- derived views --------------------------------------------------------
    @property
    def language(self):
        return str(self.frontmatter.get("language") or "").lower()

    def content_slides(self):
        return [s for s in self.slides if (s["slide_kind"] or "content") == "content"]

    def citations(self):
        """Every (n, url) cited in a body field, deck-wide, in document order."""
        found = []
        for slide in self.slides:
            for pair in slide["citations"]:
                found.append((pair["n"], pair["url"], slide["number"]))
        return found

    def client_facing(self, slide):
        """String leaves a client sees: heading plus every field but notes and Source."""
        yield ("heading",), slide["headline"]
        for path, text in _leaves(slide["fields"]):
            if path[0] in ("Speaker-Notes", "Source"):
                continue
            yield path, text


# ---------------------------------------------------------------------------
# Core checks — every profile
# ---------------------------------------------------------------------------

def check_fm_core_keys(ctx):
    fm = ctx.frontmatter
    for key in CORE_KEYS:
        if key not in fm or fm[key] in (None, ""):
            ctx.fail("fm-core-keys", "frontmatter", "missing required key `{0}`".format(key))
    if ctx.type == "slides" and ctx.version == "4.1":
        for key in SLIDES_41_KEYS:
            if key not in fm or fm[key] in (None, "", [], {}):
                ctx.fail("fm-core-keys", "frontmatter", "4.1 requires `{0}`".format(key))
        has_climax = any(
            isinstance(s["intent"], dict) and s["intent"].get("emphasis") == "climax"
            for s in ctx.slides)
        if has_climax and "climax" not in fm:
            ctx.fail("fm-core-keys", "frontmatter",
                     "a slide carries `emphasis: climax` but `climax` is absent")
        if not has_climax and "climax" in fm:
            ctx.fail("fm-core-keys", "frontmatter",
                     "`climax` is set but no slide carries `emphasis: climax`")


def check_fm_type_version(ctx):
    expected = ctx.profile["type"]
    actual = ctx.frontmatter.get("type")
    if actual != expected:
        ctx.fail("fm-type-version", "frontmatter",
                 "type is {0!r}, expected {1!r}".format(actual, expected))
    accepted = ctx.profile["versions"] + ctx.profile["legacy"]
    if ctx.version not in accepted:
        ctx.fail("fm-type-version", "frontmatter",
                 "version {0!r} not in {1}".format(ctx.version, list(accepted)))
    if ctx.type == "infographic":
        preset = str(ctx.frontmatter.get("style_preset") or "")
        if preset in HAND_DRAWN_PRESETS and ctx.version not in HAND_DRAWN_CEILING:
            ctx.fail("fm-type-version", "frontmatter",
                     "style_preset {0!r} renders through a hand-drawn agent that accepts "
                     "only versions {1}; declare one of those".format(preset, list(HAND_DRAWN_CEILING)))


def check_unit_fenced(ctx):
    legacy = ctx.version in ctx.profile["legacy"]
    for unit in ctx.units:
        if unit["fenced"]:
            continue
        label = "unit {0}{1}".format(unit["number"], unit["suffix"])
        if legacy:
            ctx.warn("unit-fenced", label, "unfenced body (legacy {0} shape)".format(ctx.version))
        else:
            ctx.fail("unit-fenced", label, "body is not one fenced yaml block")
    for fixed in ctx.profile["fixed_units"]:
        matches = [u for u in ctx.doc["sections"] if u["heading"] == fixed]
        if not matches:
            ctx.fail("unit-fenced", fixed, "fixed unit heading is missing")
        elif not matches[0]["fenced"]:
            ctx.fail("unit-fenced", fixed, "fixed unit body is not fenced")


def check_unit_numbering(ctx):
    if not ctx.units:
        ctx.fail("unit-numbering", "document", "no numbered units found")
        return
    expected = 1
    previous = 0
    for unit in ctx.units:
        n = unit["number"]
        if unit["suffix"]:
            # A suffixed unit (`## Block 3b:`) extends the integer before it.
            if n != previous:
                ctx.fail("unit-numbering", unit["heading"],
                         "suffixed unit {0}{1} does not extend unit {2}".format(n, unit["suffix"], previous))
            continue
        if n != expected:
            ctx.fail("unit-numbering", unit["heading"],
                     "expected unit {0}, found {1}".format(expected, n))
            expected = n + 1
        else:
            expected += 1
        previous = n


def check_no_color_fields(ctx):
    forbidden = set(ctx.profile["colors"])
    for unit in ctx.units:
        for path, key in _keys(unit["fields"]):
            if key in forbidden:
                ctx.fail("no-color-fields", unit["heading"],
                         "styling key `{0}` at {1} — the renderer owns styling".format(
                             key, ".".join(path + (key,))))


def check_cta_summary_consistent(ctx):
    section = next((u for u in ctx.doc["sections"] if u["heading"] == "## CTA Summary"), None)
    if section is None:
        return
    if not section["fenced"]:
        ctx.fail("cta-summary-consistent", "## CTA Summary", "section is not fenced")
        return
    summary = section["fields"]
    proposals = summary.get("cta_proposals")
    if not isinstance(proposals, list) or not proposals:
        ctx.fail("cta-summary-consistent", "## CTA Summary", "no `cta_proposals` list")
        return
    texts = []
    for index, proposal in enumerate(proposals):
        if not isinstance(proposal, dict):
            ctx.fail("cta-summary-consistent", "## CTA Summary", "proposal {0} is not a map".format(index))
            continue
        texts.append(proposal.get("text"))
        if proposal.get("type") not in CTA_TYPES:
            ctx.fail("cta-summary-consistent", "## CTA Summary",
                     "proposal {0} type {1!r} not in {2}".format(index, proposal.get("type"), list(CTA_TYPES)))
    primary = summary.get("primary_cta")
    if primary is not None and primary not in texts:
        ctx.fail("cta-summary-consistent", "## CTA Summary",
                 "primary_cta {0!r} is not one of the proposals".format(primary))
    for slide in ctx.slides:
        cta = slide["cta"]
        if isinstance(cta, dict) and cta.get("type") not in CTA_TYPES:
            ctx.fail("cta-summary-consistent", "slide {0}".format(slide["number"]),
                     "cta.type {0!r} not in {1}".format(cta.get("type"), list(CTA_TYPES)))


def check_metadata_block(ctx):
    section = next((u for u in ctx.doc["sections"] if u["heading"] == "## Generation Metadata"), None)
    if section is None or not section["fenced"]:
        ctx.warn("metadata-block", "document", "no fenced `## Generation Metadata` section")


# ---------------------------------------------------------------------------
# Slides-only checks
# ---------------------------------------------------------------------------

def check_fm_theme_path(ctx):
    theme_path = ctx.frontmatter.get("theme_path")
    if theme_path is None:
        return
    if not isinstance(theme_path, str) or not theme_path.endswith("/theme.md"):
        ctx.fail("fm-theme-path", "frontmatter",
                 "theme_path {0!r} does not end in /theme.md".format(theme_path))


def check_fm_confidence(ctx):
    value = ctx.frontmatter.get("confidence_score")
    if value is None:
        return
    if not isinstance(value, (int, float)) or isinstance(value, bool) or not 0 <= value <= 1:
        ctx.fail("fm-confidence", "frontmatter",
                 "confidence_score {0!r} is not a number in 0..1".format(value))


def check_layout_enum(ctx):
    for slide in ctx.slides:
        layout = slide["layout"]
        if layout not in LAYOUT_ENUM:
            ctx.fail("layout-enum", "slide {0}".format(slide["number"]),
                     "Layout {0!r} is not one of the eleven layouts".format(layout))


def check_layout_required_fields(ctx):
    for slide in ctx.slides:
        required = REQUIRED_FIELDS.get(slide["layout"])
        if required is None:
            continue
        for spec in required:
            if not _present(slide["fields"], spec):
                ctx.fail("layout-required-fields", "slide {0}".format(slide["number"]),
                         "{0} requires `{1}`".format(slide["layout"], spec))


def check_layout_unknown_fields(ctx):
    for slide in ctx.slides:
        allowed = LAYOUT_TOP_KEYS.get(slide["layout"])
        if allowed is None:
            continue
        for key in slide["fields"]:
            if key in COMMON_TOP_KEYS or key in allowed:
                continue
            if slide["layout"] == "timeline-steps" and STEP_KEY_RE.match(key):
                continue
            ctx.fail("layout-unknown-fields", "slide {0}".format(slide["number"]),
                     "`{0}` is not a field of {1}".format(key, slide["layout"]))


def check_diagram_constraints(ctx):
    for slide in ctx.slides:
        layout, diagram = slide["layout"], slide["diagram_mermaid"]
        if layout not in ("layered-architecture", "process-flow", "gantt-chart"):
            continue
        unit = "slide {0}".format(slide["number"])
        if not isinstance(diagram, str) or not diagram.strip():
            continue  # layout-required-fields reports the absence
        head = diagram.strip().splitlines()[0].strip()
        if layout == "gantt-chart":
            if not head.startswith("gantt"):
                ctx.fail("diagram-constraints", unit, "gantt-chart Diagram must start with `gantt`")
            if "dateFormat" not in diagram:
                ctx.fail("diagram-constraints", unit, "gantt Diagram carries no `dateFormat`")
            sections = sum(1 for l in diagram.splitlines() if l.strip().startswith("section "))
            tasks = sum(1 for l in diagram.splitlines()
                        if ":" in l and not l.strip().startswith(
                            ("gantt", "dateFormat", "title", "section", "axisFormat", "%%")))
            if sections > 4:
                ctx.fail("diagram-constraints", unit, "gantt has {0} sections, max 4".format(sections))
            if tasks > 8:
                ctx.fail("diagram-constraints", unit, "gantt has {0} tasks, max 8".format(tasks))
            continue
        if not re.match(r"^(graph|flowchart)\s+LR\b", head):
            ctx.fail("diagram-constraints", unit,
                     "{0} Diagram must open with `graph LR` or `flowchart LR`".format(layout))
        subgraphs = sum(1 for l in diagram.splitlines() if l.strip().startswith("subgraph"))
        nodes = _mermaid_nodes(diagram)
        if layout == "layered-architecture":
            if subgraphs == 0:
                ctx.fail("diagram-constraints", unit, "layered-architecture needs subgraph lanes")
            if subgraphs > 3:
                ctx.fail("diagram-constraints", unit, "{0} subgraphs, max 3".format(subgraphs))
            if len(nodes) > 10:
                ctx.fail("diagram-constraints", unit, "{0} nodes, max 10".format(len(nodes)))
            lane, lane_nodes = None, 0
            for line in diagram.splitlines():
                stripped = line.strip()
                if stripped.startswith("subgraph"):
                    lane, lane_nodes = stripped, 0
                elif stripped == "end":
                    lane = None
                elif lane is not None:
                    lane_nodes += len(_mermaid_nodes(stripped))
                    if lane_nodes > 4:
                        ctx.fail("diagram-constraints", unit,
                                 "lane `{0}` holds more than 4 nodes".format(lane))
                        lane = None
        else:
            if subgraphs:
                ctx.fail("diagram-constraints", unit, "process-flow must not use subgraph")
            if len(nodes) > 6:
                ctx.fail("diagram-constraints", unit, "{0} nodes, max 6".format(len(nodes)))


def check_render_contract_section(ctx):
    lines = ctx.lines
    start = 0
    if lines and lines[0].strip() == "---":
        for j in range(1, len(lines)):
            if lines[j].strip() == "---":
                start = j + 1
                break
    first_slide = next((i for i, l in enumerate(lines) if l.startswith("## Slide 1")), len(lines))
    wanted = CONTRACT_HEADINGS.get(ctx.language)
    heading_at = None
    for i in range(start, first_slide):
        stripped = lines[i].strip()
        if stripped in CONTRACT_HEADINGS.values():
            heading_at = i
            if wanted and stripped != wanted:
                ctx.fail("render-contract-section", "document",
                         "contract heading {0!r} does not match language {1!r}".format(stripped, ctx.language))
            break
    if heading_at is None:
        anywhere = any(l.strip() in CONTRACT_HEADINGS.values() for l in lines)
        message = ("Rendering Contract is mispositioned — it belongs before `## Slide 1`" if anywhere
                   else "no Rendering Contract section")
        if ctx.version in ctx.profile["legacy"] and not anywhere:
            # The contract block arrived with 4.1; a 4.0 brief predates it.
            ctx.warn("render-contract-section", "document", message + " (legacy brief)")
        else:
            ctx.fail("render-contract-section", "document", message)
        return
    clauses = 0
    for line in lines[heading_at + 1:first_slide]:
        stripped = line.strip()
        if stripped.startswith("#") or stripped == "---":
            if clauses:
                break
            continue
        if stripped.startswith("- "):
            clauses += 1
    if clauses < CONTRACT_MIN_CLAUSES:
        ctx.fail("render-contract-section", "document",
                 "Rendering Contract carries {0} clauses, needs {1}".format(clauses, CONTRACT_MIN_CLAUSES))


def check_idm_labels_localized(ctx):
    expected = IDM_LABELS.get(ctx.language)
    if not expected:
        return
    for slide in ctx.slides:
        if slide["layout"] != "is-does-means":
            continue
        for box, label in zip(("IS-Box", "DOES-Box", "MEANS-Box"), expected):
            actual = _get(slide["fields"], box + ".Label")
            if actual != label:
                ctx.fail("idm-labels-localized", "slide {0}".format(slide["number"]),
                         "{0}.Label is {1!r}, language {2!r} expects {3!r}".format(
                             box, actual, ctx.language, label))


def check_headline_length(ctx):
    for slide in ctx.slides:
        limit = HEADLINE_MAX_IDM if slide["layout"] == "is-does-means" else HEADLINE_MAX
        length = len(slide["headline"])
        if length > limit:
            ctx.fail("headline-length", "slide {0}".format(slide["number"]),
                     "headline is {0} characters, ceiling {1}".format(length, limit))


def check_jargon_client_facing(ctx):
    for slide in ctx.slides:
        if slide["slide_kind"] == "internal-prep":
            continue
        for path, text in ctx.client_facing(slide):
            hit = next((term for term in JARGON if term in text), None)
            if hit is None and JARGON_RE.search(text):
                hit = JARGON_RE.search(text).group(0)
            if hit:
                ctx.fail("jargon-client-facing", "slide {0}".format(slide["number"]),
                         "methodology term {0!r} in {1}".format(hit, ".".join(path)))


def check_density_idm(ctx):
    for slide in ctx.slides:
        if slide["layout"] != "is-does-means":
            continue
        for box, budget in IDM_BUDGET.items():
            count = _words(_get(slide["fields"], box + ".Text"))
            if count > budget:
                ctx.fail("density-idm", "slide {0}".format(slide["number"]),
                         "{0}.Text has {1} words, budget {2}".format(box, count, budget))


def check_density_bullets(ctx):
    for slide in ctx.slides:
        if slide["slide_kind"] == "references":
            continue
        for key, value in slide["fields"].items():
            if not isinstance(value, dict) or "Bullets" not in value:
                continue
            if not (key == "Context-Box" or key.endswith("-Column") or key.startswith("Quadrant-")):
                continue
            bullets = value["Bullets"]
            if not isinstance(bullets, list):
                continue
            unit = "slide {0}".format(slide["number"])
            if len(bullets) > BULLETS_PER_FIELD_MAX:
                ctx.fail("density-bullets", unit,
                         "{0}.Bullets has {1} bullets, max {2}".format(key, len(bullets), BULLETS_PER_FIELD_MAX))
            for bullet in bullets:
                count = _words(bullet)
                if count > BULLET_WORDS_MAX:
                    ctx.fail("density-bullets", unit,
                             "{0} bullet has {1} words, max {2}: {3!r}".format(
                                 key, count, BULLET_WORDS_MAX, bullet))


def check_density_banner(ctx):
    for slide in ctx.slides:
        count = _words(_banner_text(slide["fields"]))
        if count > BANNER_WORDS_MAX:
            ctx.fail("density-banner", "slide {0}".format(slide["number"]),
                     "Bottom-Banner has {0} words, max {1}".format(count, BANNER_WORDS_MAX))


def check_notes_sections(ctx):
    for slide in ctx.slides:
        notes = slide["speaker_notes"]
        if not isinstance(notes, str) or not notes.strip():
            continue
        headers = sum(1 for l in notes.splitlines() if l.strip().startswith(">>"))
        if headers < 2:
            ctx.fail("notes-sections", "slide {0}".format(slide["number"]),
                     "Speaker-Notes carry {0} `>>` section header(s); both sections are required".format(headers))


def check_notes_words(ctx):
    for slide in ctx.content_slides():
        notes = slide["speaker_notes"]
        if not isinstance(notes, str) or not notes.strip():
            continue
        count = _words(notes)
        if count < NOTES_WORDS_MIN or count > NOTES_WORDS_MAX:
            ctx.warn("notes-words", "slide {0}".format(slide["number"]),
                     "Speaker-Notes have {0} words, target {1}-{2}".format(count, NOTES_WORDS_MIN, NOTES_WORDS_MAX))


def check_notes_no_sup(ctx):
    for slide in ctx.slides:
        notes = slide["speaker_notes"]
        if isinstance(notes, str) and ctx.pb.CITATION_RE.search(notes):
            ctx.fail("notes-no-sup", "slide {0}".format(slide["number"]),
                     "superscript citation inside Speaker-Notes — notes take plain [N](url) links")


def check_cite_format(ctx):
    for slide in ctx.slides:
        if slide["slide_kind"] == "references":
            continue
        for path, text in ctx.client_facing(slide):
            if path == ("heading",):
                continue
            if BARE_CITE_RE.search(SUP_RE.sub("", text)):
                ctx.fail("cite-format", "slide {0}".format(slide["number"]),
                         "bare [N](url) in {0} — body citations are <sup>[N](url)</sup>".format(".".join(path)))


def check_cite_sequence(ctx):
    by_number = {}
    for n, url, slide_no in ctx.citations():
        by_number.setdefault(n, set()).add(url)
    if not by_number:
        return
    numbers = sorted(by_number)
    if numbers != list(range(1, len(numbers) + 1)):
        ctx.fail("cite-sequence", "deck",
                 "citation numbers {0} are not 1..{1}".format(numbers, len(numbers)))
    for n, urls in by_number.items():
        if len(urls) > 1:
            ctx.fail("cite-sequence", "deck",
                     "citation [{0}] points at {1} different URLs".format(n, len(urls)))


def check_cite_zones(ctx):
    for slide in ctx.slides:
        unit = "slide {0}".format(slide["number"])
        zones = [("heading", slide["headline"]), ("Slide-Title", slide["fields"].get("Slide-Title")),
                 ("Bottom-Banner", _banner_text(slide["fields"]))]
        for key, value in slide["fields"].items():
            if key == "Hero-Stat-Box" and isinstance(value, dict):
                zones += [("Hero-Stat-Box." + k, v) for k, v in value.items()]
            elif STEP_KEY_RE.match(key) and isinstance(value, dict):
                zones += [(key + "." + k, value.get(k)) for k in ("Label", "Number")]
            elif key in ("Context-Box", "Left-Column", "Right-Column") and isinstance(value, dict):
                zones.append((key + ".Headline", value.get("Headline")))
        for name, text in zones:
            # Both spellings: the superscript form and a bare [N](url). The heading
            # is the most important zone and cite-format skips it on purpose, so a
            # bare marker there would otherwise be caught by nothing.
            if isinstance(text, str) and ("<sup>" in text or BARE_CITE_RE.search(text)):
                ctx.fail("cite-zones", unit, "citation marker inside exclusion zone {0}".format(name))


def check_cite_references_complete(ctx):
    cited = sorted({n for n, _, _ in ctx.citations()})
    if not cited:
        return
    refs = [s for s in ctx.slides if s["slide_kind"] == "references"]
    if not refs:
        ctx.fail("cite-references-complete", "deck",
                 "{0} citation(s) but no `Slide-Kind: references` slide".format(len(cited)))
        return
    text = "\n".join(t for _, t in _leaves(refs[-1]["fields"]))
    for n in cited:
        if "[{0}]".format(n) not in text:
            ctx.fail("cite-references-complete", "slide {0}".format(refs[-1]["number"]),
                     "citation [{0}] is missing from the references slide".format(n))


def check_deck_bookends(ctx):
    if not ctx.slides:
        return
    first = ctx.slides[0]
    if first["layout"] != "title-slide":
        ctx.fail("deck-bookends", "slide {0}".format(first["number"]),
                 "first slide is {0!r}, must be title-slide".format(first["layout"]))
    body = [s for s in ctx.slides if s["slide_kind"] != "references"]
    if body and body[-1]["layout"] != "closing-slide":
        ctx.fail("deck-bookends", "slide {0}".format(body[-1]["number"]),
                 "last non-references slide is {0!r}, must be closing-slide".format(body[-1]["layout"]))


def check_deck_count(ctx):
    content = ctx.content_slides()
    ceiling = ctx.max_slides_arg
    if ceiling is None:
        fm_value = ctx.frontmatter.get("max_slides")
        ceiling = fm_value if isinstance(fm_value, int) and not isinstance(fm_value, bool) else DECK_MAX_DEFAULT
    if len(content) < DECK_MIN_CONTENT:
        ctx.fail("deck-count", "deck", "{0} content slides, minimum {1}".format(len(content), DECK_MIN_CONTENT))
    if len(content) > ceiling:
        ctx.fail("deck-count", "deck", "{0} content slides, max_slides {1}".format(len(content), ceiling))


def check_deck_variety(ctx):
    body = [s for s in ctx.content_slides() if s["layout"] not in ("title-slide", "closing-slide")]
    if not body:
        return
    distinct = {s["layout"] for s in body}
    needed = min(3, len(body))
    if len(distinct) < needed:
        ctx.fail("deck-variety", "deck",
                 "{0} body slides use {1} layout(s); at least {2} distinct layouts expected".format(
                     len(body), len(distinct), needed))


def check_deck_consecutive(ctx):
    run, previous = 0, None
    for slide in ctx.content_slides():
        if slide["layout"] == previous:
            run += 1
        else:
            run, previous = 1, slide["layout"]
        if run >= CONSECUTIVE_RUN:
            ctx.fail("deck-consecutive", "slide {0}".format(slide["number"]),
                     "{0} consecutive slides use {1!r}".format(run, previous))


def check_deck_prep_slides(ctx):
    if len(ctx.slides) < 2:
        return
    second = ctx.slides[1]
    if second["slide_kind"] != "internal-prep" or second["layout"] != "process-flow" \
            or not second["diagram_mermaid"]:
        ctx.fail("deck-prep-slides", "slide {0}".format(second["number"]),
                 "Slide 2 must be the Methodology slide: `Slide-Kind: internal-prep`, "
                 "`Layout: process-flow`, with a Diagram")
    seen_content = False
    for slide in ctx.slides[1:]:
        if slide["slide_kind"] == "internal-prep":
            if seen_content:
                ctx.fail("deck-prep-slides", "slide {0}".format(slide["number"]),
                         "internal-prep slide after a content slide — prep slides sit right after Slide 1")
            banner = _banner_text(slide["fields"]) or ""
            if "INTERN" not in banner.upper():
                ctx.fail("deck-prep-slides", "slide {0}".format(slide["number"]),
                         "internal-prep slide carries no INTERNAL warning banner")
        else:
            seen_content = True


def check_deck_references_last(ctx):
    refs = [i for i, s in enumerate(ctx.slides) if s["slide_kind"] == "references"]
    if len(refs) > 1:
        ctx.fail("deck-references-last", "deck", "{0} references slides, at most one".format(len(refs)))
    if refs:
        refs_idx = refs[-1]
        if refs_idx != len(ctx.slides) - 1:
            ctx.fail("deck-references-last", "slide {0}".format(ctx.slides[refs_idx]["number"]),
                     "references slide is not the last slide in the deck")
        return
    if ctx.citations():
        ctx.fail("deck-references-last", "deck", "citations present but no references slide")
    else:
        ctx.warn("deck-references-last", "deck", "no references slide (and no citations)")


# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

ALL_PROFILES = ("slides", "web", "storyboard", "infographic")
SLIDES_ONLY = ("slides",)

CHECKS = (
    # name, profiles, default severity, function
    ("fm-core-keys", ALL_PROFILES, "fail", check_fm_core_keys),
    ("fm-type-version", ALL_PROFILES, "fail", check_fm_type_version),
    ("fm-theme-path", SLIDES_ONLY, "fail", check_fm_theme_path),
    ("fm-confidence", SLIDES_ONLY, "fail", check_fm_confidence),
    ("unit-fenced", ALL_PROFILES, "fail", check_unit_fenced),
    ("unit-numbering", ALL_PROFILES, "fail", check_unit_numbering),
    ("layout-enum", SLIDES_ONLY, "fail", check_layout_enum),
    ("layout-required-fields", SLIDES_ONLY, "fail", check_layout_required_fields),
    ("layout-unknown-fields", SLIDES_ONLY, "fail", check_layout_unknown_fields),
    ("no-color-fields", ALL_PROFILES, "fail", check_no_color_fields),
    ("diagram-constraints", SLIDES_ONLY, "fail", check_diagram_constraints),
    ("render-contract-section", SLIDES_ONLY, "fail", check_render_contract_section),
    ("idm-labels-localized", SLIDES_ONLY, "fail", check_idm_labels_localized),
    ("headline-length", SLIDES_ONLY, "fail", check_headline_length),
    ("jargon-client-facing", SLIDES_ONLY, "fail", check_jargon_client_facing),
    ("density-idm", SLIDES_ONLY, "fail", check_density_idm),
    ("density-bullets", SLIDES_ONLY, "fail", check_density_bullets),
    ("density-banner", SLIDES_ONLY, "fail", check_density_banner),
    ("notes-sections", SLIDES_ONLY, "fail", check_notes_sections),
    ("notes-words", SLIDES_ONLY, "warn", check_notes_words),
    ("notes-no-sup", SLIDES_ONLY, "fail", check_notes_no_sup),
    ("cite-format", SLIDES_ONLY, "fail", check_cite_format),
    ("cite-sequence", SLIDES_ONLY, "fail", check_cite_sequence),
    ("cite-zones", SLIDES_ONLY, "fail", check_cite_zones),
    ("cite-references-complete", SLIDES_ONLY, "fail", check_cite_references_complete),
    ("deck-bookends", SLIDES_ONLY, "fail", check_deck_bookends),
    ("deck-count", SLIDES_ONLY, "fail", check_deck_count),
    ("deck-variety", SLIDES_ONLY, "fail", check_deck_variety),
    ("deck-consecutive", SLIDES_ONLY, "fail", check_deck_consecutive),
    ("deck-prep-slides", SLIDES_ONLY, "fail", check_deck_prep_slides),
    ("deck-references-last", SLIDES_ONLY, "fail", check_deck_references_last),
    ("cta-summary-consistent", ALL_PROFILES, "fail", check_cta_summary_consistent),
    ("metadata-block", ALL_PROFILES, "warn", check_metadata_block),
)


def emit(success, data=None, error="", code=0):
    print(json.dumps({"success": success, "data": data or {}, "error": error}, ensure_ascii=False))
    return code


def run_checks(ctx):
    for name, profiles, _severity, fn in CHECKS:
        if ctx.type not in profiles:
            continue
        fn(ctx)
        ctx.checks_run.append(name)
    fails = sum(1 for f in ctx.findings if f["severity"] == "fail")
    warns = sum(1 for f in ctx.findings if f["severity"] == "warn")
    return {
        "type": ctx.type,
        "brief": ctx.path,
        "version": ctx.version,
        "checks_run": ctx.checks_run,
        "findings": ctx.findings,
        "fails": fails,
        "warns": warns,
    }


class _EnvelopeParser(argparse.ArgumentParser):
    def error(self, message):
        emit(False, None, "argument error: {0}".format(message), 2)
        raise SystemExit(2)


def main():
    parser = _EnvelopeParser(description="Lint a brief against its machine-checkable rules.")
    parser.add_argument("brief", nargs="?", help="path to the brief")
    parser.add_argument("--type", dest="brief_type", help="slides | web | storyboard | infographic")
    parser.add_argument("--max-slides", type=int, default=None, help="content-slide ceiling (slides)")
    parser.add_argument("--strict", action="store_true", help="promote warnings to failures")
    parser.add_argument("--list-checks", action="store_true", help="list every check and exit")
    args = parser.parse_args()

    if args.list_checks:
        checks = [{"name": n, "profiles": list(p), "severity": s} for n, p, s, _ in CHECKS]
        return emit(True, {"checks": checks, "layouts": list(LAYOUT_ENUM)})

    if args.brief_type not in PROFILES:
        return emit(False, None, "--type must be one of: {0}".format(", ".join(PROFILES)), 2)
    if not args.brief:
        return emit(False, None, "a brief path is required", 2)

    try:
        ctx = Context(args.brief_type, args.brief, args.max_slides, args.strict)
        data = run_checks(ctx)
    except CheckError as exc:
        return emit(False, None, str(exc), 2)
    except Exception as exc:  # never surface a traceback
        return emit(False, None, "checker error: {0}".format(exc), 2)

    return emit(data["fails"] == 0, data, "", 0 if data["fails"] == 0 else 1)


if __name__ == "__main__":
    sys.exit(main())
