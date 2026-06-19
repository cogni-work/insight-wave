#!/usr/bin/env python3
"""
migrate-layout.py — one-shot curated-layout migration for an EXISTING wiki
(schema_version 0.0.7 → 0.0.8).

`knowledge-setup` seeds the curated, progressively-disclosed layout for NEW
wikis only. This driver converges an old-structure base onto the same shape so
the curated layout reaches wikis that already exist:

  1. Relocate the visible control files from the flat `wiki/` root into
     `wiki/meta/` — `log.md`, `context_brief.md`, `open_questions.md` — via
     `os.replace` (atomic, same filesystem). A file already under `meta/` (or
     absent) is skipped, so a partial prior migration is converged, not broken.
  2. Fold `wiki/overview.md`'s `MACHINE-OWNED:OVERVIEW-NARRATIVE` block into the
     `wiki/index.md` intro (the curated front door owns the narrative now), and
     retire the block in `overview.md` to a pointer stub line. Everything else
     in `overview.md` — the `## Recent syntheses` running list, human prose —
     is preserved byte-for-byte (relocate, never delete).
  3. Render the six per-type sub-indexes (`sub_index.py render --type <t>`),
     then re-render the root as the curated MAP (`root_index.py render`). The
     root split is the lossy transform: the renderer carries every
     `MACHINE-OWNED:PORTAL-LEADIN` span AND every human (non-sentineled)
     lead-in verbatim, dropping only the per-page `- [[slug]]` bullets (they
     live in the sub-indexes rendered first) — the migrator inherits that
     preservation guarantee by delegating, never re-implementing the split.
  4. Bump `.cogni-wiki/config.json::schema_version` to `0.0.8` via the vendored
     locked `config_bump.py --set-string` (the same call `knowledge-setup`
     Step 3.5(e) makes), and append one best-effort `migrate` line to the log.

Dry-run is the DEFAULT; `--apply` is required to move files, write pages, or
bump the schema. The dry run emits a **content diff surface**, not just a
file-move list: it stages the proposed root MAP + all seven sub-indexes to
`<wiki-root>/.cogni-wiki/*-proposed.md` (lock-free `stage` subcommands, live
pages untouched) so a reviewer can diff exactly what the split would produce.
The staged root is built from the PRE-fold index, so the narrative fold is
reported separately in the envelope rather than reflected in the staged text.

Idempotent: a base already at `schema_version >= 0.0.8` with nothing
misplaced exits early with `action: noop` / `reason: already_migrated`; a
second `--apply` run is a clean no-op. When a control file has REAPPEARED at
the flat wiki/ root on an already-curated base (the case health.py's
curated_layout_violation flags), the noop gate splits to a relocate-only
path: just the locked control-file moves run (`action: relocated`, schema
untouched, no overview fold, no renders) — this is what makes
`knowledge-lint --fix=misplaced_control_files`'s delegation effective on
post-migration bases. Locking: the relocation + fold phase runs under cogni-wiki's canonical
`_wiki_lock` (imported from `_wikilib`, never re-inlined); the lock is RELEASED
before the renderer subprocesses run, because each renderer takes the same
flock itself and a held parent lock would deadlock the child. `config_bump.py`
locks its own write.

`_CANONICAL_META` in `_knowledge_lib` stays False — the write-side flip is a
separate coordinated change; migration works today because every reader
resolves `wiki/meta/<file>` first when it exists (the read-side fallback).

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
    extract_machine_block,
    meta_dir,
    resolve_wiki_scripts,
    upsert_machine_block,
)
from sub_index import REGISTRY, _import_wiki_lock  # noqa: E402

TARGET_SCHEMA = "0.0.8"
# The current engine schema. `--repair` reconciles a lagging already-curated
# base up to this (the curated layout + the first-class person type), the same
# value knowledge-setup seeds for a new base.
ENGINE_SCHEMA = "0.0.9"
# Pre-per-type-dirs bases (< 0.0.5) hard-fail across the plugin; this migrator
# only bridges the curated-layout gap, not the page-directory cutover.
FLOOR_SCHEMA = "0.0.5"

CONTROL_FILES = ("log.md", "context_brief.md", "open_questions.md")

# A degraded curated front door: a per-theme ROOT-LINKS machine span whose
# inner text is the empty-state sentinel — the same signal health.py's
# structural_drift check keys on. root_index.py owns both the span name and the
# sentinel string; re-stated here only as the drift-detection needle (the regen
# itself delegates to root_index.py render, never re-implements the link build).
ROOT_LINKS_EMPTY_SENTINEL = "_(no pages yet)_"
_ROOT_LINKS_SPAN_RE = re.compile(
    r"<!--\s*MACHINE-OWNED:ROOT-LINKS:START\s*-->(.*?)"
    r"<!--\s*MACHINE-OWNED:ROOT-LINKS:END\s*-->",
    re.DOTALL,
)

OVERVIEW_NARRATIVE_NAME = "OVERVIEW-NARRATIVE"
OVERVIEW_STUB_LINE = (
    "_The overview narrative now lives in the curated map intro at "
    "[index.md](index.md). This page keeps the running `## Recent syntheses` "
    "list._"
)
# A whole MACHINE-OWNED:OVERVIEW-NARRATIVE span including its sentinels —
# removed from overview.md after the inner text relocates to index.md.
_OVERVIEW_SPAN_RE = re.compile(
    r"\n?[ \t]*<!--\s*MACHINE-OWNED:" + OVERVIEW_NARRATIVE_NAME + r":START\s*-->.*?"
    r"<!--\s*MACHINE-OWNED:" + OVERVIEW_NARRATIVE_NAME + r":END\s*-->[ \t]*\n?",
    re.DOTALL,
)


def _emit(success: bool, data: "dict | None" = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _version_tuple(version: str) -> "tuple[int, ...]":
    parts = []
    for chunk in (version or "").strip().split("."):
        try:
            parts.append(int(chunk))
        except ValueError:
            parts.append(0)
    return tuple(parts) or (0,)


def _is_version_at_least(have: str, target: str) -> bool:
    return _version_tuple(have) >= _version_tuple(target)


def _read_schema_version(wiki_root: Path) -> "tuple[str, str]":
    """Return (schema_version, error). Empty error on success."""
    config_path = wiki_root / ".cogni-wiki" / "config.json"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except OSError as exc:
        return "", f"config.json unreadable: {exc}"
    except ValueError as exc:
        return "", f"config.json is not valid JSON: {exc}"
    return str(config.get("schema_version", "")), ""


def _plan_control_moves(wiki_root: Path) -> "list[dict]":
    """One record per control file: what the relocation would (or did) do."""
    plans = []
    meta = meta_dir(wiki_root)
    for name in CONTROL_FILES:
        src = wiki_root / "wiki" / name
        dst = meta / name
        if dst.exists():
            action = "skip_target_exists" if src.exists() else "skip_already_migrated"
        elif not src.exists():
            action = "skip_source_absent"
        else:
            action = "move"
        plans.append({"file": name, "src": str(src), "dst": str(dst), "action": action})
    return plans


def _resolve_scripts(args: argparse.Namespace) -> "tuple[Path | None, str]":
    """Resolve the cogni-wiki wiki-ingest scripts dir (override or probe)."""
    if args.wiki_scripts_dir:
        return Path(args.wiki_scripts_dir).expanduser().resolve(), ""
    try:
        return resolve_wiki_scripts(
            "wiki-ingest", expected_script="config_bump.py"
        ), ""
    except FileNotFoundError as exc:
        return None, str(exc)


def _apply_control_moves(wiki_root: Path, moves: "list[dict]") -> None:
    """Execute the planned control-file moves in place. Caller holds the
    wiki lock. Each plan's `action` advances move -> moved / move_failed."""
    meta_dir(wiki_root).mkdir(parents=True, exist_ok=True)
    for plan in moves:
        if plan["action"] != "move":
            continue
        try:
            os.replace(plan["src"], plan["dst"])
            plan["action"] = "moved"
        except OSError as exc:
            plan["action"] = "move_failed"
            plan["error"] = str(exc)


