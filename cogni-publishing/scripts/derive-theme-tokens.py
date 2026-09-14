#!/usr/bin/env python3
"""derive-theme-tokens.py — Derive a tier-0 theme's tokens/*.json from its theme.md.

Stdlib only, plus the sibling token compiler. A tier-0 theme keeps its design
variables as ``theme.md`` prose; design-render reads only the authoritative
``tokens/*.json``. This script is the theme-lifecycle bridge between the two: it
reads ``theme.md`` section by section and writes ``tokens/colors.json``,
``tokens/typography.json`` and ``tokens/spacing.json``, then ``tokens.css`` as the
compiler's own projection of them. It never supplies a value the file does not
state: every derived token is a literal copied verbatim from its row, and a role
the file lacks stays absent, so the renderer names it instead of rendering around
it.

Sections read, each by its exact heading and never across one:

* ``## Color Palette`` (with its ``###`` subsections) — ``- **Label**: `<hex>` ...``
  rows become ``colors`` keys, lower-kebab except where COLOR_KEYS renames them;
* ``## Typography`` rows before its first ``###`` — ``- **Body**: Family /
  fallback: A, B, generic`` become ``typography.font-*`` stacks (FONT_KEYS);
* ``### Type Scale`` under ``## Typography`` — ``- **H2**: 30px / 1.2 / 600 /
  -0.01em`` rows become ``size-``, ``line-height-`` and, when the row states one,
  ``tracking-`` keys (TYPE_KEYS renames a role);
* ``## Spacing Scale`` — ``- **4**: 16px`` rows become ``spacing`` keys.

Fenced code blocks are skipped. A malformed or repeated row inside a read section
is a rejection naming it, and nothing is written. The derived maps pass through
the compiler's ``compile_maps`` before any write, and ``tokens.css`` is its
``render_css`` output, so this script serializes no CSS of its own.

A target that already holds any canonical ``<stem>.json`` is left untouched unless
``--overwrite`` is given: a theme's existing tokens may be authoritative in their
own right (an imported design system), never something to regenerate from prose.

Usage:
    python3 derive-theme-tokens.py <theme-dir> [--tokens-dir <dir>] [--overwrite]

Emits one ``{"success", "data", "error"}`` envelope on stdout and nothing on
stderr. Exit 0 written, 1 a rejection (``data`` is the finding), 2 a usage or
runtime error.
"""

import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path

SCRIPTS = Path(__file__).absolute().parent

PALETTE = "## Color Palette"
TYPOGRAPHY = "## Typography"
TYPE_SCALE = "### Type Scale"
SPACING = "## Spacing Scale"

# Labels whose token key is not their lower-kebab form: the renderer reads the
# page ground as colors.bg, the copy font as typography.font-sans, and the
# reference theme names its eyebrow role micro.
COLOR_KEYS = {"Background": "bg"}
FONT_KEYS = {"Headers": "font-heading", "Body": "font-sans", "Mono": "font-mono"}
TYPE_KEYS = {"Eyebrow / Micro": "micro"}

# CSS generic family keywords stay unquoted in a derived stack.
GENERIC_FAMILIES = frozenset((
    "serif", "sans-serif", "monospace", "cursive", "fantasy", "system-ui", "math", "emoji",
    "fangsong", "ui-serif", "ui-sans-serif", "ui-monospace", "ui-rounded",
))

ROW = re.compile(r"^- \*\*(?P<label>[^*]+)\*\*:\s*(?P<value>.*)$")
HEX_VALUE = re.compile(r"^`(#[0-9A-Fa-f]{6})`")
PX = re.compile(r"^[0-9]+(?:\.[0-9]+)?px$")
RATIO = re.compile(r"^[0-9]+(?:\.[0-9]+)?$")
TRACKING = re.compile(r"^-?[0-9]+(?:\.[0-9]+)?(?:em)?$")
SPACING_VALUE = re.compile(r"^(?:0|[0-9]+(?:\.[0-9]+)?px)$")
FALLBACK = re.compile(r"^(?P<first>.+?)\s*/\s*fallback:\s*(?P<rest>.+)$")
UNSAFE_FAMILY = re.compile(r"['\"\\;{}<>]")
DESCRIPTION = re.compile(r"\s+[—-]\s+")


