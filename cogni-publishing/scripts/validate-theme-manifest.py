#!/usr/bin/env python3
"""validate-theme-manifest.py — Validate a theme directory against Theme System v2.

Stdlib-only. Tier-0 themes (no manifest.json) are valid as a no-op so existing
``themes/cogni-work/`` and ``themes/_template/`` continue to validate. Tiered
themes must conform to ``references/theme-manifest.schema.json``, declare
on-disk paths that exist, and stay free of the reserved keys ``live``,
``live_within_session``, and ``copy`` at any nesting depth.

The validator inlines a minimal draft-07 implementation covering the subset
the schema actually uses (``type``, ``required``, ``properties``,
``additionalProperties: false``, ``patternProperties``, ``pattern``,
``const``, ``minLength``, and ``not.anyOf`` with ``required``). When a
tokens tier is declared, the token graph must compile under
``generate-tokens-css.py`` — an alias cycle, an unresolved reference or an
unsupported construct is a hard failure whose finding becomes the envelope's
``data``. When ``tokens.css`` or ``tokens.resolved.json`` is present, the
regenerated projection must match it (after stripping); a drift is a hard
failure.

Usage:
    python3 validate-theme-manifest.py <theme-dir>
"""

import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path


RESERVED_KEYS = {"live", "live_within_session", "copy"}


# ---------------------------------------------------------------------------
# Output envelope
# ---------------------------------------------------------------------------


