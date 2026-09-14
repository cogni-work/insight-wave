"""Target-neutral core of design-render: inputs, theme, fonts, the target-resolved-plan@2 and provenance.

Stdlib only. Nothing here writes a file, reads the environment or the home directory, or knows how a
target draws a unit: it validates the inputs through the publishing validator, resolves the theme's
tokens through the token compiler, resolves fonts from references/font-fallbacks-v1.json, lays every
composition unit out on a fixed canvas and records what was used. A target adapter (html_adapter.py)
turns the result into an artifact. references/design-render.md is the normative description.
"""

import hashlib
import importlib.util
import json
import math
import re
from pathlib import Path

SCRIPTS = Path(__file__).absolute().parent
PLUGIN_ROOT = SCRIPTS.parent
REFERENCES = PLUGIN_ROOT / "references"
FONT_FALLBACKS = REFERENCES / "font-fallbacks-v1.json"
RUNTIME_DIR = PLUGIN_ROOT / "runtime"

RENDERER_NAME = "cogni-publishing/design-render"
CANVAS = {"unit": "px", "width": 1280, "height": 720}
VOLATILE_FIELDS = ("generated_at", "run_id")

# Token roles every theme must supply. Colors, the copy font, the type scale and the spacing steps
# the layout uses; a missing one is an invalid-theme finding that names it.
REQUIRED_TOKENS = (
    ("colors", "text"), ("colors", "bg"), ("colors", "surface"), ("colors", "accent"),
    ("colors", "text-muted"), ("colors", "border"),
    ("typography", "font-sans"),
    ("typography", "size-display"), ("typography", "line-height-display"),
    ("typography", "size-h2"), ("typography", "line-height-h2"),
    ("typography", "size-h3"), ("typography", "line-height-h3"),
    ("typography", "size-body"), ("typography", "line-height-body"),
    ("typography", "size-small"), ("typography", "line-height-small"),
    ("spacing", "3"), ("spacing", "4"), ("spacing", "5"), ("spacing", "6"), ("spacing", "7"),
)
COPY_FONT_TOKEN = "typography.font-sans"

# Each type role of the pattern library's scale maps to one size and line-height token pair.
TYPE_ROLE_TOKENS = {
    "type.display": ("size-display", "line-height-display"),
    "type.heading": ("size-h2", "line-height-h2"),
    "type.lead": ("size-h3", "line-height-h3"),
    "type.body": ("size-body", "line-height-body"),
    "type.caption": ("size-small", "line-height-small"),
}
# The role a slot is set in before the pattern's minimum typography role (or a unit's type_floor)
# raises it. Headlines lead; notes sit aside at body size.
SLOT_ROLES = {
    "answer": "type.display", "claim": "type.heading", "heading": "type.heading",
    "support": "type.lead", "context": "type.body", "items": "type.body", "entities": "type.body",
    "series": "type.body", "evidence": "type.caption", "notes": "type.body",
}
ASIDE_SLOTS = {"notes"}


class RenderError(Exception):
    """A rejection. `code` and `check` name the finding; exit status 1 unless `usage` says 2."""

    def __init__(self, code, message, check, reference=None, artifact=None, status=1):
        super().__init__(message)
        self.status = status
        self.finding = {"code": code, "check": check}
        if artifact is not None:
            self.finding["artifact"] = artifact
        if reference is not None:
            self.finding["reference"] = reference


def load_script(name, filename):
    """Import a sibling cogni-publishing script by path, so one validator and one token compiler serve
    every caller and no schema is forked."""
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_script("cogni_publishing_validator", "validate-publishing.py")
tokens_compiler = load_script("cogni_publishing_tokens", "generate-tokens-css.py")


# --- literal-preserving JSON ------------------------------------------------------------------------

class FloatLiteral(float):
    """A JSON number that remembers how the brief wrote it, so a label never reformats it."""

    def __new__(cls, text):
        value = super().__new__(cls, text)
        value.literal = text
        return value


class IntLiteral(int):
    def __new__(cls, text):
        value = super().__new__(cls, text)
        value.literal = text
        return value


