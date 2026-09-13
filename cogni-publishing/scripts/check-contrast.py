#!/usr/bin/env python3
"""check-contrast.py — WCAG 2.1 contrast ratios for a theme palette.

Stdlib-only. Reads a flat ``{"role": "#rrggbb"}`` JSON map and reports the
contrast ratio of every foreground/background pair, each with its AA verdict.
The map is deliberately palette-shape-agnostic: a tier-0 theme keeps its
colours only as ``theme.md`` prose and a tiered theme keeps them in
``tokens/colors.json``, so the caller resolves whichever source exists and
hands this script the same flat map either way.

A ratio is a formula, not a judgement. Everything downstream of the arithmetic
-- the below-AA flag and the replacement-hex suggestion -- is computed here and
reported as data, so a caller never has to derive a figure of its own.

Thresholds are WCAG 2.1 AA: 4.5:1 for normal text, 3:1 for large text and UI
components. Both comparisons are inclusive and run against the unrounded
ratio; rounding is applied to the reported figure only.

A below-AA pair is a finding, not an error -- ``success`` stays true. False is
reserved for operational failure: an unreadable file, malformed JSON, or a
pair naming a role the palette does not define.

Nothing the palette supplies is dropped quietly. ``data.unparsed`` holds the
roles no spelling of which parsed as ``#rrggbb``; ``data.unclassified`` holds the
roles that parse fine but fall outside the vocabulary above, so they form no
default pair; ``data.collisions`` names the superseded spellings. All three
are reported on every run. A caller that reads only
``data.evaluated`` would otherwise be told a partial audit was a clean one --
the exact false-confidence shape this script exists to remove.

Role keys are normalised with ``strip().lower()``, so two spellings can collapse
onto one role. A normalised key lands in exactly one of ``data.roles`` and
``data.unparsed``, never both. Within a collided group the survivor is the first
entry in source order whose value parses as ``#rrggbb``, or the first entry when
none does -- so the survivor is not simply the earliest spelling, and which value
survives remains a function of key order in the file. The remedy is to
de-duplicate the source palette rather than to trust the survivor. What the group
does not do is lose an entry silently: every spelling the survivor supersedes is
named in ``data.collisions``, with the value it carried and the ``kept_key`` that
beat it.

Every pair also carries ``fg_luminance`` and ``bg_luminance``, the WCAG
relative luminances the ratio is computed from. They are reported as evidence,
never as a filter: this script pairs every foreground role with every surface
role, and only the theme itself knows which of those pairings it intends. No
pair is suppressed on the script's own guess about intent.

Usage:
    python3 check-contrast.py <palette.json>
    python3 check-contrast.py <palette.json> --pair text:background
    python3 check-contrast.py <palette.json> --large-pair accent:background
"""

import argparse
import colorsys
import json
import re
import sys
from pathlib import Path


AA_NORMAL = 4.5
AA_LARGE = 3.0

HEX_RE = re.compile(r"^#?([0-9A-Fa-f]{6})$")

# Role families used to derive the default pair set. The vocabulary tracks the
# role names this repo's themes actually carry -- ``themes/_template/theme.md``
# and every ``design-variables`` artifact spell the status colour ``danger``,
# never ``error``. A role the palette defines and this vocabulary does not
# classify is still reported, under ``data.unclassified``, so a mis-keyed or
# custom role can never leave the audit quietly partial.
#
# One role per line in LARGE_UI_ROLES: the mutation harness anchors on a
# single-line literal, and a tuple wrapped mid-role is not anchorable.
NORMAL_TEXT_ROLES = (
    "text",
    "text-light",
    "text-muted",
    "textmuted",
    "muted",
    "foreground",
    "fg",
)
LARGE_UI_ROLES = (
    "primary",
    "secondary",
    "accent",
    "accent-dark",
    "accent-muted",
    "border",
    "link",
    "success",
    "warning",
    "danger",
    "info",
)
SURFACE_ROLES = (
    "background",
    "bg",
    "surface",
    "surface-2",
    "surface-dark",
    "canvas",
    "card",
)

CLASSIFIED_ROLES = frozenset(NORMAL_TEXT_ROLES + LARGE_UI_ROLES + SURFACE_ROLES)


# ---------------------------------------------------------------------------
# Output envelope
# ---------------------------------------------------------------------------