def emit(success: bool, data=None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


# ---------------------------------------------------------------------------
# Inline draft-07 validator (subset)
# ---------------------------------------------------------------------------


class ValidationError(Exception):
    """A rejected theme. ``finding`` is the machine-readable cause, when one exists."""

    def __init__(self, message, finding=None):
        super().__init__(message)
        self.finding = finding or {}


_PY_TYPES = {
    "string": str,
    "integer": int,
    "number": (int, float),
    "boolean": bool,
    "object": dict,
    "array": list,
    "null": type(None),
}


def _at(path: str) -> str:
    return path or "/"


def validate(instance, schema, path: str = "") -> None:
    """Validate ``instance`` against draft-07 ``schema``. Raises on first failure."""
    if "type" in schema:
        t = schema["type"]
        expected = _PY_TYPES.get(t)
        if expected is None:
            raise ValidationError("unknown schema type {!r} at {}".format(t, _at(path)))
        # JSON booleans are also ints in Python — guard the integer/number cases.
        if t in ("integer", "number") and isinstance(instance, bool):
            raise ValidationError(
                "expected {!r} at {}, got boolean".format(t, _at(path))
            )
        if not isinstance(instance, expected):
            raise ValidationError(
                "expected {!r} at {}, got {}".format(
                    t, _at(path), type(instance).__name__
                )
            )

    if "const" in schema and instance != schema["const"]:
        raise ValidationError(
            "value at {} must equal {!r}, got {!r}".format(
                _at(path), schema["const"], instance
            )
        )

    if isinstance(instance, str):
        if "minLength" in schema and len(instance) < schema["minLength"]:
            raise ValidationError(
                "string at {} shorter than minLength {}".format(
                    _at(path), schema["minLength"]
                )
            )
        if "pattern" in schema and not re.search(schema["pattern"], instance):
            raise ValidationError(
                "string {!r} at {} does not match pattern {!r}".format(
                    instance, _at(path), schema["pattern"]
                )
            )

    if isinstance(instance, dict):
        for req in schema.get("required", []):
            if req not in instance:
                raise ValidationError(
                    "missing required key {!r} at {}".format(req, _at(path))
                )

        props = schema.get("properties", {})
        pattern_props = schema.get("patternProperties", {})
        addl = schema.get("additionalProperties", True)

        for key, value in instance.items():
            child_path = "{}/{}".format(path, key)
            if key in props:
                validate(value, props[key], child_path)
                continue
            matched = False
            for pat, sub in pattern_props.items():
                if re.search(pat, key):
                    validate(value, sub, child_path)
                    matched = True
                    break
            if matched:
                continue
            if addl is False:
                raise ValidationError(
                    "additional property {!r} not allowed at {}".format(
                        key, _at(path)
                    )
                )

    if "not" in schema:
        try:
            validate(instance, schema["not"], path)
        except ValidationError:
            pass
        else:
            raise ValidationError(
                "value at {} matched a forbidden 'not' schema".format(_at(path))
            )

    if "anyOf" in schema:
        for sub in schema["anyOf"]:
            try:
                validate(instance, sub, path)
                break
            except ValidationError:
                continue
        else:
            raise ValidationError(
                "value at {} did not match any of 'anyOf'".format(_at(path))
            )


# ---------------------------------------------------------------------------
# Theme-specific checks
# ---------------------------------------------------------------------------


def check_reserved_keys(node, path: str = "") -> None:
    """Recursively reject reserved keys at any depth.

    JSON Schema's ``not.anyOf`` only catches root-level occurrences. Nested
    cases like ``{"tiers": {"components": {"web": {"live": true}}}}`` slip
    past it; this scan closes that gap.
    """
    if isinstance(node, dict):
        for key, value in node.items():
            if key in RESERVED_KEYS:
                raise ValidationError(
                    "reserved key {!r} at {}/{} — forbidden in schema v1.0; "
                    "reserved for Phase 3".format(key, path, key)
                )
            check_reserved_keys(value, "{}/{}".format(path, key))
    elif isinstance(node, list):
        for i, item in enumerate(node):
            check_reserved_keys(item, "{}[{}]".format(path, i))


def check_paths_exist(theme_dir: Path, manifest: dict) -> None:
    """Verify every on-disk path declared in the manifest exists."""
    tiers = manifest.get("tiers", {})
    for tier_name in ("tokens", "assets"):
        if tier_name in tiers:
            p = (theme_dir / tiers[tier_name]).resolve()
            if not p.exists():
                raise ValidationError(
                    "tiers.{} path {!r} does not exist (resolved to {})".format(
                        tier_name, tiers[tier_name], p
                    )
                )
    for group in ("components", "templates"):
        for name, subpath in tiers.get(group, {}).items():
            p = (theme_dir / subpath).resolve()
            if not p.exists():
                raise ValidationError(
                    "tiers.{}.{} path {!r} does not exist (resolved to {})".format(
                        group, name, subpath, p
                    )
                )
    if "showcase" in manifest:
        p = (theme_dir / manifest["showcase"]).resolve()
        if not p.exists():
            raise ValidationError(
                "showcase path {!r} does not exist (resolved to {})".format(
                    manifest["showcase"], p
                )
            )
    # voice_ref is an in-document anchor (e.g. '#voice--copy-guidelines'); skip path check.


def _load_token_generator():
    """Dynamically load the sibling generator script (its filename uses hyphens)."""
    here = Path(__file__).resolve().parent
    spec = importlib.util.spec_from_file_location(
        "_token_gen", here / "generate-tokens-css.py"
    )
    if spec is None or spec.loader is None:
        raise ValidationError("cannot locate generate-tokens-css.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def check_tokens(theme_dir: Path, manifest: dict) -> list:
    """Compile the declared tokens tier and compare its generated projections.

    The compile runs whenever a tokens tier is declared, so a graph the compiler
    refuses fails validation even before any projection has been written.
    ``tokens.css`` and ``tokens.resolved.json`` are each compared only when
    present: a theme that ships JSON without its projections is allowed (the
    build step writes them). Returns the compiler's skipped-shape report.
    """
    tokens_subpath = manifest.get("tiers", {}).get("tokens")
    if not tokens_subpath:
        return []
    tokens_dir = (theme_dir / tokens_subpath).resolve()
    gen = _load_token_generator()
    try:
        compiled = gen.compile_dir(tokens_dir)
    except gen.TokenError as e:
        raise ValidationError(str(e), finding=e.finding())
    except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
        raise ValidationError("token compilation failed: {}".format(e))

    css_file = tokens_dir / "tokens.css"
    if css_file.exists():
        expected = gen.render_css(compiled)
        if expected.strip() != css_file.read_text(encoding="utf-8").strip():
            raise ValidationError(
                "tokens.css drift: regenerated output differs from {}. "
                "Run 'generate-tokens-css.py --write' to refresh.".format(css_file),
                finding={"code": "projection-drift", "token": None, "reference": "tokens.css"},
            )
    resolved_file = tokens_dir / gen.RESOLVED_FILENAME
    if resolved_file.exists():
        expected = gen.resolved_text(compiled)
        if expected.strip() != resolved_file.read_text(encoding="utf-8").strip():
            raise ValidationError(
                "{} drift: regenerated output differs from {}. "
                "Run 'generate-tokens-css.py --write' to refresh.".format(
                    gen.RESOLVED_FILENAME, resolved_file),
                finding={"code": "projection-drift", "token": None,
                         "reference": gen.RESOLVED_FILENAME},
            )
    return compiled.skipped


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def find_schema() -> Path:
    here = Path(__file__).resolve().parent
    return here.parent / "references" / "theme-manifest.schema.json"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate a theme directory against Theme System v2."
    )
    parser.add_argument("theme_dir", help="Path to the theme directory")
    args = parser.parse_args()

    theme_dir = Path(args.theme_dir).resolve()
    if not theme_dir.is_dir():
        return emit(False, error="theme directory not found: {}".format(theme_dir))

    manifest_file = theme_dir / "manifest.json"
    if not manifest_file.exists():
        return emit(
            True,
            data={
                "tier": 0,
                "theme_dir": str(theme_dir),
                "note": "no manifest.json — tier-0 theme is valid",
            },
        )

    try:
        with manifest_file.open("r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        return emit(False, error="cannot read manifest.json: {}".format(e))

    schema_file = find_schema()
    if not schema_file.exists():
        return emit(False, error="schema not found at {}".format(schema_file))
    try:
        with schema_file.open("r", encoding="utf-8") as f:
            schema = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        return emit(False, error="cannot read schema: {}".format(e))

    try:
        validate(manifest, schema)
        check_reserved_keys(manifest)
        check_paths_exist(theme_dir, manifest)
        skipped = check_tokens(theme_dir, manifest)
    except ValidationError as e:
        return emit(False, data=e.finding, error=str(e))

    data = {
        "tier": "tiered",
        "theme_dir": str(theme_dir),
        "name": manifest.get("name"),
        "slug": manifest.get("slug"),
        "tiers_present": sorted(manifest.get("tiers", {}).keys()),
    }
    if skipped:
        data["tokens_skipped"] = skipped
    return emit(True, data=data)


if __name__ == "__main__":
    sys.exit(main())
