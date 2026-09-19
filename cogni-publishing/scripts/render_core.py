"""Shared frozen-input, theme, font and text-measurement helpers for independent verification.

Python standard library only. This module contains no artifact writer or layout planner.
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

CANVAS = {"unit": "px", "width": 1280, "height": 720}

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
# The role a slot is set in when its pattern declares none, before the pattern's minimum typography
# role (or a unit's type_floor) raises it. Headlines lead; notes sit aside at body size. The library
# is the first carrier: a pattern's slot may declare default_type_role, and this table is the
# fallback for a slot that does not. See design-render.md §Type roles.
SLOT_ROLES = {
    "answer": "type.display", "figure": "type.display", "claim": "type.heading", "heading": "type.heading",
    "support": "type.lead", "context": "type.body", "items": "type.body", "entities": "type.body",
    "series": "type.body", "evidence": "type.caption", "notes": "type.body",
}
ASIDE_SLOTS = {"notes"}


def slot_default_role(pattern, slot):
    """The role `slot` starts at under `pattern`: the role the pattern's own slot declares in the
    library, else this module's fallback table. The canvas raise to the pattern's min_type_role or
    the unit's type_floor is the caller's, and applies to either answer. Every consumer of a slot's
    default role resolves it here, so the fact has one carrier at every read site."""
    declared = next((entry for entry in pattern.get("slots", []) if entry.get("id") == slot), {})
    return declared.get("default_type_role", SLOT_ROLES.get(slot, "type.body"))

# A theme may ship licensed faces, declared in this file under its directory. Each face names a file
# inside the theme in one of the sfnt formats, recognised by the signature its bytes must start with,
# and the media type an embedding target labels it with. A family may ship several weights, each its
# own face; a declaration that names no weight is the regular one, which copy is set in.
FACES_FILE = "assets/fonts/faces.json"
FACE_FORMATS = {
    "truetype": ("font/ttf", (b"\x00\x01\x00\x00", b"true")),
    "opentype": ("font/otf", (b"OTTO",)),
}
FACE_FAMILY = re.compile(r"[A-Za-z0-9][A-Za-z0-9 _-]{0,63}")
FACE_WEIGHTS = (1, 1000)
COPY_WEIGHT = 400


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


# --- theme ----------------------------------------------------------------------------------------

class Theme:
    def __init__(self, directory, slug, compiled, tokens, faces=None):
        self.directory = directory
        self.slug = slug
        self.compiled = compiled
        self.tokens = tokens  # {stem: {key: literal}}
        self.css = tokens_compiler.render_css(compiled)
        self.digest = validator.digest_of(tokens)
        self.faces = faces or {}  # {(family, weight): shipped face}, in declaration order

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
    faces = load_faces(directory, slug, set(load_fallbacks()["generic_families"]))
    return Theme(directory, slug, compiled, resolved, faces)


def face_error(slug, reference, message):
    return RenderError("invalid-theme", f"theme {slug}: {message}", "theme-font", reference, artifact="theme")


def theme_file(directory, slug, value, field):
    """A path the face declaration names: relative to the theme directory, free of '..', and still inside
    the theme once every symlink resolves — a theme is untrusted input, and the file's bytes are copied
    into the artifact — and naming a file."""
    if not isinstance(value, str) or not value.strip():
        raise face_error(slug, str(value), f"a shipped face's {field} must be a path inside the theme")
    relative = Path(value)
    if relative.is_absolute() or value.startswith(("/", "\\")) or re.match(r"[A-Za-z]:", value) \
            or ".." in relative.parts:
        raise face_error(slug, value, f"the {field} {value!r} is not a path inside the theme")
    try:
        root, target = directory.resolve(), (directory / relative).resolve()
    except (OSError, RuntimeError) as exc:
        raise face_error(slug, value, f"the {field} {value!r} cannot be resolved: {exc}") from exc
    if root not in target.parents:
        raise face_error(slug, value, f"the {field} {value!r} resolves outside the theme")
    if not target.is_file():
        raise face_error(slug, value, f"the {field} {value!r} names no file in the theme")
    return target


def load_faces(directory, slug, generics):
    """The licensed faces a theme ships, from its optional FACES_FILE. Every declaration is validated
    before anything is written: a family that is a safe name and not a generic keyword; a weight that is
    an integer in the CSS range, COPY_WEIGHT when the declaration names none, and unique within its
    family; a contained file whose bytes carry its format's signature and are no other face's bytes; a
    licence file beside it; and a positive advance_em, the declared metric the layout measures with. A
    theme that declares nothing ships no face."""
    declaration = directory / FACES_FILE
    if not declaration.exists() and not declaration.is_symlink():
        return {}
    path = theme_file(directory, slug, FACES_FILE, "declaration")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise face_error(slug, FACES_FILE, f"{FACES_FILE} is not readable JSON: {exc}") from exc
    entries = data.get("faces") if isinstance(data, dict) else None
    if not isinstance(entries, list) or not entries:
        raise face_error(slug, FACES_FILE, f"{FACES_FILE} declares no faces list")
    faces, digests = {}, set()
    for entry in entries:
        family = entry.get("family") if isinstance(entry, dict) else None
        if not isinstance(family, str) or not FACE_FAMILY.fullmatch(family) or family.lower() in generics:
            raise face_error(slug, str(family), f"{family!r} is not a plain family name for a shipped face")
        weight = entry.get("weight", COPY_WEIGHT)
        if isinstance(weight, bool) or not isinstance(weight, int) \
                or not FACE_WEIGHTS[0] <= weight <= FACE_WEIGHTS[1]:
            raise face_error(slug, family, f"{family} declares weight {weight!r}; a shipped face's weight is an "
                             f"integer from {FACE_WEIGHTS[0]} to {FACE_WEIGHTS[1]}")
        if (family, weight) in faces:
            raise face_error(slug, family, f"{family} declares weight {weight} twice; each weight of a family is "
                             "one shipped face")
        form = entry.get("format")
        if form not in FACE_FORMATS:
            raise face_error(slug, family, f"{family} declares format {form!r}; a shipped face is "
                             f"{' or '.join(FACE_FORMATS)}")
        target = theme_file(directory, slug, entry.get("file"), "file")
        theme_file(directory, slug, entry.get("licence"), "licence")
        advance = entry.get("advance_em")
        if isinstance(advance, bool) or not isinstance(advance, (int, float)) or not math.isfinite(advance) \
                or advance <= 0:
            raise face_error(slug, family, f"{family} declares advance_em {advance!r}; the layout needs a "
                             "positive number")
        payload = target.read_bytes()
        mime, signatures = FACE_FORMATS[form]
        if not payload.startswith(signatures):
            raise face_error(slug, entry["file"], f"{entry['file']} does not start with a {form} signature")
        digest = sha256_bytes(payload)
        if digest in digests:
            # The fidelity check knows an embedded face by its bytes, so one file under two declarations
            # would let a page label either weight with it.
            raise face_error(slug, entry["file"], f"{entry['file']} carries the bytes of a face already declared")
        digests.add(digest)
        faces[(family, weight)] = {"family": family, "weight": weight, "file": entry["file"], "path": target,
                                   "format": form, "mime": mime, "advance_em": float(advance), "sha256": digest,
                                   "data": payload}
    return faces


def family_faces(faces):
    """The shipped faces grouped by family, each family's faces ordered by weight."""
    grouped = {}
    for face in faces.values():
        grouped.setdefault(face["family"], []).append(face)
    return {family: sorted(members, key=lambda face: face["weight"]) for family, members in grouped.items()}