def _move_failures_error(data: dict, moves: "list[dict]") -> "int | None":
    failures = [p for p in moves if p["action"] == "move_failed"]
    if failures:
        return _emit(False, data=data, error=(
            "control-file relocation failed: "
            + ", ".join(p["file"] for p in failures)
        ))
    return None


def _append_migrate_log(wiki_root: Path, line: str) -> None:
    """Best-effort dated log append (meta-first, flat-root fallback)."""
    try:
        log_file = meta_dir(wiki_root) / "log.md"
        if not log_file.is_file():
            log_file = wiki_root / "wiki" / "log.md"
        if log_file.is_file():
            stamp = _dt.date.today().isoformat()
            with log_file.open("a", encoding="utf-8") as fh:
                fh.write(f"\n## [{stamp}] {line}\n")
    except OSError:
        pass  # observability only — never fail the migration on a log write


def _fold_overview(wiki_root: Path, apply: bool) -> dict:
    """Relocate overview.md's OVERVIEW-NARRATIVE inner into index.md's intro.

    Non-destructive: only the machine-owned span moves; the `## Recent
    syntheses` list and any human prose in overview.md stay byte-for-byte. The
    span in overview.md is replaced by a one-line pointer stub (inserted after
    the H1 only when no stub is present yet).
    """
    overview_path = wiki_root / "wiki" / "overview.md"
    index_path = wiki_root / "wiki" / "index.md"
    if not overview_path.is_file():
        return {"action": "skip_no_overview"}
    try:
        overview_text = overview_path.read_text(encoding="utf-8")
    except OSError as exc:
        return {"action": "skip_unreadable", "error": str(exc)}
    inner = extract_machine_block(overview_text, OVERVIEW_NARRATIVE_NAME)
    if inner is None:
        return {"action": "skip_no_narrative_block"}
    if not apply:
        return {"action": "would_fold", "narrative_chars": len(inner)}

    index_text = ""
    if index_path.is_file():
        index_text = index_path.read_text(encoding="utf-8")
    new_index = upsert_machine_block(index_text, OVERVIEW_NARRATIVE_NAME, inner)
    if new_index != index_text:
        atomic_write_text(index_path, new_index)

    stripped = _OVERVIEW_SPAN_RE.sub("", overview_text)
    if OVERVIEW_STUB_LINE not in stripped:
        lines = stripped.splitlines(keepends=True)
        insert_at = 0
        for i, line in enumerate(lines):
            if line.lstrip().startswith("# "):
                insert_at = i + 1
                if insert_at < len(lines) and lines[insert_at].strip() == "":
                    insert_at += 1
                break
        lines.insert(insert_at, "\n" + OVERVIEW_STUB_LINE + "\n")
        stripped = "".join(lines)
    if stripped != overview_text:
        atomic_write_text(overview_path, stripped)
    return {"action": "folded", "narrative_chars": len(inner)}


