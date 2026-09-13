#!/usr/bin/env python3
"""Shared theme-value guard for cogni dashboard/report renderers.

Operator-supplied ``--design-variables`` values are interpolated into a
generated ``<style>`` block. A value carrying CSS-structural or markup
characters — e.g. ``"background": "#000000</style><script>alert(1)</script>"`` —
could break out of the stylesheet in the self-contained HTML output, while
entity-derived values are HTML-escaped. This helper lets every renderer reject
such a value and fall back to its built-in palette for that key, so the guard
lives in one place instead of being copy-pasted per renderer.

Two consumption surfaces:

  * **In-plugin import** (the fast path used by renderers): load this file by
    path and call :func:`sanitize_section`, which resolves each section's profile
    and shape from :data:`SECTION_PROFILES` so no renderer restates that policy.
    (:func:`is_safe_value` / :func:`sanitize_values` remain the lower-level
    surface for a caller that already knows the profile it wants.) Renderers in
    *other* plugins cannot rely on a normal ``import`` (separate plugin cache
    dirs), so the natural consumers are cogni-workspace's own renderers; the
    cross-plugin sharing mechanism is a separate, deferred decision.
  * **CLI report**: ``python3 sanitize-theme.py <design-variables.json>`` prints
    a ``{"success","data","error"}`` envelope naming which keys would be
    rejected — the stdlib-only, dependency-free contract every cogni script
    follows.

Profiles
--------
``strict`` (the default)
    Denylist ``<>{}();@\\``, max length 120. Rejects stylesheet/markup breakout
    **and** the ``url()`` / ``@import`` external-fetch surface (a self-contained
    artifact that phones home on open). Correct for ``colors`` / ``status`` /
    border tokens, which never legitimately need those characters.

``font-aware``
    Denylist ``<>{};@\\`` (``strict``'s set minus the two paren characters), max
    length 300, **no shape gate**. For the declaration *values* ``strict`` cannot
    express: font stacks, shadows and ``radius``. Permits ``rgba(...)`` /
    ``url(...)`` by allowing parens, while ``;`` and ``@`` stay forbidden.

``import-aware``
    ``font-aware``'s denylist and bound, plus a *second, anchored acceptance
    path*: one ``@import url(<https-url>);`` statement or one bare ``https://…``
    URL. Applied to ``google_fonts_import`` alone.

    The split between these two profiles is load-bearing, and collapsing them is
    the bug this table shape exists to prevent. The shape gate's URL alternative
    must tolerate ``@`` and ``;`` *inside* the URL — the shipped default needs
    both for ``wght@400;500`` — so a value accepted by the gate can carry those
    characters. That is safe **only** where the value is emitted as a complete
    at-rule statement of its own, which is true of ``google_fonts_import`` and of
    nothing else. Wired to a section interpolated as a raw declaration value
    inside ``:root`` — as ``fonts`` / ``shadows`` / ``radius`` are — the same gate
    re-admits exactly the declaration chaining the denylist exists to block:
    ``https://a.example/x;background:red;position:fixed`` is a "bare URL" by
    shape and a two-declaration injection by effect.

    Rejected under both profiles: ``</style>`` / ``<script>`` and any markup
    breakout, rule-block injection (``{``/``}``), and ``;`` declaration
    injection. Rejected under ``import-aware`` specifically: ``data:`` /
    ``http:`` / protocol-relative schemes, chained imports
    (``@import a;@import b;``), media-qualified imports
    (``@import url(...) screen;``), and anything with trailing content —
    all of these are properties of the *shape gate*, which ``font-aware``
    deliberately does not carry.

    **Consequence for ``font-aware``:** with no shape gate it permits an
    arbitrary ``url(...)``, including non-https schemes, because the denylist
    alone cannot distinguish them. That is safe only in a slot whose consuming
    CSS property cannot fetch — ``font-family``, ``box-shadow`` and
    ``border-radius``, which is exactly what the profile covers. A renderer must
    **not** route a fetchable property (``background``, ``src``, ``mask``, …)
    through ``font-aware``; such a slot needs ``strict``, or a new row here.

    **Accepted residual, by policy:** a well-formed *https* ``@import`` from an
    arbitrary host passes — there is deliberately no host allowlist, so
    self-hosted, Bunny, and Adobe font hosts keep working. External imports are
    kept rather than inlined; narrowing that is a maintainer policy decision,
    not a property of this guard.

Single quotes stay legal under both profiles: a font stack
(``'Segoe UI', Roboto``) needs them and they cannot terminate a ``<style>``
block on their own.
"""