def load_compiler():
    spec = importlib.util.spec_from_file_location("cogni_publishing_tokens", SCRIPTS / "generate-tokens-css.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


compiler = load_compiler()


class DeriveError(Exception):
    """A rejection or a usage/runtime error; `status` is the exit code."""

    def __init__(self, code, message, reference=None, status=1):
        super().__init__(message)
        self.status = status
        self.finding = {"code": code, "reference": reference}


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise DeriveError("usage-error", message, status=2)


def kebab(label):
    return re.sub(r"[^a-z0-9]+", "-", label.strip().lower()).strip("-")


def without_description(value):
    """A row's value up to its trailing ' — description', if it has one."""
    return DESCRIPTION.split(value.strip(), maxsplit=1)[0].strip()


def rows(text):
    """Every `- **Label**: value` row outside a fence, with the headings it sits under."""
    h2 = h3 = None
    fenced = False
    for number, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            fenced = not fenced
            continue
        if fenced:
            continue
        if line.startswith("# "):
            h2 = h3 = None
        elif line.startswith("## "):
            h2, h3 = stripped, None
        elif line.startswith("### "):
            h3 = stripped
        else:
            match = ROW.match(line)
            if match:
                yield number, h2, h3, match.group("label").strip(), match.group("value")


def reference(section, label, number):
    return f"{section} / {label} (line {number})"


def malformed(section, label, number, why):
    return DeriveError("malformed-row", f"theme.md line {number}: the {section} row {label!r} {why}",
                       reference(section, label, number))


def put(stem_map, key, value, section, label, number):
    if key in stem_map:
        raise DeriveError("duplicate-row", f"theme.md line {number}: the {section} row {label!r} repeats the "
                          f"token {key!r}", reference(section, label, number))
    stem_map[key] = value


def font_stack(value, section, label, number):
    value = without_description(value)
    match = FALLBACK.match(value)
    families = [match.group("first")] + match.group("rest").split(",") if match else value.split(",")
    families = [family.strip() for family in families]
    if not all(families):
        raise malformed(section, label, number, "names an empty font family")
    for family in families:
        if UNSAFE_FAMILY.search(family):
            raise malformed(section, label, number, f"names the family {family!r}, which a CSS stack cannot quote")
    return ", ".join(family if family.lower() in GENERIC_FAMILIES else f"'{family}'" for family in families)


def derive(text):
    """{stem: {key: literal}} for the three derived stems, plus the sections that yielded nothing."""
    colors, typography, spacing = {}, {}, {}
    for number, h2, h3, label, value in rows(text):
        if h2 == PALETTE:
            section = h3 or PALETTE
            match = HEX_VALUE.match(value.strip())
            if not match:
                raise malformed(section, label, number, "carries no backticked six-digit hex colour")
            put(colors, COLOR_KEYS.get(label, kebab(label)), match.group(1), section, label, number)
        elif h2 == TYPOGRAPHY and h3 is None:
            if label not in FONT_KEYS:
                raise DeriveError("unmapped-font", f"theme.md line {number}: the {TYPOGRAPHY} row {label!r} is not "
                                  f"one of {', '.join(FONT_KEYS)}, so it has no token role",
                                  reference(TYPOGRAPHY, label, number))
            put(typography, FONT_KEYS[label], font_stack(value, TYPOGRAPHY, label, number), TYPOGRAPHY, label,
                number)
        elif h2 == TYPOGRAPHY and h3 == TYPE_SCALE:
            parts = [part.strip() for part in without_description(value).split("/")]
            if len(parts) < 2 or not PX.match(parts[0]) or not RATIO.match(parts[1]):
                raise malformed(TYPE_SCALE, label, number, "does not start with '<size>px / <line-height ratio>'")
            role = TYPE_KEYS.get(label, kebab(label))
            put(typography, f"size-{role}", parts[0], TYPE_SCALE, label, number)
            put(typography, f"line-height-{role}", parts[1], TYPE_SCALE, label, number)
            if len(parts) > 3:
                if not TRACKING.match(parts[3]):
                    raise malformed(TYPE_SCALE, label, number, f"has {parts[3]!r} where the tracking belongs")
                put(typography, f"tracking-{role}", parts[3], TYPE_SCALE, label, number)
        elif h2 == SPACING:
            step = without_description(value)
            if not SPACING_VALUE.match(step):
                raise malformed(SPACING, label, number, f"has {step!r}, which is neither 0 nor a px length")
            put(spacing, kebab(label), step, SPACING, label, number)
    derived = {"colors": colors, "typography": typography, "spacing": spacing}
    missing = [stem for stem, values in derived.items() if not values]
    return {stem: values for stem, values in derived.items() if values}, missing


def run(argv):
    parser = Parser(prog="derive-theme-tokens.py", description="Derive a tier-0 theme's tokens/*.json from theme.md.")
    parser.add_argument("theme_dir", help="theme directory holding theme.md")
    parser.add_argument("--tokens-dir", help="where to write the tokens (default: <theme-dir>/tokens)")
    parser.add_argument("--overwrite", action="store_true",
                        help="replace canonical token files the target already holds")
    args = parser.parse_args(argv)

    theme_dir = Path(args.theme_dir)
    theme_md = theme_dir / "theme.md"
    target = Path(args.tokens_dir) if args.tokens_dir else theme_dir / "tokens"
    # Checked before theme.md is even read, so existing tokens are never at the mercy of how the prose parses.
    existing = [stem for stem in compiler.CANONICAL_FILES if (target / f"{stem}.json").exists()]
    if existing and not args.overwrite:
        held = ", ".join(stem + ".json" for stem in existing)
        raise DeriveError("tokens-exist", f"{target} already holds {held}; they may be authoritative, so nothing "
                          "was written — pass --overwrite to replace them", str(target))
    try:
        text = theme_md.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise DeriveError("theme-md", f"cannot read {theme_md}: {exc}", str(theme_md), status=2) from exc
    derived, missing = derive(text)
    if not derived:
        raise DeriveError("nothing-derived", f"{theme_md} has none of the {PALETTE}, {TYPOGRAPHY} or {SPACING} rows "
                          "a token is derived from", str(theme_md))

    try:
        maps = compiler.load_maps(target) if existing else {}
    except (OSError, ValueError) as exc:
        raise DeriveError("tokens-unreadable", f"cannot read the tokens in {target}: {exc}", str(target),
                          status=2) from exc
    maps.update(derived)
    try:
        compiled = compiler.compile_maps(maps)
    except compiler.TokenError as exc:
        raise DeriveError(exc.code, str(exc), exc.token) from exc

    written = []
    try:
        target.mkdir(parents=True, exist_ok=True)
        for stem in compiler.CANONICAL_FILES:
            if stem in derived:
                path = target / f"{stem}.json"
                path.write_text(json.dumps(derived[stem], indent=2, ensure_ascii=False, sort_keys=True) + "\n",
                                encoding="utf-8")
                written.append(path.name)
        (target / "tokens.css").write_text(compiler.render_css(compiled), encoding="utf-8")
        written.append("tokens.css")
        resolved = target / compiler.RESOLVED_FILENAME
        if compiled.aliases() or resolved.exists():
            resolved.write_text(compiler.resolved_text(compiled), encoding="utf-8")
            written.append(resolved.name)
    except OSError as exc:
        raise DeriveError("write-failed", f"cannot write the tokens in {target}: {exc}", str(target),
                          status=2) from exc
    return {"theme": theme_dir.absolute().name, "theme_md": str(theme_md), "tokens_dir": str(target),
            "written": written, "tokens": {stem: len(values) for stem, values in derived.items()},
            "sections_missing": missing, "overwrote": bool(existing), "skipped": compiled.skipped}


def main(argv=None):
    try:
        data, error, status = run(sys.argv[1:] if argv is None else argv), None, 0
    except DeriveError as exc:
        data, error, status = exc.finding, str(exc), exc.status
    print(json.dumps({"success": status == 0, "data": data, "error": error}, ensure_ascii=False))
    return status


if __name__ == "__main__":
    sys.exit(main())
