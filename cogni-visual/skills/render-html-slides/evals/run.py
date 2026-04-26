#!/usr/bin/env python3
"""evals/run.py — Regression eval for render-html-slides Theme System v2 wiring.

Stdlib-only. Three test cases, run end-to-end against the real
``generate-html-slides.py`` script:

1. **Tier-0 baseline (regression).** No ``--theme-slug`` flag. Asserts the
   rendered HTML contains the inline ``:root`` token block and does NOT
   contain an ``@import url(...tokens.css)`` line. This is the well-tested
   default code path — it runs on every legacy invocation.

2. **Tier-1 tokens.css import.** ``--theme-slug cogni-work`` against the
   real ``cogni-workspace/themes/cogni-work`` (which declares
   ``tiers.tokens`` and has ``tokens/tokens.css`` on disk). Asserts the
   rendered HTML contains an ``@import url('file://.../cogni-work/tokens/tokens.css')``
   line ahead of the inline ``:root`` block.

3. **Tier-0 theme with --theme-slug (graceful fallback).** ``--theme-slug
   _template`` against the manifestless ``_template`` theme. Asserts the
   rendered HTML behaves exactly like case (1) — the missing manifest is a
   normal control-flow signal that triggers the fallback path. This is
   also the well-tested code path that runs whenever a theme without
   ``tiers.tokens`` is selected (so today, every cogni-work consumer that
   passes ``--theme-slug cogni-work`` falls into case 2; every legacy
   caller falls into case 1; this case 3 is the documented behavior for
   in-between themes that haven't migrated yet).

Exit code 0 on all-pass, 1 on any failure. Prints a JSON results envelope
on stdout for machine consumption.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
SKILL_DIR = HERE.parent
SCRIPT = SKILL_DIR / "scripts" / "generate-html-slides.py"
PLUGIN_ROOT = SKILL_DIR.parent.parent  # cogni-visual/
REPO_ROOT = PLUGIN_ROOT.parent  # insight-wave/
THEMES_DIR = REPO_ROOT / "cogni-workspace" / "themes"


MINIMAL_SLIDE_DATA = {
    "metadata": {
        "title": "Eval Deck",
        "customer": "Test",
        "provider": "Test",
        "generated": "2026-04-25",
    },
    "slides": [
        {
            "number": 1,
            "layout": "title-slide",
            "headline": "Phase 2 Pilot",
            "fields": {"Subtitle": "Theme System v2"},
        },
        {
            "number": 2,
            "layout": "generic",
            "headline": "Tier-1 Tokens",
            "bullets": ["tokens.css imports cleanly", "Inline :root provides fallbacks"],
            "fields": {},
        },
    ],
}


def run_render(theme_slug=None, themes_dir=None):
    """Invoke generate-html-slides.py with optional --theme-slug. Returns the
    rendered HTML body as a string and the JSON status the script printed."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        slide_data_path = tmp / "slide-data.json"
        output_path = tmp / "out.html"
        slide_data_path.write_text(json.dumps(MINIMAL_SLIDE_DATA), encoding="utf-8")

        cmd = [
            sys.executable,
            str(SCRIPT),
            "--slide-data", str(slide_data_path),
            "--output", str(output_path),
        ]
        if theme_slug:
            cmd += ["--theme-slug", theme_slug]
        if themes_dir:
            cmd += ["--themes-dir", str(themes_dir)]

        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            return None, {"error": proc.stderr or proc.stdout}
        try:
            status = json.loads(proc.stdout.strip().splitlines()[-1])
        except (json.JSONDecodeError, IndexError):
            status = {"raw": proc.stdout}
        html = output_path.read_text(encoding="utf-8")
        return html, status


def assert_substring(name, html, needle, present=True):
    found = needle in html
    if found != present:
        verb = "missing" if present else "unexpectedly present"
        return False, "{}: {} substring '{}'".format(name, verb, needle[:80])
    return True, None


def case_1_tier0_baseline():
    html, status = run_render(theme_slug=None)
    if html is None:
        return False, "case 1: render failed: {}".format(status.get("error"))
    checks = [
        assert_substring("case 1", html, "@import url('file://", present=False),
        assert_substring("case 1", html, "tokens.css", present=False),
        assert_substring("case 1", html, ":root", present=True),
        assert_substring("case 1", html, "--primary:", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is True:
        failures.append("case 1: status reported tokens_css_imported=true on legacy invocation")
    return len(failures) == 0, failures


def case_2_tier1_cogni_work():
    cogni_work = THEMES_DIR / "cogni-work"
    if not (cogni_work / "manifest.json").is_file() or not (cogni_work / "tokens" / "tokens.css").is_file():
        return False, ["case 2: cogni-work tier-1 layout missing on disk — phase-1 deps not merged?"]
    html, status = run_render(theme_slug="cogni-work", themes_dir=THEMES_DIR)
    if html is None:
        return False, ["case 2: render failed: {}".format(status.get("error"))]
    expected_import = "@import url('file://{}/cogni-work/tokens/tokens.css'".format(THEMES_DIR.resolve())
    checks = [
        assert_substring("case 2", html, expected_import, present=True),
        assert_substring("case 2", html, ":root", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is not True:
        failures.append("case 2: status reported tokens_css_imported={} (expected true)".format(status.get("tokens_css_imported")))
    return len(failures) == 0, failures


def case_3_tier0_theme_with_slug():
    template = THEMES_DIR / "_template"
    if not template.is_dir():
        return False, ["case 3: _template theme missing on disk"]
    if (template / "manifest.json").is_file():
        return False, ["case 3: _template unexpectedly has a manifest.json — graceful-fallback case is invalid"]
    html, status = run_render(theme_slug="_template", themes_dir=THEMES_DIR)
    if html is None:
        return False, ["case 3: render failed: {}".format(status.get("error"))]
    checks = [
        assert_substring("case 3", html, "@import url('file://", present=False),
        assert_substring("case 3", html, ":root", present=True),
    ]
    failures = [msg for ok, msg in checks if not ok]
    if status.get("tokens_css_imported") is True:
        failures.append("case 3: status reported tokens_css_imported=true (expected false — fallback path)")
    return len(failures) == 0, failures


def main():
    cases = [
        ("tier-0 baseline (regression)", case_1_tier0_baseline),
        ("tier-1 cogni-work tokens.css", case_2_tier1_cogni_work),
        ("tier-0 _template with --theme-slug (graceful fallback)", case_3_tier0_theme_with_slug),
    ]
    results = []
    failed = 0
    for name, fn in cases:
        ok, detail = fn()
        results.append({
            "name": name,
            "passed": ok,
            "details": detail if not ok else None,
        })
        if not ok:
            failed += 1

    envelope = {
        "passed": failed == 0,
        "total": len(cases),
        "failed": failed,
        "results": results,
    }
    print(json.dumps(envelope, indent=2))
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