import json
import re
import sys

# One ``@import url(<https-url>);`` statement, or one bare ``https://…`` URL —
# the two shapes renderers actually accept (``cogni-visual/enrich-report``
# normalizes the latter into the former).
#
# Anchored ``^…\Z`` with **no trailing ``\s*``**. Both details are load-bearing:
# ``$`` alone matches *before* a trailing newline, and a trailing ``\s*``
# re-admits that newline even under ``\Z``. With the anchor tight, a shape-gated
# value carrying anything after the statement — ``@import url('https://h/x.css');
# body{color:red}``, a second chained ``@import``, or bare trailing whitespace —
# fails closed onto the built-in default rather than being normalized away.
#
# This gate is consulted **only when the denylist path already failed**, i.e. for
# values carrying ``@`` or ``;``. A value with none of the forbidden characters
# is accepted without ever being shape-checked — deliberately, since it provably
# cannot break out.
#
# It belongs to ``import-aware`` alone. Because the URL alternative must allow
# ``@`` and ``;`` inside the URL (the shipped default needs ``wght@400;500``),
# wiring it to a profile covering raw declaration values would let
# ``https://a.example/x;background:red`` through as a "bare URL" — see the
# module docstring.
#
# ``_URL`` is named once because both alternatives must stay identical: excluding
# whitespace, quotes, parens, angle brackets, braces and backslash is what makes
# a shape-accepted value provably free of every breakout character, and is also
# what makes the captured URL safe to re-wrap in ``url('…')`` below.
_URL = r"https://[^\s'\"()<>{}\\]+"
# The named groups exist so :func:`normalize_font_import` can recover the URL
# from either alternative. Group 1 stays the optional quote (the ``\1``
# backreference pairs the closing quote with the opening one), so the named
# groups are added *after* it.
_FONT_IMPORT_RE = re.compile(
    r"^(?:@import\s+url\(\s*(['\"]?)(?P<stmt>" + _URL + r")\1\s*\)\s*;?"
    r"|(?P<bare>" + _URL + r"))\Z"
)

def normalize_font_import(value):
    """Canonicalize an accepted import value into ``@import url('<url>');``.

    Returns the canonical statement, or ``None`` when ``value`` is not a
    well-formed import — the caller treats that as "no usable override" and
    keeps its default.

    Normalizing is a correctness requirement, not tidiness. The value is emitted
    verbatim at the top of the ``<style>`` block, immediately before ``:root {``,
    and two shapes the gate accepts are not self-terminating there: a **bare
    URL** (no ``@import``, no ``;``) and an ``@import`` whose optional trailing
    ``;`` is absent. In both cases CSS error recovery consumes the following
    block, so the whole ``:root`` rule is swallowed and every theme variable is
    silently lost. Re-emitting one canonical, terminated statement makes both
    inputs safe by construction.

    Re-wrapping is provably well-formed because ``_URL`` excludes quotes,
    parens and whitespace, so the captured URL can never close the ``url('…')``
    it is placed inside.
    """
    match = _FONT_IMPORT_RE.match(value) if isinstance(value, str) else None
    if match is None:
        return None
    return "@import url('%s');" % (match.group("stmt") or match.group("bare"))


# profile name -> (forbidden character set, max length, optional shape regex,
# optional normalizer). The regex is the profile's *second* acceptance path and
# the normalizer canonicalizes what that path accepts; carrying both in the
# record keeps this table the complete statement of policy, so a future profile
# is a new row rather than a new branch inside is_safe_value or sanitize_section.
# A gate-carrying profile whose normalizer were wired up by name somewhere else
# would fail silently — see normalize_font_import for what that costs.
_PROFILES = {
    "strict": (set("<>{}();@\\"), 120, None, None),
    "font-aware": (set("<>{};@\\"), 300, None, None),
    "import-aware": (set("<>{};@\\"), 300, _FONT_IMPORT_RE, normalize_font_import),
}
DEFAULT_PROFILE = "strict"
FONT_AWARE_PROFILE = "font-aware"
IMPORT_AWARE_PROFILE = "import-aware"