def read_json(path, artifact):
    try:
        text = Path(path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise RenderError("runtime-error", f"cannot read {artifact} {path}: {exc}", "input", artifact=artifact,
                          status=2) from exc
    try:
        return json.loads(text, parse_float=FloatLiteral, parse_int=IntLiteral)
    except json.JSONDecodeError as exc:
        raise RenderError("invalid-artifact", f"{artifact} {path} is not JSON: {exc}", "input",
                          artifact=artifact) from exc


def number_text(value):
    """The number exactly as the brief wrote it."""
    literal = getattr(value, "literal", None)
    return literal if literal is not None else validator.canonical(value)


def sha256_bytes(data):
    return "sha256:" + hashlib.sha256(data).hexdigest()


def sha256_file(path):
    return sha256_bytes(Path(path).read_bytes())


# --- inputs ---------------------------------------------------------------------------------------

def validate_inputs(brief, composition):
    """Both inputs through the publishing validator; any contract finding stops the render."""
    try:
        library, _ = validator.load_library(validator.DEFAULT_LIBRARY)
        summary = validator.validate_composition(brief, composition, library)
    except validator.ContractError as exc:
        error = RenderError(exc.finding["code"], str(exc), exc.finding.get("check", "composition"),
                            exc.finding.get("reference"), exc.finding.get("artifact"))
        error.finding = dict(exc.finding)
        raise error from exc
    return library, summary


class Content:
    """Read access to the frozen content a composition binds: record fields, data items, sources."""

    def __init__(self, brief):
        self.brief = brief
        self.index = validator.BriefIndex(brief)
        self.index.sources = brief.get("sources", [])
        self.sources = {source["id"]: source for source in brief.get("sources", [])}
        self.source_order = [source["id"] for source in brief.get("sources", [])]

    def field(self, record_ref, field):
        found = self.index.field(record_ref, field)
        return None if found is None else found[1]

    def data(self, data_ref):
        return self.index.data[data_ref]

    def texts(self, entry):
        """The strings a plan content entry lays out, for line estimation only."""
        if "record_ref" in entry:
            value = self.field(entry["record_ref"], entry["field"])
            return list(value) if isinstance(value, list) else [value]
        if "data_ref" in entry:
            item = self.data(entry["data_ref"])
            return [f"{item.get('label', '')} {number_text(item['value'])} {item.get('unit', '')}"]
        source = self.sources[entry["source_ref"]]
        return [source_line(source)]


def source_line(source):
    """A source entry as one line: the verbatim raw line of a narrative source, otherwise its fields."""
    if isinstance(source.get("raw"), str):
        return source["raw"]
    return " ".join(str(source[key]) for key in source_fields(source))


def source_fields(source):
    """The displayable fields of a direct source, in the order the brief wrote them."""
    return [key for key, value in source.items() if key != "id" and isinstance(value, str) and value]


def language_of(brief, override):
    if override:
        return override
    metadata = brief.get("metadata")
    language = metadata.get("language") if isinstance(metadata, dict) else None
    return language if isinstance(language, str) and language else "en"


# --- theme ----------------------------------------------------------------------------------------

class Theme:
    def __init__(self, directory, slug, compiled, tokens):
        self.directory = directory
        self.slug = slug
        self.compiled = compiled
        self.tokens = tokens  # {stem: {key: literal}}
        self.css = tokens_compiler.render_css(compiled)
        self.digest = validator.digest_of(tokens)

    def value(self, stem, key):
        return self.tokens[stem][key]

    def px(self, stem, key):
        return parse_px(self.value(stem, key), f"{stem}.{key}")


def parse_px(value, token):
    text = str(value).strip()
    match = re.fullmatch(r"(-?[0-9]+(?:\.[0-9]+)?)(px)?", text)
    if not match:
        raise RenderError("invalid-theme", f"token {token} is {text!r}; the layout needs a px length",
                          "theme-token-unit", token, artifact="theme")
    return float(match.group(1))


def parse_ratio(value, token):
    text = str(value).strip()
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", text):
        raise RenderError("invalid-theme", f"token {token} is {text!r}; a line height is a unitless ratio",
                          "theme-token-unit", token, artifact="theme")
    return float(text)


def resolve_theme(theme_path, design_system):
    """A theme directory (or its theme.md) whose slug equals the composition's design_system name and
    whose tokens/*.json compile and carry every required role."""
    path = Path(theme_path)
    directory = path.parent if path.name == "theme.md" else path
    if not (directory / "theme.md").is_file():
        raise RenderError("invalid-theme", f"{directory} holds no theme.md", "theme-md", str(directory),
                          artifact="theme")
    slug = directory.name
    if slug != design_system["name"]:
        raise RenderError("invalid-theme", f"the composition pins design system {design_system['name']!r}, but the "
                          f"theme is {slug!r}", "theme-slug", slug, artifact="theme")
    tokens_dir = directory / "tokens"
    if not tokens_dir.is_dir():
        raise RenderError("invalid-theme", f"theme {slug} has no tokens/ directory; design-render reads the "
                          "authoritative tokens/*.json", "theme-tokens", slug, artifact="theme")
    try:
        compiled = tokens_compiler.compile_dir(tokens_dir)
        resolved = tokens_compiler.render_resolved(compiled)["tokens"]
    except tokens_compiler.TokenError as exc:
        raise RenderError("invalid-theme", str(exc), "theme-tokens", exc.token, artifact="theme") from exc
    except (OSError, ValueError) as exc:
        raise RenderError("invalid-theme", f"theme {slug} tokens cannot be read: {exc}", "theme-tokens", slug,
                          artifact="theme") from exc
    for stem, key in REQUIRED_TOKENS:
        if key not in resolved.get(stem, {}):
            raise RenderError("invalid-theme", f"theme {slug} lacks the required token {stem}.{key}",
                              "theme-token-missing", f"{stem}.{key}", artifact="theme")
    return Theme(directory, slug, compiled, resolved)


# --- fonts ----------------------------------------------------------------------------------------

def load_fallbacks():
    return json.loads(FONT_FALLBACKS.read_text(encoding="utf-8"))


def split_stack(value):
    """A CSS font-family value as a list of family names, quotes removed."""
    families, current, quote = [], "", None
    for char in str(value):
        if quote:
            if char == quote:
                quote = None
            else:
                current += char
        elif char in "'\"":
            quote = char
        elif char == ",":
            families.append(current.strip())
            current = ""
        else:
            current += char
    families.append(current.strip())
    return [family for family in families if family]


def resolve_font(token, stack_value, fallbacks):
    """Walk the requested stack: a bundled face or a generic family resolves; any other family is
    skipped and recorded. Returns the provenance record, which also carries the layout metrics."""
    requested = split_stack(stack_value)
    if not requested:
        raise RenderError("font-unresolved", f"{token} names no font family", "font-stack", token, artifact="theme")
    bundled = fallbacks.get("bundled_faces", {})
    generics = fallbacks["generic_families"]
    skipped = []
    for family in requested:
        if family in bundled:
            face = bundled[family]
            return {"token": token, "requested_stack": requested, "requested_family": requested[0],
                    "resolved_face": family, "substituted": family != requested[0], "skipped": skipped,
                    "fallback_chain": [family] + list(face.get("chain", [])), "advance_em": face["advance_em"],
                    "source": "bundled"}
        generic = generics.get(family.lower())
        if generic is not None:
            return {"token": token, "requested_stack": requested, "requested_family": requested[0],
                    "resolved_face": family.lower(), "substituted": family != requested[0], "skipped": skipped,
                    "fallback_chain": list(generic["chain"]), "advance_em": generic["advance_em"],
                    "source": "generic"}
        skipped.append(family)
    raise RenderError("font-unresolved", f"no member of {token} ({', '.join(requested)}) is bundled or generic; "
                      f"{requested[0]!r} cannot be rendered without a silent substitution", "font-stack", requested[0],
                      artifact="theme")


def resolve_fonts(theme):
    """The copy font is the one the layout measures with; every font token of the theme is recorded."""
    fallbacks = load_fallbacks()
    fonts = []
    for key in sorted(theme.tokens.get("typography", {})):
        if key.startswith("font-"):
            fonts.append(resolve_font(f"typography.{key}", theme.value("typography", key), fallbacks))
    copy_font = next(font for font in fonts if font["token"] == COPY_FONT_TOKEN)
    return fonts, copy_font


def font_record(font):
    """The provenance view of a resolved font — everything but the layout metric."""
    return {key: font[key] for key in ("token", "requested_stack", "requested_family", "resolved_face",
                                       "substituted", "skipped", "fallback_chain", "source")}


def css_font_stack(font):
    return ", ".join(family if family in {"system-ui", "sans-serif", "serif", "monospace"} else f'"{family}"'
                     for family in font["fallback_chain"])


# --- layout: target-resolved-plan@2 ---------------------------------------------------------------

def estimate_lines(text, width, size, advance_em):
    """Deterministic line estimate for one string set at `size` px in `width` px with the resolved
    face's documented advance. Never truncates: long content simply needs more lines."""
    per_line = max(1, int(width // (size * advance_em)))
    return sum(max(1, math.ceil(len(paragraph) / per_line)) for paragraph in str(text).split("\n"))


class Layout:
    def __init__(self, theme, font, library):
        self.theme = theme
        self.font = font
        self.scale = library["type_scale"]
        self.padding = theme.px("spacing", "7")
        self.gap = theme.px("spacing", "5")
        self.item_gap = theme.px("spacing", "3")
        self.node_pad = theme.px("spacing", "4")
        self.frame_gap = theme.px("spacing", "6")
        self.width = CANVAS["width"] - 2 * self.padding

    def metrics(self, role):
        size_key, height_key = TYPE_ROLE_TOKENS[role]
        return (self.theme.px("typography", size_key),
                parse_ratio(self.theme.value("typography", height_key), f"typography.{height_key}"))

    def role(self, slot, floor_role, placement):
        role = SLOT_ROLES.get(slot, "type.body")
        if placement == "canvas" and self.scale.index(role) < self.scale.index(floor_role):
            role = floor_role
        return role

    def text_block(self, texts, width, role):
        size, ratio = self.metrics(role)
        lines = [estimate_lines(text, width, size, self.font["advance_em"]) for text in texts]
        height = sum(lines) * size * ratio + max(0, len(texts) - 1) * self.item_gap
        return sum(lines), height


def round_box(x, y, width, height):
    return {"x": round(x, 2), "y": round(y, 2), "width": round(width, 2), "height": round(height, 2)}


def layout_slot(layout, unit, pattern, slot, entries, content, y, role):
    """Height and line count of one canvas slot; the pattern and variant decide the arrangement."""
    texts = [text for entry in entries for text in content.texts(entry)]
    x, width = layout.padding, layout.width
    if slot == "items" and unit["variant"] == "parallel":
        columns = max(1, len(texts))
        column = (width - (columns - 1) * layout.gap) / columns
        blocks = [layout.text_block([text], column, role) for text in texts]
        return sum(b[0] for b in blocks), max(b[1] for b in blocks)
    if slot == "series":
        size, ratio = layout.metrics(role)
        row = max(size * ratio, 28.0) + layout.item_gap
        return len(texts), len(texts) * row
    if slot == "entities":
        size, ratio = layout.metrics(role)
        lines, height = 0, 0.0
        for text in texts:
            node_lines = estimate_lines(text, width - 2 * layout.node_pad, size, layout.font["advance_em"])
            lines += node_lines
            height += node_lines * size * ratio + 2 * layout.node_pad
        return lines, height + max(0, len(texts) - 1) * layout.gap
    return layout.text_block(texts, width, role)


def build_plan(brief, composition, library, theme, font, generated_at, run_id, target="html"):
    content = Content(brief)
    layout = Layout(theme, font, library)
    patterns = {pattern["id"]: pattern for pattern in library["patterns"]}
    units, frame_y = [], 0.0
    for unit in composition["units"]:
        pattern = patterns[unit["pattern"]]
        floor_role = unit.get("type_floor", pattern["constraints"]["min_type_role"])
        expected = validator.expected_slot_content(unit, content.index, pattern["family"])
        cursor, slots = layout.padding, []
        for slot in pattern["accessibility"]["reading_order"]:
            if slot not in expected:
                continue
            entries = expected[slot]
            placement = "aside" if slot in ASIDE_SLOTS else "canvas"
            role = layout.role(slot, floor_role, placement)
            if placement == "aside":
                texts = [text for entry in entries for text in content.texts(entry)]
                lines, _ = layout.text_block(texts, layout.width, role)
                box = None
            else:
                lines, height = layout_slot(layout, unit, pattern, slot, entries, content, cursor, role)
                box = round_box(layout.padding, cursor, layout.width, height)
                cursor += height + layout.gap
            slots.append({"slot": slot, "placement": placement, "box": box, "type_role": role,
                          "measured_with": font["resolved_face"], "lines": lines, "content": entries})
        height = max(CANVAS["height"], cursor - layout.gap + layout.padding)
        units.append({"composition_unit_ref": unit["id"], "pattern": unit["pattern"], "variant": unit["variant"],
                      "frame": round_box(0, frame_y, CANVAS["width"], height), "slots": slots})
        frame_y += height + layout.frame_gap
    return {
        "artifact_type": "target-resolved-plan",
        "artifact_version": "2",
        "artifact_id": f"plan:{target}:{composition['artifact_id']}",
        "composition_ref": {"artifact_id": composition["artifact_id"], "artifact_version": "2"},
        "normalized_brief_ref": {"artifact_id": brief["artifact_id"], "artifact_version": brief["artifact_version"],
                                 "content_fingerprint": validator.content_fingerprint(brief)},
        "pattern_library_ref": {"artifact_id": library["artifact_id"], "artifact_version": library["artifact_version"]},
        "target": target,
        "design_system": dict(composition["design_system"]),
        "canvas": dict(CANVAS),
        "document_bindings": list(composition["document_bindings"]),
        "units": units,
        "generated_at": generated_at,
        "run_id": run_id,
    }


def check_plan(brief, composition, plan, library):
    try:
        return validator.check_plan(brief, composition, plan, library)
    except validator.ContractError as exc:
        error = RenderError(exc.finding["code"], str(exc), exc.finding.get("check", "plan"))
        error.finding = dict(exc.finding)
        raise error from exc


# --- runtime pin and provenance ---------------------------------------------------------------------

def runtime_pin():
    """The committed pin: the runtime manifest's exact dependency versions and the lockfile digest."""
    manifest = json.loads((RUNTIME_DIR / "package.json").read_text(encoding="utf-8"))
    return {"name": manifest.get("name"), "dependencies": dict(manifest.get("dependencies", {})),
            "lock": "runtime/package-lock.json", "lock_sha256": sha256_file(RUNTIME_DIR / "package-lock.json")}


def renderer_version():
    manifest = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))
    return manifest.get("version")


def build_provenance(brief, composition, library, theme, fonts, plan_bytes, artifact_bytes, language,
                     generated_at, run_id, measurement=None, target="html", artifact_name="index.html",
                     extra_outputs=None):
    """`extra_outputs` maps an output name to (path, bytes) for a target that writes more than a plan and
    one artifact — the PPTX target's manifest."""
    fingerprint = validator.content_fingerprint(brief)
    outputs = {
        "target_plan": {"path": "target-plan.json", "sha256": sha256_bytes(plan_bytes)},
        "artifact": {"path": artifact_name, "sha256": sha256_bytes(artifact_bytes)},
    }
    for name, (path, data) in (extra_outputs or {}).items():
        outputs[name] = {"path": path, "sha256": sha256_bytes(data)}
    return {
        "artifact_type": "render-provenance",
        "artifact_version": "1",
        "artifact_id": f"provenance:{target}:{composition['artifact_id']}",
        "renderer": {"name": RENDERER_NAME, "version": renderer_version(), "target": target},
        "runtime": dict(runtime_pin(), used=measurement is not None),
        "design_system": dict(composition["design_system"]),
        "theme": {"slug": theme.slug, "tokens_sha256": theme.digest},
        "inputs": {
            "normalized_brief": {"artifact_id": brief["artifact_id"], "artifact_version": brief["artifact_version"]},
            "semantic_composition": {"artifact_id": composition["artifact_id"],
                                     "artifact_version": composition["artifact_version"]},
            "pattern_library": {"artifact_id": library["artifact_id"], "artifact_version": library["artifact_version"]},
        },
        "content_fingerprint": fingerprint,
        "language": language,
        "outputs": outputs,
        "fonts": [font_record(font) for font in fonts],
        "layout_face": next(font for font in fonts if font["token"] == COPY_FONT_TOKEN)["resolved_face"],
        "measurement": measurement,
        "generated_at": generated_at,
        "run_id": run_id,
    }
