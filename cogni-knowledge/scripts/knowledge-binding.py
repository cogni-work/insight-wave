#!/usr/bin/env python3
"""
knowledge-binding.py — read/write .cogni-knowledge/binding.json

Three actions:
  --init           create a new binding manifest
  --append-project record a deposited cogni-research project
  --read           emit the current binding manifest as JSON

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import sys
import tempfile
from pathlib import Path

# Schema bumps mirror the data shape, not the plugin tag. v0.0.3 was the
# additive bump that added curator_defaults on top of v0.0.2's project_path.
# The bump to 0.1.0 landed at v0.1.0 M12 alongside plugin.json so the two
# version surfaces re-align there (no field change — a deliberate milestone
# re-alignment per references/absorption-roadmap.md M12). 0.1.1 is the next
# additive bump — it adds research_defaults (knowledge-base-level market +
# output_language inherited by knowledge-plan; #309 P1.2-rest). Pre-0.1.1
# bindings have no research_defaults; consumers MUST read it with
# .get("research_defaults", DEFAULT_RESEARCH_DEFAULTS).
SCHEMA_VERSION = "0.1.1"
BINDING_DIRNAME = ".cogni-knowledge"
BINDING_FILENAME = "binding.json"
FETCH_CACHE_DIRNAME = "fetch-cache"
WIKI_DIRNAME = ".cogni-wiki"
WIKI_CONFIG_FILENAME = "config.json"
VALID_REPORT_SOURCES = {"web", "local", "wiki", "hybrid"}
DEFAULT_CURATOR_DEFAULTS = {
    "max_candidates_per_sq": 12,
    "score_threshold": 0.5,
    "fetch_cache_max_age_days": 30,
}
# research_defaults (schema 0.1.1, #309 P1.2-rest) records the knowledge
# base's default market + output language so every knowledge-plan run
# inherits them instead of re-deriving (or silently defaulting English on a
# German base). An output concern, not a curator one — kept as a sibling
# block. knowledge-plan's resolution precedence: explicit flag > this block >
# the market's registry default_output_language > "en".
DEFAULT_RESEARCH_DEFAULTS = {
    "market": "dach",
    "output_language": "en",
}


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _binding_path(knowledge_root: Path) -> Path:
    return knowledge_root / BINDING_DIRNAME / BINDING_FILENAME


def _today() -> str:
    return _dt.date.today().isoformat()


def _read_binding(knowledge_root: Path) -> dict:
    bp = _binding_path(knowledge_root)
    if not bp.is_file():
        raise FileNotFoundError(f"binding not found at {bp}")
    with bp.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def _write_binding(knowledge_root: Path, payload: dict) -> Path:
    # Mirrors cogni-wiki/_wikilib.atomic_write semantics — tempfile.mkstemp
    # so concurrent writers cannot collide on a predictable `.tmp` suffix,
    # and the temp file is unlinked on exception.
    bp = _binding_path(knowledge_root)
    bp.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{bp.name}.", suffix=".tmp", dir=str(bp.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        os.replace(tmp, bp)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    return bp


def cmd_init(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    wiki_path = Path(args.wiki_path).resolve()

    if not knowledge_root.is_dir():
        return _emit(False, error=f"knowledge_root does not exist: {knowledge_root}")
    if not wiki_path.is_dir():
        return _emit(False, error=f"wiki_path does not exist: {wiki_path}")

    bp = _binding_path(knowledge_root)
    if bp.is_file():
        existing = json.loads(bp.read_text(encoding="utf-8"))
        return _emit(
            False,
            data={"existing": existing, "path": str(bp)},
            error="binding already exists at the target; refusing to overwrite",
        )

    wiki_config = wiki_path / WIKI_DIRNAME / WIKI_CONFIG_FILENAME
    if not wiki_config.is_file():
        return _emit(
            False,
            error=(
                f"wiki_path is not a cogni-wiki (missing {wiki_config}). "
                "Run cogni-wiki:wiki-setup first or fix the path."
            ),
        )

    # wiki_slug is the live truth — resolved from .cogni-wiki/config.json
    # at every consumer, never cached here. Single source of truth lives
    # upstream; caching would drift if the user renames the wiki.
    #
    # The fetch-cache lives at <knowledge_root>/.cogni-knowledge/fetch-cache/
    # by convention (documented in references/fetch-cache-design.md). The path
    # is fully derivable from knowledge_root so it is not echoed into the
    # binding — consumers compute it the same way fetch-cache.py does.
    (knowledge_root / BINDING_DIRNAME / FETCH_CACHE_DIRNAME).mkdir(parents=True, exist_ok=True)
    payload = {
        "knowledge_slug": args.knowledge_slug,
        "knowledge_title": args.knowledge_title,
        "wiki_path": str(wiki_path),
        "research_projects": [],
        "topic_lineage": {"covered_themes": [], "open_themes": []},
        "curator_defaults": dict(DEFAULT_CURATOR_DEFAULTS),
        "research_defaults": {
            "market": args.market or DEFAULT_RESEARCH_DEFAULTS["market"],
            "output_language": (
                args.output_language or DEFAULT_RESEARCH_DEFAULTS["output_language"]
            ),
        },
        "created": _today(),
        "schema_version": SCHEMA_VERSION,
    }
    written = _write_binding(knowledge_root, payload)
    return _emit(True, data={"path": str(written), "binding": payload})


def cmd_append_project(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()

    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")

    if args.knowledge_slug and binding.get("knowledge_slug") != args.knowledge_slug:
        return _emit(
            False,
            data={"binding_slug": binding.get("knowledge_slug")},
            error=(
                f"knowledge_slug mismatch: binding has '{binding.get('knowledge_slug')}', "
                f"caller passed '{args.knowledge_slug}'"
            ),
        )

    if args.report_source not in VALID_REPORT_SOURCES:
        return _emit(
            False,
            error=(
                f"invalid --report-source '{args.report_source}'; "
                f"must be one of {sorted(VALID_REPORT_SOURCES)}"
            ),
        )

    projects = binding.setdefault("research_projects", [])
    existing_idx = next(
        (i for i, p in enumerate(projects) if p.get("slug") == args.research_slug),
        None,
    )

    entry = {
        "slug": args.research_slug,
        "deposited_at": args.deposited_at or _today(),
        "report_path": str(Path(args.report_path).resolve()) if args.report_path else "",
        "report_source": args.report_source,
        "project_path": str(Path(args.project_path).resolve()) if args.project_path else "",
    }

    if existing_idx is not None:
        if not args.allow_update:
            return _emit(
                False,
                data={"existing_slug": args.research_slug},
                error="research_slug already recorded in this binding; refusing to duplicate",
            )
        # In-place update so the array's ordering is preserved (downstream
        # readers like knowledge-dashboard surface projects by index order).
        previous = projects[existing_idx]
        projects[existing_idx] = entry
        written = _write_binding(knowledge_root, binding)
        return _emit(
            True,
            data={
                "path": str(written),
                "updated": entry,
                "previous": previous,
                "research_projects_count": len(projects),
            },
        )

    projects.append(entry)
    written = _write_binding(knowledge_root, binding)
    return _emit(
        True,
        data={
            "path": str(written),
            "appended": entry,
            "research_projects_count": len(projects),
        },
    )


def cmd_read(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")
    return _emit(True, data={"binding": binding, "path": str(_binding_path(knowledge_root))})


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read/write .cogni-knowledge/binding.json",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_init = sub.add_parser("init", help="Create a new binding manifest")
    p_init.add_argument("--knowledge-root", required=True)
    p_init.add_argument("--knowledge-slug", required=True)
    p_init.add_argument("--knowledge-title", required=True)
    p_init.add_argument("--wiki-path", required=True)
    p_init.add_argument(
        "--market",
        required=False,
        default="",
        help="Default market for this knowledge base (research_defaults.market). "
             "Falls back to 'dach' when omitted.",
    )
    p_init.add_argument(
        "--output-language",
        required=False,
        default="",
        help="Default output language for this knowledge base "
             "(research_defaults.output_language). Falls back to 'en' when omitted.",
    )
    p_init.set_defaults(func=cmd_init)

    p_append = sub.add_parser("append-project", help="Record a deposited research project")
    p_append.add_argument("--knowledge-root", required=True)
    p_append.add_argument("--knowledge-slug", required=False, default="")
    p_append.add_argument("--research-slug", required=True)
    p_append.add_argument("--report-path", required=False, default="")
    p_append.add_argument(
        "--project-path",
        required=False,
        default="",
        help=(
            "Absolute path to the cogni-research project root (the dir "
            "that contains .metadata/project-config.json). Optional but "
            "recommended — cycle-guard prefers it over deriving the project "
            "dir from report_path.parent.parent."
        ),
    )
    p_append.add_argument("--report-source", required=True, choices=sorted(VALID_REPORT_SOURCES))
    p_append.add_argument("--deposited-at", required=False, default="")
    p_append.add_argument(
        "--allow-update",
        action="store_true",
        help=(
            "On duplicate research_slug, update the existing entry in place "
            "instead of refusing. Used by knowledge-finalize --overwrite to "
            "keep the binding's report_path / deposited_at fresh when "
            "re-depositing a refined draft."
        ),
    )
    p_append.set_defaults(func=cmd_append_project)

    p_read = sub.add_parser("read", help="Emit the binding manifest")
    p_read.add_argument("--knowledge-root", required=True)
    p_read.set_defaults(func=cmd_read)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
