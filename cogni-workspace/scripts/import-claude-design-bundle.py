#!/usr/bin/env python3
"""import-claude-design-bundle.py — Materialise a Claude Design handoff bundle
into a Theme System v2 (RFC #132 Phase 3) theme directory.

Stdlib-only. Reads the curated mapping at
``references/claude-design-bundle-mapping.md``; the rules below are the
machine-readable mirror of that document.

Pipeline: fetch URL (or read local archive) → verify gzip + sha256 → untar
to a temp dir → assert bundle shape (root dir, theme.md, colors_and_type.css)
→ voice-header pre-check → project tokens (CSS → JSON) → regenerate
tokens.css via ``generate-tokens-css.py`` → copy components / assets / deck
primitives per the allowlist → regenerate manifest.json → validate via
``validate-theme-manifest.py`` → write ``.claude-design-source`` sidecar.

Re-syncable upstream contract: re-running with the same URL is a no-op when
the freshly-fetched archive's sha256 matches the sidecar's recorded sha256.

Usage:
    python3 import-claude-design-bundle.py --url <url>    --target <theme-dir> [--dry-run] [--allow-overwrite]
    python3 import-claude-design-bundle.py --bundle <tar> --target <theme-dir> [--dry-run] [--allow-overwrite]

Output: standard cogni-workspace JSON envelope to stdout
    {"success": bool, "data": {...}, "error": "string"}
Exit code 0 on success, 1 on failure.
"""

import argparse
import gzip
import hashlib
import importlib.util
import io
import json
import os
import re
import shutil
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


IMPORTER_VERSION = "1.0"
SIDECAR_FILENAME = ".claude-design-source"
VOICE_HEADER = "## Voice & Copy Guidelines"
MANIFEST_SCHEMA_VERSION = "1.0"

SCRIPT_DIR = Path(__file__).resolve().parent
GENERATOR_PATH = SCRIPT_DIR / "generate-tokens-css.py"
VALIDATOR_PATH = SCRIPT_DIR / "validate-theme-manifest.py"


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot locate {}".format(path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# Load the generator once at module init so we can share its CANONICAL_FILES
# tuple — a separate copy here would silently drift if a 7th canonical stem
# was added to the generator but forgotten here.
_TOKEN_GEN = _load_module(GENERATOR_PATH, "_token_gen")
CANONICAL_TOKEN_STEMS = _TOKEN_GEN.CANONICAL_FILES

# CSS variable → (token stem, key) projection rules. Evaluated in order;
# the first match wins. Variables that match none of these patterns are
# silently dropped (they belong to the bundle's semantic layer or to base
# element styles).
TOKEN_PROJECTION = [
    (re.compile(r"^--cw-(.+)$"), "colors", lambda m: m.group(1)),
    (re.compile(r"^--font-(.+)$"), "typography", lambda m: "font-" + m.group(1)),
    (re.compile(r"^--fs-(.+)$"), "typography", lambda m: "size-" + m.group(1)),
    (re.compile(r"^--lh-(.+)$"), "typography", lambda m: "line-height-" + m.group(1)),
    (re.compile(r"^--ls-(.+)$"), "typography", lambda m: "tracking-" + m.group(1)),
    (re.compile(r"^--sp-(.+)$"), "spacing", lambda m: m.group(1)),
    (re.compile(r"^--r-(.+)$"), "radii", lambda m: m.group(1)),
    (re.compile(r"^--sh-(.+)$"), "shadows", lambda m: m.group(1)),
    (re.compile(r"^--ease-(.+)$"), "motion", lambda m: "ease-" + m.group(1)),
    (re.compile(r"^--dur-(.+)$"), "motion", lambda m: "dur-" + m.group(1)),
]

# Lossy-value markers — declarations whose value starts with or contains
# any of these are dropped because they cannot represent a literal primitive.
LOSSY_VALUE_PREFIXES = ("var(", "calc(", "color-mix(", "env(", "attr(")

# Component allowlist: bundle preview filename → web component filename.
# Anything in preview/ that does not appear here is skipped (specimens or
# out-of-scope primitives).
COMPONENT_ALLOWLIST = {
    "components-cards.html": "cards.html",
    "components-buttons.html": "buttons.html",
    "components-badges.html": "badges.html",
    "components-kpi.html": "kpi.html",
    "components-table.html": "table.html",
    "components-nav-tabs.html": "nav-tabs.html",
}

