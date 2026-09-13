#!/usr/bin/env python3
"""generate-tokens-css.py — Compile a theme's canonical tokens/*.json files.

Stdlib-only. The token JSON files are the ONE authoritative representation of a
theme's design variables; everything else is a generated projection of them:

* ``tokens.css`` — one ``:root`` block of CSS custom properties, each prefixed
  with its file stem. A semantic alias stays an alias here:
  ``--semantic-fg: var(--colors-ink);`` keeps the role-to-role reference, so a
  browser resolves the chain and the role identity is visible in the output.
* ``tokens.resolved.json`` / ``--format resolved-json`` — every token resolved
  to its literal value plus the alias map, for consumers that cannot evaluate
  ``var()`` (a PPTX renderer, a colour audit).

Output is deterministic: canonical file order below, alphabetical key order
within each block. A theme whose token files hold only primitive values
compiles byte-identically to the flat-map generator this compiler replaces —
the header line and the block layout are part of that contract, because every
saved ``tokens.css`` is parity-checked against this output.

The accepted input shapes are the bounded DTCG subset documented in
``references/token-subset.md``; it is not full DTCG support. Importable API:

* ``generate(tokens_dir) -> str``         CSS; raises ``TokenError``
* ``resolve(tokens_dir) -> dict``         resolved projection; raises ``TokenError``
* ``compile_maps(maps) -> Compiled``      the same over in-memory ``{stem: {key: value}}``

Usage:
    python3 generate-tokens-css.py --tokens-dir <dir>                        # CSS to stdout
    python3 generate-tokens-css.py --tokens-dir <dir> --format resolved-json # envelope
    python3 generate-tokens-css.py --tokens-dir <dir> --write                # write projections

Exit 0 on success, 1 on a token-graph rejection or a missing directory (the
envelope's ``data`` then carries only the finding), 2 on a usage error.
"""

import argparse
import json
import re
import sys
from pathlib import Path


# Order is load-bearing: the six primitive stems come first, exactly as the
# flat-map generator emitted them, so a theme without semantic.json compiles to
# the same bytes it always did.
CANONICAL_FILES = ("colors", "typography", "spacing", "radii", "shadows", "motion", "semantic")

# DTCG `$type` values accepted on a token object. The type is informational —
# the compiler does not re-validate the value's syntax against it — and composite
# DTCG types (shadow, typography, border, transition, gradient, strokeStyle,
# cubicBezier as an array) are outside the subset. references/token-subset.md
# lists the same set; the semantic-tokens suite pins the two against each other.
SUPPORTED_TYPES = ("color", "dimension", "fontFamily", "fontWeight", "duration", "number")

# Members of a token object, or of a token file's root, that carry no value and
# are ignored rather than rejected.
IGNORED_MEMBERS = ("$description", "$extensions", "$deprecated")

HEADER = "/* Generated from tokens/*.json by generate-tokens-css.py — do not edit by hand. */\n"
RESOLVED_FILENAME = "tokens.resolved.json"
RESOLVED_SCHEMA = "tokens-resolved@1"

_ALIAS = re.compile(r"^\{([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+)\}$")


class TokenError(Exception):
    """A token graph the compiler refuses. Carries a machine-readable finding."""

    def __init__(self, code, token, reference, message):
        super().__init__(message)
        self.code = code
        self.token = token
        self.reference = reference

    def finding(self) -> dict:
        return {"code": self.code, "token": self.token, "reference": self.reference}


class Compiled:
    """Result of one compilation: ordered entries plus what was skipped."""

    def __init__(self, entries, blocks, skipped):
        self.entries = entries   # {(stem, key): ("literal", v) | ("alias", (stem, key))}
        self.blocks = blocks     # stems that exist as JSON objects, in canonical order
        self.skipped = skipped   # [{"token", "reason"}] — legacy shapes, reported not failed

    def aliases(self) -> dict:
        return {
            "{}.{}".format(s, k): "{}.{}".format(*v[1])
            for (s, k), v in sorted(self.entries.items())
            if v[0] == "alias"
        }


def _is_primitive(value) -> bool:
    return isinstance(value, (str, int, float)) and not isinstance(value, bool)