def _profile(name):
    """Resolve a profile name to its record, failing closed onto ``strict``."""
    return _PROFILES[name if name in _PROFILES else DEFAULT_PROFILE]

# Which profile each design-variables section is vetted under, and whether it is
# a ``{key: value}`` map or a single string value. This is a fact about the
# shared design-variables schema rather than about any one renderer — every
# consumer reads the same section names in the same shapes — so it lives here
# instead of being restated per renderer. Consume it via :func:`sanitize_section`.
SECTION_PROFILES = {
    "colors": ("dict", DEFAULT_PROFILE),
    "status": ("dict", DEFAULT_PROFILE),
    "fonts": ("dict", FONT_AWARE_PROFILE),
    "shadows": ("dict", FONT_AWARE_PROFILE),
    "google_fonts_import": ("scalar", IMPORT_AWARE_PROFILE),
    "radius": ("scalar", FONT_AWARE_PROFILE),
}


def is_safe_value(value, profile=DEFAULT_PROFILE):
    """Return True when ``value`` is safe to interpolate into a ``<style>`` block.

    A value passes on either of two paths, and the profile's length bound
    applies to both. The **denylist path** (the only one ``strict`` has) accepts
    a non-empty string carrying none of the profile's forbidden characters. The
    **shape path** accepts a value matching the profile's own regex, when it
    declares one — see the module docstring for why that escape hatch is narrow
    rather than a wider denylist.

    Non-strings (numbers, dicts, None) are unsafe on both paths — theme values
    reach the stylesheet as raw text, so only vetted strings may pass. An
    unknown profile name falls back to ``strict``, i.e. fails closed onto the
    tightest policy.

    **For a profile declaring a normalizer, acceptance here is necessary but not
    sufficient.** The denylist path accepts values the shape gate never sees, so
    an ``import-aware`` value can pass this check and still be unemittable —
    ``'Roboto'`` is accepted, yet emitting it where an ``@import`` belongs
    reintroduces the ``:root``-swallowing failure :func:`normalize_font_import`
    exists to prevent. Callers must go through :func:`sanitize_section` (or
    apply the profile's normalizer themselves) before emitting such a value.
    """
    forbidden, max_len, shape, _ = _profile(profile)
    if not isinstance(value, str) or not (0 < len(value) <= max_len):
        return False
    if not (forbidden & set(value)):
        return True
    return shape is not None and bool(shape.match(value))


def sanitize_values(values, defaults, profile=DEFAULT_PROFILE):
    """Filter a ``{key: value}`` override map against a fallback map.

    Returns ``(clean, rejected)`` where ``clean`` carries the safe overrides
    merged onto ``defaults`` (a rejected or absent key keeps the ``defaults``
    value), and ``rejected`` is the sorted list of keys whose override was
    dropped. ``defaults`` is the source of truth for the key set — an override
    key absent from ``defaults`` is ignored, never introduced.
    """
    clean = dict(defaults)
    rejected = []
    if isinstance(values, dict):
        for key in defaults:
            if key not in values:
                continue
            if is_safe_value(values[key], profile):
                clean[key] = values[key]
            else:
                rejected.append(key)
    return clean, sorted(rejected)