# Filenames in preview/ that should never warn (known specimens / deferred).
KNOWN_SKIPS = {
    "components-fields.html",
    "components-toggle-slider.html",
}
KNOWN_SKIP_PREFIXES = ("colors-", "type-", "spacing-", "brand-")


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------


def emit(success: bool, data=None, error: str = "") -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error}))
    return 0 if success else 1


def err(msg: str, **data) -> int:
    return emit(False, data=data, error=msg)


def _list_files(d: Path) -> list:
    """Sorted filenames in ``d``, or [] if ``d`` is not a directory."""
    return sorted(p.name for p in d.iterdir() if p.is_file()) if d.is_dir() else []


# ---------------------------------------------------------------------------
# Fetch and verify
# ---------------------------------------------------------------------------


def fetch_archive(url: str) -> bytes:
    """Stream a bundle URL into memory. Raises RuntimeError on any non-2xx."""
    req = urllib.request.Request(url, headers={"User-Agent": "import-claude-design-bundle/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.read()
    except urllib.error.HTTPError as e:
        raise RuntimeError("HTTP {} fetching {}: {}".format(e.code, url, e.reason))
    except urllib.error.URLError as e:
        raise RuntimeError("URL error fetching {}: {}".format(url, e.reason))


def read_local_archive(path: Path) -> bytes:
    try:
        return path.read_bytes()
    except (FileNotFoundError, IsADirectoryError, OSError) as e:
        raise RuntimeError("cannot read local archive {}: {}".format(path, e))


def assert_gzip(blob: bytes) -> None:
    if len(blob) < 2 or blob[0] != 0x1F or blob[1] != 0x8B:
        raise RuntimeError("archive is not gzip-compressed (magic bytes mismatch)")


# ---------------------------------------------------------------------------
# Tar extraction
# ---------------------------------------------------------------------------


def extract_archive(blob: bytes, target_dir: Path) -> Path:
    """Untar the gzipped bundle to ``target_dir``. Returns the single top-level
    directory inside the archive (e.g. ``cogni-work-design-system/``).
    """
    buf = io.BytesIO(gzip.decompress(blob))
    with tarfile.open(fileobj=buf, mode="r:") as tar:
        # Filter out macOS AppleDouble resource forks and .DS_Store noise that
        # can appear when bundles are round-tripped through Finder. The real
        # server-generated archive does not contain these.
        members = [
            m
            for m in tar.getmembers()
            if not Path(m.name).name.startswith("._") and Path(m.name).name != ".DS_Store"
        ]
        if not members:
            raise RuntimeError("archive is empty")
        top_dirs = set()
        for m in members:
            if m.name.startswith("/") or ".." in Path(m.name).parts:
                raise RuntimeError("unsafe path in archive: {}".format(m.name))
            top_dirs.add(Path(m.name).parts[0])
        if len(top_dirs) != 1:
            raise RuntimeError(
                "expected single top-level directory in archive, got {}".format(sorted(top_dirs))
            )
        tar.extractall(target_dir, members=members)
    return target_dir / next(iter(top_dirs))


# ---------------------------------------------------------------------------
# Bundle shape validation
# ---------------------------------------------------------------------------


def derive_slug_from_root(bundle_root: Path) -> str:
    """The bundle root directory is conventionally ``{slug}-design-system/``."""
    name = bundle_root.name
    suffix = "-design-system"
    if not name.endswith(suffix):
        raise RuntimeError(
            "bundle root {!r} does not end in '{}'; cannot derive slug".format(name, suffix)
        )
    slug = name[: -len(suffix)]
    if not re.match(r"^[a-z0-9][a-z0-9-]*$", slug):
        raise RuntimeError("derived slug {!r} is not kebab-case".format(slug))
    return slug


def assert_bundle_shape(bundle_root: Path, slug: str) -> dict:
    """Confirm the required bundle files exist; return their resolved paths."""
    project = bundle_root / "project"
    if not project.is_dir():
        raise RuntimeError("bundle missing required directory: project/")
    theme_md = project / "{}-theme.md".format(slug)
    if not theme_md.is_file():
        raise RuntimeError("bundle missing required file: project/{}-theme.md".format(slug))
    css = project / "colors_and_type.css"
    if not css.is_file():
        raise RuntimeError("bundle missing required file: project/colors_and_type.css")
    return {
        "project": project,
        "theme_md": theme_md,
        "css": css,
        "preview": project / "preview",
        "slides": project / "slides",
        "uploads": project / "uploads",
    }


def assert_voice_header(theme_md: Path) -> None:
    """Phase D backcompat contract: theme.md must contain the voice header."""
    text = theme_md.read_text(encoding="utf-8")
    if VOICE_HEADER not in text:
        raise RuntimeError(
            "bundle theme.md missing required header '{}'. "
            "Phase D of verify-theme-backcompat.sh requires this section for "
            "voice consumers (cogni-narrative, cogni-sales, cogni-research, "
            "cogni-copywriting). Add the section in the Claude Design session "
            "and re-export the bundle. See "
            "references/claude-design-bundle-mapping.md for guidance.".format(VOICE_HEADER)
        )


# ---------------------------------------------------------------------------
# CSS → JSON token projection
# ---------------------------------------------------------------------------


_ROOT_BLOCK = re.compile(r":root\s*\{(.*?)\}", re.DOTALL)
_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
_DECL = re.compile(r"^\s*(--[A-Za-z0-9-]+)\s*:\s*([^;]+?)\s*;\s*$", re.MULTILINE)


def parse_root_declarations(css_text: str) -> list:
    """Return [(var_name, value), ...] from every :root { ... } block."""
    out = []
    for match in _ROOT_BLOCK.finditer(css_text):
        body = _COMMENT.sub("", match.group(1))
        for decl in _DECL.finditer(body):
            name, value = decl.group(1), decl.group(2).strip()
            out.append((name, value))
    return out


def is_literal_value(value: str) -> bool:
    lowered = value.lower()
    return not any(lowered.startswith(p) or " " + p in lowered for p in LOSSY_VALUE_PREFIXES)


def project_tokens(css_text: str) -> dict:
    """Return a {stem: {key: value, ...}, ...} dict for canonical stems."""
    result = {stem: {} for stem in CANONICAL_TOKEN_STEMS}
    for var_name, value in parse_root_declarations(css_text):
        if not is_literal_value(value):
            continue
        for pattern, stem, key_fn in TOKEN_PROJECTION:
            m = pattern.match(var_name)
            if not m:
                continue
            key = key_fn(m)
            # Earlier patterns win — typography prefixes (--fs/--lh/--ls)
            # must be checked before the broader --font-* rule. Our table
            # already orders them correctly; an exact-key conflict within
            # one stem is overwritten by the later declaration (last write
            # wins), matching CSS cascade semantics for :root.
            result[stem][key] = value
            break
    return result


def write_tokens(tokens_dir: Path, projected: dict) -> list:
    """Write the populated stems to <stem>.json files. Returns the list of
    written stems."""
    tokens_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for stem in CANONICAL_TOKEN_STEMS:
        data = projected[stem]
        if not data:
            continue
        out_path = tokens_dir / "{}.json".format(stem)
        with out_path.open("w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False, sort_keys=True)
            f.write("\n")
        written.append(stem)
    return written


# ---------------------------------------------------------------------------
# Generator / validator delegation
# ---------------------------------------------------------------------------


def regenerate_tokens_css(tokens_dir: Path) -> int:
    """Call generate-tokens-css.py's generate() (loaded at module init) and
    write tokens.css. Return the byte count written."""
    css = _TOKEN_GEN.generate(tokens_dir)
    out = tokens_dir / "tokens.css"
    out.write_text(css, encoding="utf-8")
    return len(css)


def run_validator(theme_dir: Path) -> tuple:
    """Run the validator script as a subprocess (it has its own CLI). Return
    (success: bool, parsed_json: dict)."""
    import subprocess

    proc = subprocess.run(
        [sys.executable, str(VALIDATOR_PATH), str(theme_dir)],
        capture_output=True,
        text=True,
        timeout=30,
    )
    try:
        payload = json.loads(proc.stdout.strip().splitlines()[-1])
    except (json.JSONDecodeError, IndexError):
        return False, {
            "raw_stdout": proc.stdout,
            "raw_stderr": proc.stderr,
            "returncode": proc.returncode,
        }
    return proc.returncode == 0 and payload.get("success", False), payload


# ---------------------------------------------------------------------------
# Materialisation steps
# ---------------------------------------------------------------------------


def copy_components(preview_dir: Path, target_components: Path) -> dict:
    """Copy allowlisted preview/*.html files into components/web/. Returns
    a report dict."""
    written, skipped, warned = [], [], []
    if not preview_dir.is_dir():
        return {"web": written, "skipped": skipped, "warnings": warned}
    web_dir = target_components / "web"
    for f in sorted(preview_dir.iterdir()):
        if not f.is_file() or not f.name.endswith(".html"):
            continue
        target_name = COMPONENT_ALLOWLIST.get(f.name)
        if target_name:
            web_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, web_dir / target_name)
            written.append(target_name)
            continue
        if f.name in KNOWN_SKIPS or f.name.startswith(KNOWN_SKIP_PREFIXES):
            skipped.append(f.name)
            continue
        warned.append(f.name)
    return {"web": written, "skipped": skipped, "warnings": warned}


def copy_slides(slides_dir: Path, target_components: Path) -> list:
    """Copy every file under slides/ verbatim to components/deck/."""
    written = []
    if not slides_dir.is_dir():
        return written
    deck_dir = target_components / "deck"
    for f in sorted(slides_dir.iterdir()):
        if not f.is_file():
            continue
        deck_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, deck_dir / f.name)
        written.append(f.name)
    return written


def copy_assets(uploads_dir: Path, target_assets: Path) -> list:
    written = []
    if not uploads_dir.is_dir():
        return written
    for f in sorted(uploads_dir.iterdir()):
        if not f.is_file():
            continue
        target_assets.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, target_assets / f.name)
        written.append(f.name)
    return written