def copy_face(members):
    """The face of one family that regular copy is set in: the face CSS font matching picks for
    COPY_WEIGHT — the lowest declared weight from COPY_WEIGHT up to 500, else the highest one below
    COPY_WEIGHT, else the lowest one above 500."""
    by_weight = {face["weight"]: face for face in members}
    near = [weight for weight in by_weight if COPY_WEIGHT <= weight <= 500]
    if near:
        return by_weight[min(near)]
    lighter = [weight for weight in by_weight if weight < COPY_WEIGHT]
    if lighter:
        return by_weight[max(lighter)]
    return by_weight[min(weight for weight in by_weight if weight > 500)]


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


def resolve_font(token, stack_value, fallbacks, shipped=None):
    """Walk the requested stack: a family the theme ships (`shipped`, {family: its faces by weight},
    given only for a target that embeds them), a bundled face or a generic family resolves; any other
    family is skipped and recorded. Returns the provenance record, which also carries the layout
    metrics. A shipped family is measured with its copy face, and the record names every face of the
    family, since an embedding target carries each of them."""
    requested = split_stack(stack_value)
    if not requested:
        raise RenderError("font-unresolved", f"{token} names no font family", "font-stack", token, artifact="theme")
    bundled = fallbacks.get("bundled_faces", {})
    generics = fallbacks["generic_families"]
    skipped = []
    for index, family in enumerate(requested):
        members = (shipped or {}).get(family)
        if members:
            face = copy_face(members)
            rest = next((generics[later.lower()]["chain"] for later in requested[index + 1:]
                         if later.lower() in generics), [])
            return {"token": token, "requested_stack": requested, "requested_family": requested[0],
                    "resolved_face": family, "substituted": family != requested[0], "skipped": skipped,
                    "fallback_chain": [family] + list(rest), "advance_em": face["advance_em"],
                    "source": "theme", "file_sha256": face["sha256"],
                    "faces": [{"file": member["file"], "weight": member["weight"], "file_sha256": member["sha256"]}
                              for member in members]}
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
    raise RenderError("font-unresolved", f"no member of {token} ({', '.join(requested)}) is shipped by the theme, "
                      f"bundled or generic; {requested[0]!r} cannot be rendered without a silent substitution",
                      "font-stack", requested[0], artifact="theme")


