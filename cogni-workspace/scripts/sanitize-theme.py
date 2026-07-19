#!/usr/bin/env python3
"""Shared theme-value guard for cogni dashboard/report renderers.

Operator-supplied ``--design-variables`` values are interpolated into a
generated ``<style>`` block. A value carrying CSS-structural or markup
characters — e.g. ``"background": "#000</style><script>alert(1)</script>"`` —
could break out of the stylesheet in the self-contained HTML output, while
entity-derived values are HTML-escaped. This helper lets every renderer reject
such a value and fall back to its built-in palette for that key, so the guard
lives in one place instead of being copy-pasted per renderer.

Two consumption surfaces:

  * **In-plugin import** (the fast path used by renderers): load this file by
    path and call :func:`is_safe_value` / :func:`sanitize_values`. Renderers in
    *other* plugins cannot rely on a normal ``import`` (separate plugin cache
    dirs), so the natural consumers are cogni-workspace's own renderers; the
    cross-plugin sharing mechanism is a separate, deferred decision.
  * **CLI report**: ``python3 sanitize-theme.py <design-variables.json>`` prints
    a ``{"success","data","error"}`` envelope naming which keys would be
    rejected — the stdlib-only, dependency-free contract every cogni script
    follows.

Profiles
--------
``strict`` (the only profile shipped today, and the default)
    Denylist ``<>{}();@\\``, max length 120. Rejects stylesheet/markup breakout
    **and** the ``url()`` / ``@import`` external-fetch surface (a self-contained
    artifact that phones home on open). Correct for ``colors`` / ``status`` /
    border tokens, which never legitimately need those characters. It is
    deliberately **not** applied to font or shadow values that legitimately
    carry ``rgba(...)`` or ``@import url(...)`` — a ``font-aware`` profile that
    permits those while still blocking breakout is future work.

Single quotes stay legal under ``strict``: a font stack (``'Segoe UI', Roboto``)
needs them and they cannot terminate a ``<style>`` block on their own.
"""

import json
import sys

# profile name -> (forbidden character set, max length)
_PROFILES = {
    "strict": (set("<>{}();@\\"), 120),
}
DEFAULT_PROFILE = "strict"


def is_safe_value(value, profile=DEFAULT_PROFILE):
    """Return True when ``value`` is safe to interpolate into a ``<style>`` block.

    A value is safe when it is a non-empty string within the profile's length
    bound and carries none of the profile's forbidden characters. Non-strings
    (numbers, dicts, None) are unsafe — theme values reach the stylesheet as raw
    text, so only vetted strings may pass.
    """
    forbidden, max_len = _PROFILES.get(profile, _PROFILES[DEFAULT_PROFILE])
    return (
        isinstance(value, str)
        and 0 < len(value) <= max_len
        and not (forbidden & set(value))
    )


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


def _cli(argv):
    """Report which color/status override values a design-variables file would lose."""
    args = [a for a in argv if not a.startswith("--")]
    profile = DEFAULT_PROFILE
    for a in argv:
        if a.startswith("--profile="):
            profile = a.split("=", 1)[1]
    if not args:
        return {"success": False, "data": None,
                "error": "usage: sanitize-theme.py <design-variables.json> [--profile=strict]"}
    if profile not in _PROFILES:
        return {"success": False, "data": None,
                "error": "unknown profile %r (available: %s)" % (profile, ", ".join(sorted(_PROFILES)))}
    try:
        with open(args[0], "r", encoding="utf-8") as f:
            overrides = json.load(f)
    except (OSError, ValueError) as exc:
        return {"success": False, "data": None, "error": "cannot read %s: %s" % (args[0], exc)}
    if not isinstance(overrides, dict):
        return {"success": False, "data": None, "error": "design-variables must be a JSON object"}

    rejected = {}
    checked = 0
    for section in ("colors", "status"):
        src = overrides.get(section)
        if isinstance(src, dict):
            for key, value in src.items():
                checked += 1
                if not is_safe_value(value, profile):
                    rejected.setdefault(section, []).append(key)
    for section in rejected:
        rejected[section] = sorted(rejected[section])
    return {"success": True,
            "data": {"profile": profile, "checked": checked, "rejected": rejected},
            "error": None}


if __name__ == "__main__":
    result = _cli(sys.argv[1:])
    print(json.dumps(result))
    # Envelope is always printed; a usage/read error also exits non-zero so a
    # shell caller can branch on `$?`, matching the cogni script convention.
    sys.exit(0 if result["success"] else 2)