def _run_renderer(script_dir: Path, script: str, args: "list[str]") -> "tuple[bool, dict]":
    """Run a sibling renderer (sub_index.py / root_index.py) and parse its envelope."""
    proc = subprocess.run(
        [sys.executable, str(script_dir / script)] + args,
        capture_output=True,
        text=True,
    )
    try:
        result = json.loads(proc.stdout)
    except ValueError:
        return False, {
            "error": "unparseable_output",
            "stderr": (proc.stderr or "").strip()[:500],
        }
    if not result.get("success"):
        return False, {"error": result.get("error", "renderer_failed")}
    return True, result.get("data") or {}


def _relocate_only(
    wiki_root: Path,
    args: argparse.Namespace,
    schema_before: str,
    moves: "list[dict]",
    *,
    conflicts: "list[dict]",
    fold_pending: bool,
    meta_missing: bool,
) -> int:
    """Post-migration curated-layout repair (schema already >= 0.0.8).

    Repairs exactly what the curated-layout health check can flag on an
    already-curated base: misplaced flat-root control files (locked moves),
    a missing wiki/meta/ (recreated), and a reappeared overview narrative
    block (folded via the same idempotent _fold_overview the migration
    uses). No index renders, no schema bump. A control file existing at
    BOTH locations is surfaced as a conflict (success false) and never
    auto-clobbered. Idempotent: a clean re-run reaches the caller's noop.
    """
    data: dict = {
        "wiki_root": str(wiki_root),
        "applied": bool(args.apply),
        "schema_before": schema_before,
        "schema_after": schema_before,
        "control_files": moves,
        "conflicts": [p["file"] for p in conflicts],
        "overview_fold_pending": fold_pending,
        "meta_missing": meta_missing,
    }
    if not args.apply:
        data["action"] = "dry_run"
        data["reason"] = "relocate_pending"
        return _emit(True, data=data)

    wiki_scripts, err = _resolve_scripts(args)
    if err:
        return _emit(False, error=err)
    wiki_lock, lock_err = _import_wiki_lock(str(wiki_scripts))
    if lock_err:
        return _emit(False, error=lock_err)

    with wiki_lock(wiki_root):
        meta_dir(wiki_root).mkdir(parents=True, exist_ok=True)
        _apply_control_moves(wiki_root, moves)
        data["overview_fold"] = (
            _fold_overview(wiki_root, apply=True)
            if fold_pending else {"action": "skip_no_narrative_block"}
        )
    failed = _move_failures_error(data, moves)
    if failed is not None:
        return failed

    moved_n = sum(1 for p in moves if p["action"] == "moved")
    repairs = []
    if moved_n:
        repairs.append(f"relocated {moved_n} control file(s)")
    if meta_missing:
        repairs.append("recreated wiki/meta/")
    if fold_pending:
        repairs.append("folded the overview narrative")
    if repairs:
        _append_migrate_log(
            wiki_root,
            f"migrate | curated-layout repair: {', '.join(repairs)} "
            f"(schema {schema_before} unchanged)",
        )
    if conflicts:
        names = ", ".join(p["file"] for p in conflicts)
        data["action"] = "conflicts"
        return _emit(False, data=data, error=(
            f"control-file conflict(s): {names} exist at BOTH the flat "
            f"wiki/ root and wiki/meta/ — compare the two copies and remove "
            f"one manually (never auto-clobbered)"
        ))
    data["action"] = "relocated"
    return _emit(True, data=data)