def resolve_fonts(theme, embed_faces=False):
    """The copy font is the one the layout measures with; every font token of the theme is recorded. A
    face the theme ships resolves only when the target embeds it (`embed_faces`); a target that embeds no
    font skips it like any other unshipped family, so it can never substitute silently there."""
    fallbacks = load_fallbacks()
    shipped = family_faces(theme.faces) if embed_faces else None
    fonts = []
    for key in sorted(theme.tokens.get("typography", {})):
        if key.startswith("font-"):
            fonts.append(resolve_font(f"typography.{key}", theme.value("typography", key), fallbacks, shipped))
    copy_font = next(font for font in fonts if font["token"] == COPY_FONT_TOKEN)
    return fonts, copy_font


def font_record(font):
    """The provenance view of a resolved font — everything but the layout metric. A shipped family also
    records its copy face's file digest and, under `faces`, the digest of every face file of the family,
    which the theme's token digest does not cover."""
    record = {key: font[key] for key in ("token", "requested_stack", "requested_family", "resolved_face",
                                         "substituted", "skipped", "fallback_chain", "source")}
    for key in ("file_sha256", "faces"):
        if key in font:
            record[key] = font[key]
    return record


# --- conservative text measurement for verification ----------------------------------------------

# Figure geometry, defined once for the plan and every target adapter. A conceptual system keeps a
# gutter right of its nodes for the connector bends and their relationship-kind labels; a chart keeps
# its labels in a column on the left, clear of the marks by a small gap, and its marks in a band of
# CHART_BAR_SHARE to the right of that column. A row is never shorter than CHART_ROW_MIN, so a mark
# stays legible beside a one-line label, and every row of one chart is as tall as its tallest label
# needs, so a target that spreads its categories evenly over the series box keeps each mark on its
# label's row.
SYSTEM_GUTTER = 260.0
CHART_LABEL_SHARE = 0.4
CHART_LABEL_GAP = 8.0
CHART_BAR_SHARE = 0.42
CHART_ROW_MIN = 28.0