def title_case_slug(slug: str) -> str:
    return " ".join(part.capitalize() for part in slug.split("-"))


def build_manifest(slug: str, populated_tiers: dict) -> dict:
    manifest = {
        "schema_version": MANIFEST_SCHEMA_VERSION,
        "name": title_case_slug(slug),
        "slug": slug,
    }
    tiers = {}
    if populated_tiers.get("tokens"):
        tiers["tokens"] = "tokens/"
    if populated_tiers.get("assets"):
        tiers["assets"] = "assets/"
    components = {}
    if populated_tiers.get("components_web"):
        components["web"] = "components/web/"
    if populated_tiers.get("components_deck"):
        components["deck"] = "components/deck/"
    if components:
        tiers["components"] = components
    if tiers:
        manifest["tiers"] = tiers
    manifest["voice_ref"] = "theme.md#voice--copy-guidelines"
    return manifest


def write_manifest(theme_dir: Path, manifest: dict) -> None:
    with (theme_dir / "manifest.json").open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write("\n")


def write_sidecar(theme_dir: Path, url: str, sha256: str, bundle_root: str) -> None:
    sidecar = {
        "url": url,
        "sha256": sha256,
        "imported_at": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "bundle_root": bundle_root,
        "importer_version": IMPORTER_VERSION,
    }
    with (theme_dir / SIDECAR_FILENAME).open("w", encoding="utf-8") as f:
        json.dump(sidecar, f, indent=2, ensure_ascii=False)
        f.write("\n")