def _root_links_drifted(wiki_root: Path) -> "tuple[bool, str]":
    """True when wiki/index.md has any empty-sentinel ROOT-LINKS span.

    Mirrors health.py's structural_drift ROOT-LINKS check: a per-theme
    `MACHINE-OWNED:ROOT-LINKS` span whose inner text stripped equals the
    empty-state sentinel means the curated front door was never (re)populated
    with theme-scoped deep links. Returns (drifted, error).
    """
    index_path = wiki_root / "wiki" / "index.md"
    try:
        index_text = index_path.read_text(encoding="utf-8")
    except OSError as exc:
        return False, f"index.md unreadable: {exc}"
    for inner in _ROOT_LINKS_SPAN_RE.findall(index_text):
        if inner.strip() == ROOT_LINKS_EMPTY_SENTINEL:
            return True, ""
    return False, ""


def cmd_repair(args: argparse.Namespace) -> int:
    """Regenerate drifted machine-owned regions on an already-curated base.

    The repair counterpart to the version-floored migration: keyed on the
    structural-drift class health.py emits (not the schema floor), it
    regenerates the theme-scoped ROOT-LINKS region via root_index.py render
    and reconciles a lagging schema_version up to ENGINE_SCHEMA. Dry-run by
    default (stages the proposed root MAP as a diff surface); --apply writes
    under the renderer's own lock. Idempotent: a non-drifted, current-schema
    base reaches action:noop; a second --apply is a clean no-op.

    Scope boundary: root_index.py render carries the OVERVIEW-NARRATIVE block
    VERBATIM and never re-authors a bootstrap placeholder — re-authoring that
    region is the skill orchestrator's portal-narrator step (knowledge-index
    SKILL.md ### Repair mode), gated on health structural_drift findings that
    name the OVERVIEW-NARRATIVE region. This script repairs ROOT-LINKS +
    schema lag; it deliberately does not touch OVERVIEW-NARRATIVE.
    """
    wiki_root = Path(args.wiki_root).expanduser().resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")

    schema_before, err = _read_schema_version(wiki_root)
    if err:
        return _emit(False, error=err)
    # Repair operates on an already-curated base; a pre-0.0.8 base needs the
    # full layout migration first, not a region regen.
    if not _is_version_at_least(schema_before, TARGET_SCHEMA):
        return _emit(False, error=(
            f"--repair requires an already-curated base (schema >= "
            f"{TARGET_SCHEMA}); this base is at {schema_before!r} — run the "
            f"full migration via knowledge-index --migrate first"
        ))

    links_drifted, err = _root_links_drifted(wiki_root)
    if err:
        return _emit(False, error=err)
    schema_lagging = not _is_version_at_least(schema_before, ENGINE_SCHEMA)

    drifted_regions = ["ROOT-LINKS"] if links_drifted else []
    data: dict = {
        "wiki_root": str(wiki_root),
        "applied": bool(args.apply),
        "schema_before": schema_before,
        "schema_after": schema_before,
        "drifted_regions": drifted_regions,
        "schema_lagging": schema_lagging,
    }

    if not (links_drifted or schema_lagging):
        data["action"] = "noop"
        data["reason"] = "no_drift_detected"
        return _emit(True, data=data)

    own_dir = Path(__file__).resolve().parent
    wiki_scripts, err = _resolve_scripts(args)
    if err:
        return _emit(False, error=err)

    if not args.apply:
        # Dry-run: stage the proposed root MAP (lock-free; live index
        # untouched) as the content-diff surface, mirroring --migrate.
        if links_drifted:
            ok, payload = _run_renderer(
                own_dir, "root_index.py",
                ["stage", "--wiki-root", str(wiki_root)],
            )
            data["staged"] = [{
                "type": "root",
                "ok": ok,
                "path": payload.get("path", ""),
                **({"error": payload.get("error", "")} if not ok else {}),
            }]
        data["action"] = "dry_run"
        data["reason"] = "repair_pending"
        return _emit(True, data=data)

    # --- apply path -------------------------------------------------------
    # ROOT-LINKS regen: root_index.py render self-locks (no parent lock held).
    if links_drifted:
        ok, payload = _run_renderer(
            own_dir, "root_index.py",
            ["render", "--wiki-root", str(wiki_root),
             "--wiki-scripts-dir", str(wiki_scripts)],
        )
        data["rendered"] = [{
            "type": "root",
            "ok": ok,
            "changed": payload.get("changed"),
            **({"error": payload.get("error", "")} if not ok else {}),
        }]
        if not ok:
            return _emit(False, data=data, error="root MAP render failed")

    # Schema reconciliation: bump to ENGINE_SCHEMA when it lags (config_bump
    # locks its own write — same subprocess shape as cmd_migrate Phase 3).
    if schema_lagging:
        proc = subprocess.run(
            [sys.executable, str(wiki_scripts / "config_bump.py"),
             "--wiki-root", str(wiki_root),
             "--key", "schema_version", "--set-string", ENGINE_SCHEMA],
            capture_output=True,
            text=True,
        )
        try:
            bump = json.loads(proc.stdout)
        except ValueError:
            bump = {"success": False, "error": (proc.stderr or "").strip()[:500]}
        if not bump.get("success"):
            return _emit(False, data=data,
                         error=f"schema bump failed: {bump.get('error', 'unknown')}")
        data["schema_after"] = ENGINE_SCHEMA

    repairs = []
    if links_drifted:
        repairs.append("regenerated ROOT-LINKS")
    if schema_lagging:
        repairs.append(f"reconciled schema {schema_before} -> {ENGINE_SCHEMA}")
    if repairs:
        _append_migrate_log(
            wiki_root,
            f"migrate | curated-layout repair: {', '.join(repairs)}",
        )
    data["action"] = "repaired"
    return _emit(True, data=data)