def emit(success: bool, data=None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


# ---------------------------------------------------------------------------
# WCAG 2.1 arithmetic
# ---------------------------------------------------------------------------


def parse_hex(value):
    """Return (r, g, b) floats in 0..1, or None when value is not a hex colour."""
    if not isinstance(value, str):
        return None
    match = HEX_RE.match(value.strip())
    if not match:
        return None
    digits = match.group(1)
    return tuple(int(digits[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def relative_luminance(rgb):
    """WCAG 2.1 relative luminance from linearised sRGB channels."""
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast_ratio(fg_rgb, bg_rgb):
    """WCAG 2.1 contrast ratio between two colours, unrounded."""
    fg_luminance = relative_luminance(fg_rgb)
    bg_luminance = relative_luminance(bg_rgb)
    lighter = max(fg_luminance, bg_luminance)
    darker = min(fg_luminance, bg_luminance)
    return (lighter + 0.05) / (darker + 0.05)


def to_hex(rgb):
    return "#" + "".join("{:02X}".format(max(0, min(255, round(c * 255)))) for c in rgb)


def suggest_hex(fg_rgb, bg_rgb, threshold):
    """Walk the foreground's lightness at constant hue until it clears threshold.

    Each direction's exact endpoint -- L=0.0 for -1, L=1.0 for +1 -- is scored
    once that direction's stepped walk is exhausted, so pure black and pure
    white are always candidates. Returns a hex string this module has itself
    re-verified against threshold after snapping.

    None is returned only when neither the walk nor either endpoint clears. In
    exact arithmetic the two endpoint ratios multiply to a constant for any
    background -- ratio_black * ratio_white = ((L_bg + 0.05) / 0.05) *
    (1.05 / (L_bg + 0.05)) = 1.05 / 0.05 = 21 -- so the larger of the two is
    always at least sqrt(21) ~= 4.583. Both AA_NORMAL (4.5) and AA_LARGE (3.0)
    sit below that bound, so a run driven through this module's CLI cannot
    reach the None arm. threshold is a caller-supplied parameter, though: a
    value strictly above ~4.583 -- a future WCAG AAA 7:1, say -- can still
    return None.
    """
    hue, lightness, saturation = colorsys.rgb_to_hls(*fg_rgb)
    for direction in (-1, 1):
        step = 0.01
        candidate_lightness = lightness
        while 0.0 <= candidate_lightness <= 1.0:
            candidate_lightness += direction * step
            if not 0.0 <= candidate_lightness <= 1.0:
                break
            candidate = colorsys.hls_to_rgb(hue, candidate_lightness, saturation)
            if contrast_ratio(candidate, bg_rgb) >= threshold:
                snapped = parse_hex(to_hex(candidate))
                if snapped and contrast_ratio(snapped, bg_rgb) >= threshold:
                    return to_hex(candidate)
        # The accumulating walk terminates at -3.1e-17 / 1.0000000000000007
        # rather than on the bound, so it never scores the endpoint itself.
        # Score it here, after that direction is exhausted, which preserves the
        # existing try order: a pair the walk already answers keeps the shade
        # the walk found for it.
        #
        # The snap-and-re-verify below mirrors the walk deliberately and is NOT
        # a redundant identity: hls_to_rgb(hue, 1.0, saturation) is not exactly
        # (1, 1, 1) for every saturation -- at saturation 0.13 it comes back as
        # (0.9999999999999999, 1.0, 1.0) -- so the endpoint candidate is not a
        # constant and snapping it can move it. Do not "simplify" either check
        # away on the assumption that it cannot.
        endpoint_lightness = 0.0 if direction < 0 else 1.0
        endpoint = colorsys.hls_to_rgb(hue, endpoint_lightness, saturation)
        if contrast_ratio(endpoint, bg_rgb) >= threshold:
            snapped = parse_hex(to_hex(endpoint))
            if snapped and contrast_ratio(snapped, bg_rgb) >= threshold:
                return to_hex(endpoint)
    # Not dead code. Unreachable at both thresholds this CLI exposes, and
    # reachable only STRICTLY above ~4.583 -- at exactly sqrt(21) the >=
    # comparison still clears. Derivation in the docstring; cc33 pins it.
    return None


# ---------------------------------------------------------------------------
# Pair evaluation
# ---------------------------------------------------------------------------


def evaluate_pair(fg_role, bg_role, fg_value, bg_value, threshold):
    fg_rgb = parse_hex(fg_value)
    bg_rgb = parse_hex(bg_value)
    ratio = contrast_ratio(fg_rgb, bg_rgb)
    entry = {
        "foreground": fg_role,
        "background": bg_role,
        "fg_hex": fg_value,
        "bg_hex": bg_value,
        "fg_luminance": round(relative_luminance(fg_rgb), 4),
        "bg_luminance": round(relative_luminance(bg_rgb), 4),
        "ratio": round(ratio, 4),
        "threshold": threshold,
        "passes": ratio >= threshold,
        "passes_aa_normal": ratio >= AA_NORMAL,
        "passes_aa_large": ratio >= AA_LARGE,
    }
    if not entry["passes"]:
        entry["suggested_hex"] = suggest_hex(fg_rgb, bg_rgb, threshold)
    return entry


def default_pairs(usable):
    pairs = []
    surfaces = [r for r in SURFACE_ROLES if r in usable]
    for surface in surfaces:
        for role in NORMAL_TEXT_ROLES:
            if role in usable:
                pairs.append((role, surface, AA_NORMAL))
        for role in LARGE_UI_ROLES:
            if role in usable:
                pairs.append((role, surface, AA_LARGE))
    return pairs


def split_pair(raw, flag):
    parts = raw.split(":")
    if len(parts) != 2 or not parts[0] or not parts[1]:
        raise ValueError("{} expects FOREGROUND:BACKGROUND, got {!r}".format(flag, raw))
    return parts[0], parts[1]


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="WCAG 2.1 contrast ratios for a flat {role: '#rrggbb'} palette."
    )
    parser.add_argument("palette", help="path to a flat JSON map of role -> hex colour")
    parser.add_argument("--pair", action="append", default=[], metavar="FG:BG",
                        help="evaluate this role pair at the 4.5:1 normal-text threshold")
    parser.add_argument("--large-pair", action="append", default=[], metavar="FG:BG",
                        help="evaluate this role pair at the 3:1 large-text/UI threshold")
    args = parser.parse_args()

    path = Path(args.palette)
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return emit(False, None, "palette not found: {}".format(path))
    except (OSError, UnicodeDecodeError) as exc:
        return emit(False, None, "palette unreadable: {}".format(exc))
    except json.JSONDecodeError as exc:
        return emit(False, None, "palette is not valid JSON: {}".format(exc))

    if not isinstance(raw, dict):
        return emit(False, None, "palette must be a JSON object of role -> hex colour")

    grouped = {}
    for role, value in raw.items():
        grouped.setdefault(str(role).strip().lower(), []).append((role, value))

    usable = {}
    unparsed = {}
    collisions = []
    for key, entries in grouped.items():
        winner = next((i for i, (_r, v) in enumerate(entries)
                       if parse_hex(v) is not None), None)
        kept = 0 if winner is None else winner
        kept_role, kept_value = entries[kept]
        for role, value in entries[:kept] + entries[kept + 1:]:
            collisions.append({
                "role": key,
                "superseded_key": str(role),
                "superseded_value": value,
                "kept_key": str(kept_role),
            })
        if winner is None:
            unparsed[key] = kept_value
        else:
            usable[key] = kept_value.strip()

    requested = []
    try:
        for raw_pair in args.pair:
            fg, bg = split_pair(raw_pair, "--pair")
            requested.append((fg.lower(), bg.lower(), AA_NORMAL))
        for raw_pair in args.large_pair:
            fg, bg = split_pair(raw_pair, "--large-pair")
            requested.append((fg.lower(), bg.lower(), AA_LARGE))
    except ValueError as exc:
        return emit(False, None, str(exc))

    for fg, bg, _ in requested:
        for role in (fg, bg):
            if role not in usable:
                reason = ("is present but carries no usable hex value"
                          if role in unparsed else "is not in the palette")
                return emit(False, None,
                            "requested role {!r} {}".format(role, reason))

    pairs_to_run = requested or default_pairs(usable)

    pairs = [evaluate_pair(fg, bg, usable[fg], usable[bg], threshold)
             for fg, bg, threshold in pairs_to_run]
    failures = ["{} on {}".format(p["foreground"], p["background"])
                for p in pairs if not p["passes"]]

    data = {
        "palette": str(path),
        "roles": sorted(usable),
        "unparsed": unparsed,
        "collisions": collisions,
        "unclassified": sorted(set(usable) - CLASSIFIED_ROLES),
        "pairs": pairs,
        "evaluated": len(pairs),
        "failures": failures,
        "thresholds": {"aa_normal": AA_NORMAL, "aa_large": AA_LARGE},
    }
    return emit(True, data, "")


if __name__ == "__main__":
    sys.exit(main())
