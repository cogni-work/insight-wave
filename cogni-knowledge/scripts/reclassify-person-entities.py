#!/usr/bin/env python3
"""
reclassify-person-entities.py — one-shot legacy person-entity reclassifier.

The first-class `person` page type (`wiki/people/`, `type: person`) split named
humans out of the catch-all `entity` type — for NEW pages. Pre-existing named
humans still sit as `type: entity` under `wiki/entities/`. This operator driver
migrates them:

  1. DRY RUN (default): walk `wiki/entities/*.md` and surface a CANDIDATE list
     via a deliberately conservative person-vs-org heuristic (title of 2-4
     capitalized tokens, no digits, no org-marker token). The heuristic is a
     review surface, never an actor — a bare-name company is exactly the false
     positive that must not move silently.
  2. APPLY: `--apply` requires an explicit selector — `--slugs a,b,c` (the
     authoritative operator/LLM-judgment channel) or `--all-candidates` (an
     explicit opt-in to the heuristic set). Per selected page, under the
     vendored `_wiki_lock`: verify `type: entity`, surgically rewrite that one
     frontmatter line to `type: person` (rest byte-for-byte preserved), and
     `os.replace` the file into `wiki/people/<slug>.md`, refusing to clobber
     an existing target.
  3. Re-render the `entities` + `people` sub-indexes (`sub_index.py render`)
     and the curated root MAP (`root_index.py render`) so index presence
     re-files. The renderers self-lock, so the move lock is RELEASED first
     (the migrate-layout.py precedent). `wiki_index_update.py --move-slug` is
     intentionally NOT used: the curated root carries no per-page bullets.

Requires `schema_version >= 0.0.8` (the curated layout — the sub-indexes this
script re-files through exist only there); a pre-curated base is refused with
a pointer to `knowledge-index --migrate`. `entries_count` is unchanged (same
total page count), so no config bump is needed.

Idempotent: re-running with the same `--slugs` finds the source gone and the
target present and reports a clean noop. Non-destructive: never deletes a
page, never overwrites an existing `wiki/people/` page.

Run once by an operator post-deploy; the live-base run is intentionally not
part of the PR diff (the `migrate-question-index.py` / `backfill_concepts_index.py`
posture).

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.9+.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write_text,
    meta_dir,
    resolve_wiki_scripts,
)
from sub_index import _import_wiki_lock  # noqa: E402

# The curated layout this script re-files through.
MIN_SCHEMA = "0.0.8"

# Title tokens that mark an organization, not a person. Conservative and
# case-insensitive; a hit anywhere in the title disqualifies the candidate.
ORG_MARKERS = frozenset({
    "gmbh", "ag", "se", "kg", "ohg", "ug", "inc", "inc.", "ltd", "ltd.",
    "llc", "plc", "corp", "corp.", "co", "co.", "sa", "s.a.", "bv", "b.v.",
    "institut", "institute", "universität", "universitaet", "university",
    "hochschule", "kommission", "commission", "agentur", "agency",
    "verband", "association", "behörde", "behoerde", "ministerium",
    "ministry", "bundesamt", "amt", "stiftung", "foundation", "verein",
    "group", "gruppe", "holding", "partners", "consulting", "solutions",
    "systems", "software", "technologies", "labs", "council", "committee",
    "authority", "office", "bank", "fonds", "fund",
})

# Lowercase name particles allowed mid-name (von Neumann, van der Sar, ...).
NAME_PARTICLES = frozenset({
    "von", "van", "de", "der", "den", "del", "della", "di", "da", "la",
    "le", "al", "bin", "ibn", "mac", "ten", "ter", "zu",
})

_TYPE_LINE_RE = re.compile(r"^(type\s*:\s*)entity\s*$", re.M)
_TITLE_LINE_RE = re.compile(r"^title\s*:\s*(.+?)\s*$", re.M)
_FM_BLOCK_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.S)


def _emit(success: bool, data: "dict | None" = None, error: str = "") -> int:
    print(json.dumps(
        {"success": bool(success), "data": data or {}, "error": error or ""},
        indent=2, ensure_ascii=False,
    ))
    return 0 if success else 1


def _version_tuple(version: str) -> "tuple[int, ...]":
    parts = []
    for chunk in (version or "").strip().split("."):
        try:
            parts.append(int(chunk))
        except ValueError:
            parts.append(0)
    return tuple(parts) or (0,)


def _read_schema_version(wiki_root: Path) -> "tuple[str, str]":
    config_path = wiki_root / ".cogni-wiki" / "config.json"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except OSError as exc:
        return "", f"config.json unreadable: {exc}"
    except ValueError as exc:
        return "", f"config.json is not valid JSON: {exc}"
    return str(config.get("schema_version", "")), ""


def _frontmatter(text: str) -> str:
    m = _FM_BLOCK_RE.match(text)
    return m.group(1) if m else ""


def _title_of(fm: str, slug: str) -> str:
    m = _TITLE_LINE_RE.search(fm)
    if not m:
        return slug.replace("-", " ")
    return m.group(1).strip().strip('"').strip("'")


def _looks_like_person(title: str) -> "tuple[bool, str]":
    """Conservative person heuristic. Returns (is_candidate, reason)."""
    tokens = title.split()
    if not 2 <= len(tokens) <= 4:
        return False, f"{len(tokens)} title token(s) (want 2-4)"
    lowered = [t.lower().strip(",()") for t in tokens]
    for t in lowered:
        if t in ORG_MARKERS:
            return False, f"org marker '{t}'"
    if any(ch.isdigit() for ch in title):
        return False, "title contains digits"
    if "&" in title or "+" in title:
        return False, "conjunction symbol (org pattern)"
    for raw, low in zip(tokens, lowered):
        if low in NAME_PARTICLES:
            continue
        if not raw[0].isupper():
            return False, f"lowercase token '{raw}'"
        if len(raw) > 1 and raw.isupper():
            return False, f"acronym token '{raw}' (org pattern)"
    return True, "2-4 capitalized name tokens, no org markers"


def _run_renderer(own_dir: Path, script: str, args: "list[str]") -> "tuple[bool, str]":
    proc = subprocess.run(
        [sys.executable, str(own_dir / script)] + args,
        capture_output=True, text=True, timeout=120,
    )
    try:
        result = json.loads(proc.stdout)
    except ValueError:
        return False, (proc.stderr or "unparseable renderer output").strip()[:300]
    if not result.get("success"):
        return False, result.get("error", "renderer_failed")
    return True, ""


def cmd_reclassify(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root).expanduser().resolve()
    entities_dir = wiki_root / "wiki" / "entities"
    people_dir = wiki_root / "wiki" / "people"
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")

    schema, err = _read_schema_version(wiki_root)
    if err:
        return _emit(False, error=err)
    if _version_tuple(schema) < _version_tuple(MIN_SCHEMA):
        return _emit(False, error=(
            f"schema_version {schema!r} predates the curated layout "
            f"({MIN_SCHEMA}) whose sub-indexes this script re-files through — "
            f"run knowledge-index --migrate first"
        ))

    # Candidate scan (always — the dry-run review surface).
    candidates: "list[dict]" = []
    non_candidates: "list[dict]" = []
    if entities_dir.is_dir():
        for path in sorted(entities_dir.glob("*.md")):
            if path.name == "index.md":
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except OSError as exc:
                non_candidates.append({"slug": path.stem, "reason": f"unreadable: {exc}"})
                continue
            fm = _frontmatter(text)
            if not _TYPE_LINE_RE.search(fm):
                non_candidates.append({"slug": path.stem, "reason": "not type: entity"})
                continue
            title = _title_of(fm, path.stem)
            is_person, reason = _looks_like_person(title)
            entry = {"slug": path.stem, "title": title, "reason": reason}
            (candidates if is_person else non_candidates).append(entry)

    data: dict = {
        "wiki_root": str(wiki_root),
        "schema_version": schema,
        "applied": bool(args.apply),
        "candidates": candidates,
        "non_candidates_count": len(non_candidates),
        "moved": [],
        "skipped": [],
        "rendered": [],
    }

    if not args.apply:
        data["action"] = "dry_run"
        data["non_candidates"] = non_candidates
        return _emit(True, data=data)

    # --apply requires an explicit selector — the heuristic never acts alone.
    if args.slugs:
        selected = [s.strip() for s in args.slugs.split(",") if s.strip()]
    elif args.all_candidates:
        selected = [c["slug"] for c in candidates]
    else:
        return _emit(False, data=data, error=(
            "--apply requires an explicit selector: --slugs a,b,c (review the "
            "dry-run candidates first) or --all-candidates"
        ))
    if not selected:
        data["action"] = "noop"
        return _emit(True, data=data)

    if args.wiki_scripts_dir:
        wiki_scripts = Path(args.wiki_scripts_dir).expanduser().resolve()
    else:
        try:
            wiki_scripts = resolve_wiki_scripts(
                "wiki-ingest", expected_script="_wikilib.py"
            )
        except FileNotFoundError as exc:
            return _emit(False, error=str(exc))
    wiki_lock, lock_err = _import_wiki_lock(str(wiki_scripts))
    if lock_err:
        return _emit(False, error=lock_err)

    failures: "list[str]" = []
    with wiki_lock(wiki_root):
        people_dir.mkdir(parents=True, exist_ok=True)
        for slug in selected:
            src = entities_dir / f"{slug}.md"
            dst = people_dir / f"{slug}.md"
            if not src.is_file():
                if dst.is_file():
                    data["skipped"].append({"slug": slug, "reason": "already_reclassified"})
                else:
                    data["skipped"].append({"slug": slug, "reason": "source_absent"})
                    failures.append(f"{slug}: no such entity page")
                continue
            if dst.exists():
                data["skipped"].append({"slug": slug, "reason": "target_exists"})
                failures.append(f"{slug}: wiki/people/{slug}.md already exists (no clobber)")
                continue
            text = src.read_text(encoding="utf-8")
            fm = _frontmatter(text)
            if not _TYPE_LINE_RE.search(fm):
                data["skipped"].append({"slug": slug, "reason": "not_type_entity"})
                failures.append(f"{slug}: frontmatter type is not 'entity'")
                continue
            # Surgical retype confined to the frontmatter block.
            new_fm = _TYPE_LINE_RE.sub(r"\g<1>person", fm, count=1)
            new_text = text.replace(fm, new_fm, 1)
            atomic_write_text(src, new_text)
            os.replace(src, dst)
            data["moved"].append({"slug": slug, "from": str(src), "to": str(dst)})

    if failures:
        data["action"] = "partial" if data["moved"] else "refused"
        # Renders still run when something moved, so the indexes match disk.
    if data["moved"]:
        own_dir = Path(__file__).resolve().parent
        for script, render_args in (
            ("sub_index.py", ["render", "--type", "entities"]),
            ("sub_index.py", ["render", "--type", "people"]),
            ("root_index.py", ["render"]),
        ):
            ok_, rerr = _run_renderer(
                own_dir, script,
                render_args + ["--wiki-root", str(wiki_root),
                               "--wiki-scripts-dir", str(wiki_scripts)],
            )
            data["rendered"].append({
                "target": f"{script} {' '.join(render_args)}",
                "ok": ok_, **({"error": rerr} if not ok_ else {}),
            })
            if not ok_:
                return _emit(False, data=data, error=f"index render failed: {rerr}")
        try:
            log_file = meta_dir(wiki_root) / "log.md"
            if log_file.is_file():
                stamp = _dt.date.today().isoformat()
                with log_file.open("a", encoding="utf-8") as fh:
                    fh.write(
                        f"\n## [{stamp}] reclassify | {len(data['moved'])} "
                        f"entity page(s) reclassified to person (wiki/people/)\n"
                    )
        except OSError:
            pass  # observability only

    if failures:
        return _emit(False, data=data, error="; ".join(failures))
    data["action"] = "reclassified" if data["moved"] else "noop"
    return _emit(True, data=data)


def main(argv: "list[str]") -> int:
    parser = argparse.ArgumentParser(
        description=(
            "One-shot reclassifier: move named-human type:entity pages into "
            "wiki/people/ as type:person. Dry-run by default; --apply requires "
            "--slugs or --all-candidates."
        ),
        allow_abbrev=False,
    )
    parser.add_argument("--wiki-root", required=True,
                        help="Wiki root (the dir containing wiki/ and .cogni-wiki/).")
    parser.add_argument("--wiki-scripts-dir",
                        help="Override the cogni-wiki wiki-ingest scripts dir "
                             "(self-resolves vendored-first when omitted).")
    parser.add_argument("--apply", action="store_true",
                        help="Execute the moves (requires --slugs or --all-candidates).")
    parser.add_argument("--slugs",
                        help="Comma-separated entity slugs to reclassify — the "
                             "authoritative selector; review the dry-run candidates first.")
    parser.add_argument("--all-candidates", action="store_true",
                        help="Explicit opt-in: act on every heuristic candidate.")
    args = parser.parse_args(argv)
    return cmd_reclassify(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