def cmd_migrate(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root).expanduser().resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")

    schema_before, err = _read_schema_version(wiki_root)
    if err:
        return _emit(False, error=err)
    if _is_version_at_least(schema_before, TARGET_SCHEMA):
        # Already curated — but a control file may have reappeared at the
        # flat wiki/ root AFTER migration (an old tool, a hand copy). The
        # health check flags exactly that at schema >= 0.0.8, so the noop
        # gate splits: noop only when nothing is misplaced; otherwise run
        # the relocate-only path (control-file moves under the lock, schema
        # untouched, no overview fold, no renderer subprocesses).
        moves = _plan_control_moves(wiki_root)
        pending_moves = [p for p in moves if p["action"] == "move"]
        # A control file existing at BOTH wiki/ root and wiki/meta/ is a
        # conflict the repair must SURFACE, never silently noop past (and
        # never auto-clobber) — health keeps flagging it otherwise with no
        # visible reason.
        conflicts = [p for p in moves if p["action"] == "skip_target_exists"]
        fold_pending = _fold_overview(wiki_root, apply=False).get("action") == "would_fold"
        meta_missing = not meta_dir(wiki_root).is_dir()
        if not (pending_moves or conflicts or fold_pending or meta_missing):
            return _emit(True, data={
                "wiki_root": str(wiki_root),
                "action": "noop",
                "reason": "already_migrated",
                "schema_version": schema_before,
            })
        return _relocate_only(
            wiki_root, args, schema_before, moves,
            conflicts=conflicts, fold_pending=fold_pending,
            meta_missing=meta_missing,
        )
    if getattr(args, "relocate_only", False):
        return _emit(False, error=(
            f"--relocate-only requires an already-curated base (schema >= "
            f"{TARGET_SCHEMA}); this base is at {schema_before!r} — run the "
            f"full migration via knowledge-index --migrate"
        ))
    if not _is_version_at_least(schema_before, FLOOR_SCHEMA):
        return _emit(False, error=(
            f"schema_version {schema_before!r} predates the per-type-dirs "
            f"layout ({FLOOR_SCHEMA}); run cogni-wiki's migrate_layout.py first"
        ))

    own_dir = Path(__file__).resolve().parent
    wiki_scripts, err = _resolve_scripts(args)
    if err:
        return _emit(False, error=err)

    moves = _plan_control_moves(wiki_root)
    data: dict = {
        "wiki_root": str(wiki_root),
        "applied": bool(args.apply),
        "schema_before": schema_before,
        "schema_after": schema_before,
        "control_files": moves,
        "overview_fold": {},
        "rendered": [],
        "staged": [],
    }

    # Sub-indexes first, then the root MAP — the root's count-links must
    # point at sub-indexes that exist. Shared by the stage and render loops.
    render_targets = [
        ("sub_index.py", t, ["--type", t]) for t in sorted(REGISTRY)
    ] + [("root_index.py", "root", [])]

    if not args.apply:
        data["overview_fold"] = _fold_overview(wiki_root, apply=False)
        # Content-diff surface: stage every proposed index (lock-free, live
        # pages untouched) so a reviewer can diff the split before --apply.
        for script, label, type_args in render_targets:
            ok, payload = _run_renderer(
                own_dir, script,
                ["stage"] + type_args + ["--wiki-root", str(wiki_root)],
            )
            data["staged"].append({
                "type": label,
                "ok": ok,
                "path": payload.get("path", ""),
                **({"error": payload.get("error", "")} if not ok else {}),
            })
        data["action"] = "dry_run"
        return _emit(True, data=data)

    # --- apply path -------------------------------------------------------
    wiki_lock, lock_err = _import_wiki_lock(str(wiki_scripts))
    if lock_err:
        return _emit(False, error=lock_err)

    # Phase 1 (locked): relocate control files + fold the overview narrative.
    # The lock is released before the renderer subprocesses run — each takes
    # the same flock itself and would deadlock behind a held parent lock.
    with wiki_lock(wiki_root):
        _apply_control_moves(wiki_root, moves)
        data["overview_fold"] = _fold_overview(wiki_root, apply=True)

    failed = _move_failures_error(data, moves)
    if failed is not None:
        return failed

    # Phase 2 (renderers self-lock): same target order as the stage loop.
    for script, label, type_args in render_targets:
        ok, payload = _run_renderer(
            own_dir, script,
            ["render"] + type_args + ["--wiki-root", str(wiki_root),
             "--wiki-scripts-dir", str(wiki_scripts)],
        )
        data["rendered"].append({
            "type": label,
            "ok": ok,
            **({"error": payload.get("error", "")} if not ok else {}),
        })
        if not ok:
            return _emit(False, data=data,
                         error=f"index render failed for {label}")

    # Phase 3: advertise the curated layout (locked by config_bump itself).
    proc = subprocess.run(
        [sys.executable, str(wiki_scripts / "config_bump.py"),
         "--wiki-root", str(wiki_root),
         "--key", "schema_version", "--set-string", TARGET_SCHEMA],
        capture_output=True,
        text=True,
    )
    try:
        bump = json.loads(proc.stdout)
    except ValueError:
        bump = {"success": False, "error": (proc.stderr or "").strip()[:500]}
    if not bump.get("success"):
        return _emit(False, data=data,
                     error=f"schema bump failed: {bump.get('error', 'unknown')}")
    data["schema_after"] = TARGET_SCHEMA

    # Best-effort log append (the log now lives under wiki/meta/).
    moved_n = sum(1 for p in moves if p["action"] == "moved")
    _append_migrate_log(
        wiki_root,
        f"migrate | curated layout {schema_before} -> {TARGET_SCHEMA} "
        f"(control files moved: {moved_n}, "
        f"overview: {data['overview_fold'].get('action', '')})",
    )

    data["action"] = "migrated"
    return _emit(True, data=data)