def chars_per_line(width, size, advance_em):
    """How many characters of the resolved face's documented advance fit one line of `width` px."""
    return max(1, int(width // (size * advance_em)))


def estimate_lines(text, width, size, advance_em):
    """Deterministic line estimate for one string set at `size` px in `width` px with the resolved
    face's documented advance. Never truncates: long content simply needs more lines. This is the
    character estimate for text the page flows itself (Layout.text_block): each paragraph counts
    ceil(characters / chars_per_line) lines. A figure label, which SVG cannot wrap, is estimated by
    estimate_label_lines instead, so figure labels and flowing text are estimated differently."""
    per_line = chars_per_line(width, size, advance_em)
    return sum(max(1, math.ceil(len(paragraph) / per_line)) for paragraph in str(text).split("\n"))


# The no-break spaces. str.isspace() counts them as whitespace, but a figure label never breaks at
# one, so a number and its unit, or a French guillemet and its word, joined by one stay on one line.
NO_BREAK_SPACES = "\u00a0\u2007\u202f"


def is_break_space(char):
    """Whether a figure label may break at `char`: any whitespace except a no-break space."""
    return char.isspace() and char not in NO_BREAK_SPACES


def label_tokens(paragraph):
    """One paragraph as (word, space) pairs that join back to it exactly: each word is a maximal run
    of characters that are not break spaces, and its space is the run of break spaces after it.
    Whitespace at the start of the paragraph is a pair with an empty word."""
    tokens, at = [], 0
    while at < len(paragraph):
        end = at
        while end < len(paragraph) and not is_break_space(paragraph[end]):
            end += 1
        stop = end
        while stop < len(paragraph) and is_break_space(paragraph[stop]):
            stop += 1
        tokens.append((paragraph[at:end], paragraph[end:stop]))
        at = stop
    return tokens


def wrap_lines(text, width, size, advance_em):
    """A figure label's display lines, as slices of `text`. Each paragraph is filled word by word and
    breaks before the first word that would not fit in chars_per_line characters. The break spaces a
    line ends with stay at the end of that line and do not count toward its fit, so a continuation line
    never starts indented; spaces inside a line count. Only a word longer than chars_per_line is cut:
    it starts a fresh line, fills whole lines, and its last piece may be followed by further words. The
    newline that ends a paragraph stays at the end of its last line, and every paragraph gives at least
    one line. Lossless by construction — the lines join to `text` exactly — and there are always
    exactly estimate_label_lines(text, width, size, advance_em) of them."""
    per_line = chars_per_line(width, size, advance_em)
    paragraphs = str(text).split("\n")
    lines = []
    for index, paragraph in enumerate(paragraphs):
        chunks, current = [], ""
        for word, space in label_tokens(paragraph):
            if current and len(current) + len(word) > per_line:
                chunks.append(current)
                current = ""
            while len(word) > per_line:
                chunks.append(word[:per_line])
                word = word[per_line:]
            current += word + space
        chunks.append(current)
        if index < len(paragraphs) - 1:
            chunks[-1] += "\n"
        lines.extend(chunks)
    return lines


def place_word(lines, used, word, per_line):
    """The line count and the current line's length after a word of `word` characters is placed on a
    line already holding `used`, by the rule wrap_lines applies."""
    if used and used + word > per_line:
        lines, used = lines + 1, 0
    if word > per_line:
        cut = (word - 1) // per_line
        return lines + cut, word - cut * per_line
    return lines, used + word


def estimate_label_lines(text, width, size, advance_em):
    """The figure-label line estimate: how many lines wrap_lines gives `text`. It walks the characters
    and keeps only lengths — it builds no line and never calls wrap_lines — so the plan's count and the
    drawn split are two computations of one rule that the suite checks against each other."""
    per_line = chars_per_line(width, size, advance_em)
    total = 0
    for paragraph in str(text).split("\n"):
        lines, used, word = 1, 0, 0
        for char in paragraph:
            if not is_break_space(char):
                word += 1
                continue
            if word:
                lines, used = place_word(lines, used, word, per_line)
                word = 0
            used += 1
        if word:
            lines, used = place_word(lines, used, word, per_line)
        total += lines
    return total


# --- runtime pin and provenance ---------------------------------------------------------------------

def runtime_pin():
    """The committed pin: the runtime manifest's exact dependency versions and the lockfile digest."""
    manifest = json.loads((RUNTIME_DIR / "package.json").read_text(encoding="utf-8"))
    return {"name": manifest.get("name"), "dependencies": dict(manifest.get("dependencies", {})),
            "lock": "runtime/package-lock.json", "lock_sha256": sha256_file(RUNTIME_DIR / "package-lock.json")}