def _parse_value(stem, key, value):
    """Classify one primitive value as a literal or an alias reference."""
    token = "{}.{}".format(stem, key)
    if isinstance(value, str) and value.startswith("{") and value.endswith("}"):
        m = _ALIAS.match(value)
        if not m:
            raise TokenError(
                "malformed-alias", token, value,
                "token {} has a malformed alias {!r}; an alias is exactly "
                "'{{<stem>.<key>}}'".format(token, value),
            )
        ref_stem, ref_key = m.group(1), m.group(2)
        if ref_stem not in CANONICAL_FILES:
            raise TokenError(
                "unsupported-construct", token, value,
                "token {} aliases {!r}, but '{}' is not a canonical token file "
                "({})".format(token, value, ref_stem, ", ".join(CANONICAL_FILES)),
            )
        return ("alias", (ref_stem, ref_key))
    return ("literal", value)


def _parse_token_object(stem, key, obj):
    """Parse a DTCG token object — a dict carrying ``$value``."""
    token = "{}.{}".format(stem, key)
    for member in obj:
        if member != "$value" and member != "$type" and member not in IGNORED_MEMBERS:
            raise TokenError(
                "unsupported-construct", token, member,
                "token {} carries {!r}; a token object supports only $value, $type "
                "and the ignored {}".format(token, member, ", ".join(IGNORED_MEMBERS)),
            )
    if "$type" in obj and obj["$type"] not in SUPPORTED_TYPES:
        raise TokenError(
            "unsupported-construct", token, str(obj["$type"]),
            "token {} declares $type {!r}, which is outside the supported subset "
            "({})".format(token, obj["$type"], ", ".join(SUPPORTED_TYPES)),
        )
    value = obj["$value"]
    if not _is_primitive(value):
        raise TokenError(
            "unsupported-construct", token, "$value",
            "token {} has a composite $value ({}); only a string or number, or an "
            "alias to one, is supported".format(token, type(value).__name__),
        )
    return _parse_value(stem, key, value)


def compile_maps(maps) -> Compiled:
    """Compile ``{stem: parsed-json}`` into ordered entries, then check the graph.

    Stems absent from ``maps`` are skipped silently, as missing files always
    were. Raises ``TokenError`` on the first rejection, in canonical-stem then
    key order, so the reported finding is deterministic.
    """
    entries, blocks, skipped = {}, [], []
    for stem in CANONICAL_FILES:
        if stem not in maps:
            continue
        data = maps[stem]
        if not isinstance(data, dict):
            skipped.append({"token": stem, "reason": "file is not a JSON object"})
            continue
        blocks.append(stem)
        for key in sorted(data.keys()):
            value = data[key]
            token = "{}.{}".format(stem, key)
            if key.startswith("$"):
                if key in IGNORED_MEMBERS:
                    continue
                raise TokenError(
                    "unsupported-construct", stem, key,
                    "tokens/{}.json carries a root-level {!r}; group-level members "
                    "such as $type inheritance are outside the supported subset".format(stem, key),
                )
            if _is_primitive(value):
                entries[(stem, key)] = _parse_value(stem, key, value)
            elif isinstance(value, dict) and "$value" in value:
                entries[(stem, key)] = _parse_token_object(stem, key, value)
            elif isinstance(value, dict) and any(m.startswith("$") for m in value):
                raise TokenError(
                    "unsupported-construct", token, "group",
                    "token {} is a DTCG group (it has $-members but no $value); nested "
                    "groups are outside the supported subset".format(token),
                )
            else:
                # A plain nested object, a boolean, a null or an array. The flat
                # generator skipped these silently; they stay skipped so existing
                # themes need no upgrade, but they are now reported.
                skipped.append({"token": token, "reason": "{} is not a token value".format(
                    "null" if value is None else type(value).__name__)})

    compiled = Compiled(entries, blocks, skipped)
    for (stem, key) in sorted(entries):
        _resolve_one(compiled, (stem, key))
    return compiled


def _resolve_one(compiled, start):
    """Follow one alias chain to its literal. Raises on a cycle or a dangling ref."""
    seen = [start]
    current = start
    while True:
        kind, payload = compiled.entries[current]
        if kind == "literal":
            return payload
        target = payload
        token = "{}.{}".format(*current)
        ref = "{}.{}".format(*target)
        if target not in compiled.entries:
            raise TokenError(
                "unresolved-reference", token, ref,
                "token {} aliases {{{}}}, which no token file defines".format(token, ref),
            )
        if target in seen:
            chain = " -> ".join("{}.{}".format(*t) for t in seen + [target])
            raise TokenError(
                "alias-cycle", token, ref,
                "alias cycle: {}".format(chain),
            )
        seen.append(target)
        current = target