def main(argv: "list[str]") -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Migrate an existing wiki to the curated layout (schema 0.0.8): "
            "control files to wiki/meta/, overview narrative folded into the "
            "index intro, curated root MAP + per-type sub-indexes rendered. "
            "Dry-run by default; --apply to execute."
        ),
        allow_abbrev=False,
    )
    parser.add_argument(
        "--wiki-root",
        required=True,
        help="Absolute path to the wiki root (the dir containing wiki/ and .cogni-wiki/).",
    )
    parser.add_argument(
        "--wiki-scripts-dir",
        help=(
            "Override path to cogni-wiki's wiki-ingest scripts dir (containing "
            "config_bump.py and _wikilib.py). When omitted, self-resolves via "
            "the knowledge-ingest probe (vendored-first)."
        ),
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help=(
            "Actually relocate files, render indexes, and bump the schema. "
            "Without this flag the run is dry: planned moves are reported and "
            "the proposed indexes are staged to .cogni-wiki/*-proposed.md as "
            "the content-diff surface; nothing live is touched. With --repair: "
            "render the regenerated root MAP under the renderer's lock and "
            "reconcile schema_version up to the current engine schema."
        ),
    )
    parser.add_argument(
        "--repair",
        action="store_true",
        help=(
            "Regenerate drifted machine-owned regions on an already-curated "
            "base (schema >= 0.0.8) — keyed on the structural-drift class "
            "health.py emits, not the version floor. Regenerates the "
            "theme-scoped ROOT-LINKS region via root_index.py render and "
            "reconciles a lagging schema_version. Dry-run by default; pair "
            "with --apply to write. Idempotent (noop on a non-drifted, "
            "current-schema base). Does NOT re-author the OVERVIEW-NARRATIVE "
            "placeholder — that is the orchestrator's portal-narrator step. "
            "REFUSES a pre-0.0.8 base (run --migrate first)."
        ),
    )
    parser.add_argument(
        "--relocate-only",
        action="store_true",
        help=(
            "Restrict to the post-migration control-file relocation: on an "
            "already-curated base (schema >= 0.0.8) relocate misplaced "
            "flat-root control files into wiki/meta/ (or noop); REFUSE a "
            "pre-0.0.8 base instead of running the full migration. This is "
            "the mode knowledge-lint --fix=misplaced_control_files uses, so "
            "the lint fixer can never trigger the lossy layout migration."
        ),
    )
    args = parser.parse_args(argv)
    if getattr(args, "repair", False):
        return cmd_repair(args)
    return cmd_migrate(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