def sanitize_section(section, value, defaults, profile=None):
    """Vet one design-variables section under the profile its consumers apply.

    The single entry point a renderer should use: it resolves the section's
    shape and profile from :data:`SECTION_PROFILES`, so no caller has to restate
    which sections are dict-shaped or which profile each one takes. Returns
    ``(clean, rejected)`` — ``clean`` being the vetted value (or ``defaults``
    when the override is rejected) and ``rejected`` a list of dropped keys, or
    ``[section]`` for a rejected scalar.

    An absent or empty scalar is **not** an override — an empty
    ``google_fonts_import`` legitimately means "no import" — so it yields
    ``defaults`` with nothing rejected rather than being reported as unsafe.

    A scalar is additionally passed through its profile's normalizer, when that
    profile declares one, so the value a renderer interpolates is canonical — for
    ``import-aware`` that means an always-terminated ``@import`` statement. A
    value that passes the denylist but the normalizer cannot canonicalize has no
    valid rendering in that slot, so it is rejected rather than emitted raw.

    ``profile`` overrides the section's default profile; leave it ``None`` to
    apply the policy the renderers actually use. The override is **ignored for a
    dict-shaped section when it names a normalizer-carrying profile**: the
    per-key path cannot normalize, so honouring it would accept a gate-shaped
    value and emit it raw into a declaration slot — reinstating the very
    injection the profile split closes. An unknown section falls back to the
    tightest policy rather than raising, matching :func:`_profile`, so a renderer
    using a section outside the table degrades instead of killing the render.
    """
    shape, section_profile = SECTION_PROFILES.get(section, ("dict", DEFAULT_PROFILE))
    applied = profile or section_profile
    if shape == "dict":
        if _profile(applied)[3] is not None:
            applied = section_profile
        return sanitize_values(value, defaults, applied)
    if value in (None, ""):
        return defaults, []
    if is_safe_value(value, applied):
        normalizer = _profile(applied)[3]
        clean = normalizer(value) if normalizer is not None else value
        if clean is not None:
            return clean, []
    return defaults, [section]


def _cli(argv):
    """Report which design-variable override values a file would lose.

    Walks every section in :data:`SECTION_PROFILES`, vetting each under the
    profile that section's renderer applies. An explicit ``--profile=`` forces
    one profile across all sections instead — useful for asking "what would
    `strict` reject here?" of a file the renderer treats more leniently.
    """
    args = [a for a in argv if not a.startswith("--")]
    forced_profile = None
    for a in argv:
        if a.startswith("--profile="):
            forced_profile = a.split("=", 1)[1]
    if not args:
        return {"success": False, "data": None,
                "error": "usage: sanitize-theme.py <design-variables.json> "
                         "[--profile=strict|font-aware|import-aware]"}
    if forced_profile is not None and forced_profile not in _PROFILES:
        return {"success": False, "data": None,
                "error": "unknown profile %r (available: %s)"
                         % (forced_profile, ", ".join(sorted(_PROFILES)))}
    try:
        with open(args[0], "r", encoding="utf-8") as f:
            overrides = json.load(f)
    except (OSError, ValueError) as exc:
        return {"success": False, "data": None, "error": "cannot read %s: %s" % (args[0], exc)}
    if not isinstance(overrides, dict):
        return {"success": False, "data": None, "error": "design-variables must be a JSON object"}

    rejected = {}
    section_profiles = {}
    checked = 0
    for section, (shape, section_profile) in SECTION_PROFILES.items():
        section_profiles[section] = forced_profile or section_profile
        src = overrides.get(section)
        # Report against the file's own keys, so `defaults` is `src` itself —
        # the same walk `sanitize_section` gives a renderer, minus the fallback
        # values a report has no use for.
        if shape == "dict" and isinstance(src, dict):
            checked += len(src)
        elif shape == "scalar" and src not in (None, ""):
            checked += 1
        else:
            continue
        _, bad = sanitize_section(section, src, src, forced_profile)
        if bad:
            rejected[section] = bad
    return {"success": True,
            # ``profile`` stays a string on every invocation — it names the
            # profile in force across the walk, falling back to the default when
            # none was forced. Reporting the *forced* value here (and so ``null``
            # by default) would be a type change on a field callers already read
            # as always-a-string; the per-section detail this profile model adds
            # is carried additively by ``section_profiles`` instead.
            "data": {"profile": forced_profile or DEFAULT_PROFILE,
                     "section_profiles": section_profiles,
                     "checked": checked,
                     "rejected": rejected},
            "error": None}


if __name__ == "__main__":
    result = _cli(sys.argv[1:])
    print(json.dumps(result))
    # Envelope is always printed; a usage/read error also exits non-zero so a
    # shell caller can branch on `$?`, matching the cogni script convention.
    sys.exit(0 if result["success"] else 2)