def _var_name(stem, key) -> str:
    # Underscores become hyphens before composition, avoiding a double-dash
    # artefact (--colors--focus) when a JSON key starts with an underscore.
    return "--{}-{}".format(stem, key.replace("_", "-").lstrip("-"))


def render_css(compiled) -> str:
    body = []
    for stem in compiled.blocks:
        body.append("  /* {} */".format(stem))
        for (s, key) in sorted(k for k in compiled.entries if k[0] == stem):
            kind, payload = compiled.entries[(s, key)]
            value = payload if kind == "literal" else "var({})".format(_var_name(*payload))
            body.append("  {}: {};".format(_var_name(s, key), value))
    if body:
        return HEADER + ":root {\n" + "\n".join(body) + "\n}\n"
    return HEADER + ":root {\n}\n"


def render_resolved(compiled) -> dict:
    tokens = {}
    for (stem, key) in sorted(compiled.entries):
        tokens.setdefault(stem, {})[key] = _resolve_one(compiled, (stem, key))
    return {"schema": RESOLVED_SCHEMA, "tokens": tokens, "aliases": compiled.aliases()}


def resolved_text(compiled) -> str:
    return json.dumps(render_resolved(compiled), indent=2, ensure_ascii=False, sort_keys=True) + "\n"


def load_maps(tokens_dir) -> dict:
    tokens_dir = Path(tokens_dir)
    if not tokens_dir.is_dir():
        raise FileNotFoundError("tokens directory not found: {}".format(tokens_dir))
    maps = {}
    for stem in CANONICAL_FILES:
        f = tokens_dir / (stem + ".json")
        if f.exists():
            with f.open("r", encoding="utf-8") as h:
                maps[stem] = json.load(h)
    return maps


def compile_dir(tokens_dir) -> Compiled:
    return compile_maps(load_maps(tokens_dir))


def generate(tokens_dir) -> str:
    """Return the canonical CSS for a tokens directory. Raises ``TokenError``."""
    return render_css(compile_dir(tokens_dir))


def resolve(tokens_dir) -> dict:
    """Return the resolved projection for a tokens directory. Raises ``TokenError``."""
    return render_resolved(compile_dir(tokens_dir))


def _emit(success, data=None, error=""):
    print(json.dumps({"success": success, "data": data or {}, "error": error}, ensure_ascii=False))
    return 0 if success else 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compile a theme's canonical tokens/*.json into its generated projections."
    )
    parser.add_argument("--tokens-dir", required=True,
                        help="Path to the tokens/ directory inside a theme.")
    parser.add_argument("--format", choices=("css", "resolved-json"), default="css",
                        help="css (default) prints tokens.css; resolved-json prints the "
                             "resolved projection inside the standard envelope.")
    parser.add_argument("--write", action="store_true",
                        help="Write tokens.css (and tokens.resolved.json when the theme has an "
                             "alias or already ships that file) into <tokens-dir>.")
    args = parser.parse_args()

    try:
        compiled = compile_dir(args.tokens_dir)
    except TokenError as e:
        return _emit(False, data=e.finding(), error=str(e))
    except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
        return _emit(False, error=str(e))

    if args.write:
        out = Path(args.tokens_dir) / "tokens.css"
        css = render_css(compiled)
        data = {"path": str(out), "bytes": len(css)}
        resolved_out = Path(args.tokens_dir) / RESOLVED_FILENAME
        try:
            out.write_text(css, encoding="utf-8")
            if compiled.aliases() or resolved_out.exists():
                resolved_out.write_text(resolved_text(compiled), encoding="utf-8")
                data["resolved_path"] = str(resolved_out)
        except OSError as e:
            return _emit(False, error=str(e))
        if compiled.skipped:
            data["skipped"] = compiled.skipped
        return _emit(True, data=data)

    if args.format == "resolved-json":
        data = render_resolved(compiled)
        data["skipped"] = compiled.skipped
        return _emit(True, data=data)

    sys.stdout.write(render_css(compiled))
    return 0


if __name__ == "__main__":
    sys.exit(main())