def read_sidecar(theme_dir: Path):
    try:
        with (theme_dir / SIDECAR_FILENAME).open("r", encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def parse_args(argv) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Materialise a Claude Design handoff bundle into a Theme System v2 theme directory."
    )
    src = parser.add_mutually_exclusive_group(required=True)
    src.add_argument("--url", help="Bundle URL (https://api.anthropic.com/v1/design/h/<hash>)")
    src.add_argument("--bundle", help="Path to a local .tar.gz bundle (for testing)")
    parser.add_argument("--target", required=True, help="Path to the target theme directory")
    parser.add_argument("--dry-run", action="store_true", help="Extract and validate but do not write")
    parser.add_argument(
        "--allow-overwrite",
        action="store_true",
        help="Permit overwriting existing files in --target (required when target is non-empty)",
    )
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> int:
    target = Path(args.target).resolve()

    # Fetch + verify.
    try:
        if args.url:
            blob = fetch_archive(args.url)
            source_url = args.url
        else:
            blob = read_local_archive(Path(args.bundle))
            source_url = "file://" + str(Path(args.bundle).resolve())
        assert_gzip(blob)
    except RuntimeError as e:
        return err(str(e))
    sha256 = hashlib.sha256(blob).hexdigest()

    # Idempotency check — skip if sidecar matches.
    existing = read_sidecar(target) if target.is_dir() else None
    if existing and existing.get("sha256") == sha256 and existing.get("url") == source_url:
        return emit(
            True,
            data={
                "noop": True,
                "reason": "sidecar sha256 matches; bundle unchanged since {}".format(
                    existing.get("imported_at")
                ),
                "target": str(target),
                "sha256": sha256,
            },
        )

    # Overwrite gate.
    if target.exists() and any(target.iterdir()) and not args.allow_overwrite:
        return err(
            "target {} is not empty; pass --allow-overwrite to permit re-syncing this theme".format(target)
        )

    # Extract.
    with tempfile.TemporaryDirectory(prefix="claude-design-bundle-") as tmpdir:
        tmp = Path(tmpdir)
        try:
            bundle_root = extract_archive(blob, tmp)
            slug = derive_slug_from_root(bundle_root)
            paths = assert_bundle_shape(bundle_root, slug)
            assert_voice_header(paths["theme_md"])
        except RuntimeError as e:
            return err(str(e))

        # Project tokens.
        try:
            css_text = paths["css"].read_text(encoding="utf-8")
        except OSError as e:
            return err("cannot read bundle CSS: {}".format(e))
        projected = project_tokens(css_text)
        populated_stems = [stem for stem in CANONICAL_TOKEN_STEMS if projected[stem]]
        if not populated_stems:
            return err(
                "no canonical tokens projected from bundle CSS; "
                "the bundle may use a non-standard naming scheme"
            )

        # Dry-run report and exit before any write.
        if args.dry_run:
            return emit(
                True,
                data={
                    "dry_run": True,
                    "target": str(target),
                    "slug": slug,
                    "sha256": sha256,
                    "tokens_to_write": populated_stems,
                    "previews_found": _list_files(paths["preview"]),
                    "slides_found": _list_files(paths["slides"]),
                    "uploads_found": _list_files(paths["uploads"]),
                },
            )

        target.mkdir(parents=True, exist_ok=True)

        # theme.md (already passed voice-header check).
        try:
            shutil.copy2(paths["theme_md"], target / "theme.md")
        except OSError as e:
            return err("cannot write theme.md: {}".format(e))

        # tokens/*.json + tokens.css
        tokens_dir = target / "tokens"
        try:
            write_tokens(tokens_dir, projected)
            css_bytes = regenerate_tokens_css(tokens_dir)
        except (OSError, RuntimeError) as e:
            return err("token materialisation failed: {}".format(e))

        # components and assets.
        try:
            components_report = copy_components(paths["preview"], target / "components")
            deck_files = copy_slides(paths["slides"], target / "components")
            asset_files = copy_assets(paths["uploads"], target / "assets")
        except OSError as e:
            return err("component/asset copy failed: {}".format(e))

        # manifest.json
        manifest = build_manifest(
            slug,
            {
                "tokens": bool(populated_stems),
                "assets": bool(asset_files),
                "components_web": bool(components_report["web"]),
                "components_deck": bool(deck_files),
            },
        )
        try:
            write_manifest(target, manifest)
        except OSError as e:
            return err("cannot write manifest.json: {}".format(e))

        # Validate before sidecar.
        ok, payload = run_validator(target)
        if not ok:
            return err(
                "validate-theme-manifest.py rejected the materialised theme: {}".format(
                    json.dumps(payload, ensure_ascii=False)
                )
            )

        # Sidecar last.
        try:
            write_sidecar(target, source_url, sha256, bundle_root.name)
        except OSError as e:
            return err("cannot write sidecar: {}".format(e))

        return emit(
            True,
            data={
                "target": str(target),
                "slug": slug,
                "sha256": sha256,
                "manifest": manifest,
                "tokens_written": populated_stems,
                "tokens_css_bytes": css_bytes,
                "components_web": components_report["web"],
                "components_web_skipped": components_report["skipped"],
                "components_web_warnings": components_report["warnings"],
                "components_deck": deck_files,
                "assets": asset_files,
                "validator": payload,
            },
        )


def main() -> int:
    args = parse_args(sys.argv[1:])
    try:
        return run(args)
    except Exception as e:  # pragma: no cover — defensive
        return err("uncaught {}: {}".format(type(e).__name__, e))


if __name__ == "__main__":
    sys.exit(main())
