#!/usr/bin/env python3
"""knowledge-ingest-postprocess.py — first-party orchestrator for the deterministic
tail of knowledge-ingest Phase 4 (Steps 4.1–4.5.6, the LLM-mediated backlink
*curation* and the Step 4.6 contradiction tripwire excepted).

Why this script exists (fragility, not performance)
---------------------------------------------------
Before this script, knowledge-ingest/SKILL.md drove the per-slug wiki integration
as a model-managed shell loop. That orchestration was the error-prone surface, not
a wall-clock one (a microbenchmark put the entire post-processing script budget at
~2.2s across 21 slugs — the dominant per-slug cost is the LLM backlink curation,
which stays in SKILL.md by design and cannot move into a stdlib script). Two real
footguns bit during that study:

  1. the env-var-as-trailing-arg slug/summary footgun — untrusted summary/slug text
     interpolated into a shell command line; and
  2. the mid-loop ``n_new`` / ``n_new_q`` counter drift — the model managing two
     running counters across a long loop.

This orchestrator collapses the model-managed loop into one structured call. It owns
env-var passing internally (summaries are read from ingest-manifest.json, never
interpolated), and it computes ``n_new``/``n_new_q`` authoritatively in one place
(``action == "inserted"`` only). It does NOT collapse the per-slug ``_wiki_lock``
cycles into one acquire — each vendored helper still takes the lock in its own
process, serially. There is **no acquire-once-then-shell-out** shape here (that
would deadlock: ``_wiki_lock`` is a non-re-entrant ``fcntl.flock(LOCK_EX)``); the
vendored engine is shelled out **unchanged**.

Byte-identical contract
-----------------------
The per-slug post-processing produces byte-identical wiki output vs the prior
SKILL.md shell loop on the same inputs: the same vendored scripts, in the same
order, with the same arguments (``wiki_index_update.py --summary <sanitized>
--category <theme_label> --max-summary 240``; ``config_bump.py --key entries_count
--delta <n>``; ``backlink_audit.py --apply-plan -``; ``question-store.py emit``;
``sub_index.py render``; ``knowledge-binding.py upsert-themes``). Only the
orchestration moved.

Inputs (all structured — never a command-line interpolation of untrusted text)
------------------------------------------------------------------------------
  * ``--project-path``        — project root holding ``.metadata/``
  * ``--wiki-root``           — the bound wiki root
  * ``--wiki-scripts-dir``    — resolved cogni-wiki ``wiki-ingest`` scripts dir
  * ``--knowledge-scripts-dir`` — this plugin's ``scripts/`` dir (for the sibling
                                  first-party scripts question-store / sub_index /
                                  knowledge-binding); defaults to this file's dir
  * ``--binding``             — binding.json path (read-only; threaded to emit and
                                  written by upsert-themes)
  * ``--knowledge-root``      — knowledge base root (for upsert-themes)
  * ``--new-slugs``           — file (``-`` for stdin) listing the source slugs
                                  ingested THIS run, one per line OR a JSON array,
                                  in deterministic order. These are the slugs Step 4
                                  iterates; the script reads each slug's summary +
                                  ``sub_question_refs`` from ingest-manifest.json.
  * ``--output-language``     — plan.json output language (passed to the merge of
                                  question-manifest is N/A here; reserved/forwarded)

Per-slug curated backlink plans (the LLM-mediated middle step that stays in
SKILL.md) are read from ``<project>/.metadata/.backlink-plan.<slug>.json`` by
convention; a missing or empty plan file means "no genuine relation found for this
slug" (skip apply — never invent a backlink).

Output
------
One JSON envelope ``{"success": bool, "data": {...}, "error": str|None}`` per the
insight-wave script contract. ``data`` carries everything the SKILL Step 6 summary
and the Step 7 run-metrics record need: counts, per-step outcomes, and the emit
envelope's ``questions`` / ``theme_bindings`` / ``skipped_no_findings`` /
``sources_unmapped`` pass-through.

Fail-soft posture (mirrors the prior SKILL.md flow exactly)
-----------------------------------------------------------
A helper failure never rolls back an ingested page — the page, its claims, and any
already-applied backlink/index row are on disk. Per-step failures are recorded and
surfaced in ``data``; the script keeps going. The only hard errors (``success:
false``) are structural input problems (missing manifest/plan, unreadable JSON) the
caller must fix before the post-processing can run at all.

stdlib only (bash + python3, no pip).
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

# This script's own dir on sys.path so `from _knowledge_lib import ...` resolves
# regardless of CWD (the orchestrator is a first-party cogni-knowledge script).
_SELF_DIR = Path(__file__).resolve().parent
if str(_SELF_DIR) not in sys.path:
    sys.path.insert(0, str(_SELF_DIR))

from _knowledge_lib import sanitize_summary  # noqa: E402


def _emit(success: bool, data: dict | None = None, error: str | None = None) -> int:
    print(json.dumps({"success": success, "data": data or {}, "error": error},
                     ensure_ascii=False))
    return 0 if success else 1


def _read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _load_new_slugs(spec: str) -> list[str]:
    """Read the this-run slug list from a file (or stdin via '-').

    Accepts either a JSON array of strings or a newline-delimited list. Order is
    preserved (the caller passes deterministic order); duplicates are dropped
    keeping first occurrence.
    """
    raw = sys.stdin.read() if spec == "-" else Path(spec).read_text(encoding="utf-8")
    raw = raw.strip()
    slugs: list[str]
    if not raw:
        slugs = []
    elif raw[0] == "[":
        parsed = json.loads(raw)
        if not isinstance(parsed, list):
            raise ValueError("--new-slugs JSON must be an array of slug strings")
        slugs = [str(s).strip() for s in parsed]
    else:
        slugs = [ln.strip() for ln in raw.splitlines()]
    seen: set[str] = set()
    out: list[str] = []
    for s in slugs:
        if s and s not in seen:
            seen.add(s)
            out.append(s)
    return out


def _run(cmd: list[str], stdin_text: str | None = None) -> tuple[int, str, str]:
    """Run a subprocess, returning (returncode, stdout, stderr). Never raises on a
    non-zero exit — the caller decides how to surface it (fail-soft)."""
    proc = subprocess.run(
        cmd,
        input=stdin_text,
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def _parse_envelope(stdout: str) -> dict | None:
    """Parse a JSON envelope from a helper's stdout; None on unparseable output."""
    out = (stdout or "").strip()
    if not out:
        return None
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        # Some helpers may print a trailing non-JSON line; take the last JSON line.
        for line in reversed(out.splitlines()):
            line = line.strip()
            if line.startswith("{"):
                try:
                    return json.loads(line)
                except json.JSONDecodeError:
                    continue
        return None


def _index_action(stdout: str) -> str | None:
    """Extract ``data.action`` from a wiki_index_update.py envelope (or None)."""
    env = _parse_envelope(stdout)
    if env is None:
        return None
    if isinstance(env, dict):
        data = env.get("data")
        if isinstance(data, dict) and "action" in data:
            return data.get("action")
        # wiki_index_update.py prints a bare action dict in some paths.
        if "action" in env:
            return env.get("action")
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--project-path", required=True)
    ap.add_argument("--wiki-root", required=True)
    ap.add_argument("--wiki-scripts-dir", required=True,
                    help="Resolved cogni-wiki wiki-ingest scripts dir (vendored-first)")
    ap.add_argument("--knowledge-scripts-dir", default=str(_SELF_DIR),
                    help="This plugin's scripts/ dir (sibling first-party scripts)")
    ap.add_argument("--binding", default=None,
                    help="binding.json path (read by emit; written by upsert-themes)")
    ap.add_argument("--knowledge-root", default=None,
                    help="Knowledge base root (required for upsert-themes)")
    ap.add_argument("--new-slugs", required=True,
                    help="File ('-' for stdin) of this-run source slugs (JSON array "
                         "or newline list, deterministic order)")
    ap.add_argument("--output-language", default="en")
    args = ap.parse_args()

    project = Path(args.project_path)
    meta = project / ".metadata"
    wiki_root = args.wiki_root
    wiki_scripts = Path(args.wiki_scripts_dir)
    k_scripts = Path(args.knowledge_scripts_dir)

    # --- Structural input validation (the only hard-error class) ---------------
    manifest_path = meta / "ingest-manifest.json"
    plan_path = meta / "plan.json"
    candidates_path = meta / "candidates.json"
    if not manifest_path.is_file():
        return _emit(False, error=f"ingest-manifest.json not found: {manifest_path}")
    if not plan_path.is_file():
        return _emit(False, error=f"plan.json not found: {plan_path}")
    try:
        manifest = _read_json(manifest_path)
        plan = _read_json(plan_path)
    except (OSError, json.JSONDecodeError) as exc:
        return _emit(False, error=f"could not read inputs: {exc}")

    backlink_audit = wiki_scripts / "backlink_audit.py"
    wiki_index_update = wiki_scripts / "wiki_index_update.py"
    config_bump = wiki_scripts / "config_bump.py"
    if not backlink_audit.is_file() or not wiki_index_update.is_file() or not config_bump.is_file():
        return _emit(False, error=f"vendored wiki-ingest scripts missing under {wiki_scripts}")

    question_store = k_scripts / "question-store.py"
    sub_index = k_scripts / "sub_index.py"
    knowledge_binding = k_scripts / "knowledge-binding.py"

    try:
        new_slugs = _load_new_slugs(args.new_slugs)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        return _emit(False, error=f"could not read --new-slugs: {exc}")

    # --- Build the lookups the per-slug loop needs (authoritative, in one place) -
    # theme_label map keyed by sub-question id (from plan.sub_questions[]).
    theme_label_by_sqid: dict[str, str] = {}
    for sq in (plan.get("sub_questions") or []):
        sqid = sq.get("id")
        if sqid:
            theme_label_by_sqid[sqid] = sq.get("theme_label", "") or ""
    query_by_sqid: dict[str, str] = {
        sq.get("id"): sq.get("query", "")
        for sq in (plan.get("sub_questions") or []) if sq.get("id")
    }

    # ingested[] entry by slug — carries the ingester-authored summary +
    # sub_question_refs. Reading the summary here (not via a shell env var) is what
    # removes the env-var-as-trailing-arg footgun.
    ingested_by_slug: dict[str, dict] = {}
    for entry in (manifest.get("ingested") or []):
        slug = entry.get("slug")
        if slug:
            ingested_by_slug[slug] = entry

    def _category_for_refs(refs) -> str:
        """Source category: first-listed sub_question_ref's theme_label, else Sources."""
        if refs:
            first = refs[0]
            label = theme_label_by_sqid.get(first, "")
            if label:
                return label
        return "Sources"

    data: dict = {
        "n_new": 0,
        "n_new_q": 0,
        "backlinks_applied": 0,
        "backlinks_failed": 0,
        "failed_index_updates": [],
        "reverse_links_applied": 0,
        "reverse_links_failed": 0,
        "sources_subindex": "skipped",
        "questions_subindex": "skipped",
        "questions": [],
        "theme_bindings": [],
        "skipped_no_findings": [],
        "sources_unmapped": [],
        "themes_added": 0,
        "themes_updated": 0,
        "warnings": [],
        "new_slug_count": len(new_slugs),
    }

    # =====================================================================
    # Step 4.1 (apply only) + 4.2 + 4.3: per-new-slug backlink apply + index
    # =====================================================================
    n_new = 0
    for slug in new_slugs:
        entry = ingested_by_slug.get(slug)
        if entry is None:
            # The slug was named as this-run but is not in ingested[] (e.g. it was
            # quarantined by the Step 3.5 integrity sweep). Skip — never index a
            # page that is not in the manifest.
            data["warnings"].append(f"new-slug not in ingested[]: {slug}")
            continue

        # --- 4.1 apply curated backlink plan (the audit + curation stays in SKILL) -
        plan_file = meta / f".backlink-plan.{slug}.json"
        if plan_file.is_file():
            try:
                plan_text = plan_file.read_text(encoding="utf-8").strip()
            except OSError as exc:
                plan_text = ""
                data["warnings"].append(f"backlink plan unreadable for {slug}: {exc}")
            if plan_text:
                # Validate it carries at least one target before shelling out.
                targets = []
                try:
                    targets = (json.loads(plan_text) or {}).get("targets") or []
                except json.JSONDecodeError:
                    targets = []
                if targets:
                    rc, out, err = _run(
                        ["python3", str(backlink_audit),
                         "--wiki-root", wiki_root,
                         "--new-page", slug,
                         "--apply-plan", "-"],
                        stdin_text=plan_text,
                    )
                    env = _parse_envelope(out)
                    if rc == 0 and isinstance(env, dict):
                        d = env.get("data") or {}
                        data["backlinks_applied"] += len(d.get("applied") or [])
                        data["backlinks_failed"] += len(d.get("failed") or [])
                    else:
                        data["backlinks_failed"] += len(targets)
                        data["warnings"].append(
                            f"backlink apply failed for {slug}: {err.strip() or 'non-zero exit'}")

        # --- 4.2/4.3 index update (sanitized summary + thematic category) --------
        raw_summary = entry.get("summary", "") or ""
        clean_summary = sanitize_summary(raw_summary)
        category = _category_for_refs(entry.get("sub_question_refs") or [])
        rc, out, err = _run(["python3", str(wiki_index_update),
                             "--wiki-root", wiki_root,
                             "--slug", slug,
                             "--summary", clean_summary,
                             "--category", category,
                             "--max-summary", "240"])
        if rc != 0:
            data["failed_index_updates"].append({"slug": slug, "kind": "source",
                                                 "error": (err.strip() or "non-zero exit")})
            continue
        action = _index_action(out)
        if action == "inserted":
            n_new += 1
        elif action is None:
            data["warnings"].append(f"index update for {slug}: unparseable envelope")

    data["n_new"] = n_new

    # =====================================================================
    # Step 4 (after loop): entries_count bump by n_new, then sources sub-index
    # =====================================================================
    if n_new > 0:
        rc, out, err = _run(["python3", str(config_bump),
                             "--wiki-root", wiki_root,
                             "--key", "entries_count",
                             "--delta", str(n_new)])
        if rc != 0:
            data["warnings"].append(
                f"entries_count bump (+{n_new}) failed — run wiki-lint --fix=entries_count_drift")
            data["sources_entries_bump"] = "failed"
        else:
            data["sources_entries_bump"] = f"+{n_new}"

        rc, out, err = _run(["python3", str(sub_index), "render",
                             "--type", "sources",
                             "--wiki-root", wiki_root,
                             "--wiki-scripts-dir", str(wiki_scripts)])
        data["sources_subindex"] = "rendered" if rc == 0 else "failed"
        if rc != 0:
            data["warnings"].append(
                f"sources sub-index render failed — {err.strip() or 'non-zero exit'}; source pages on disk")
    else:
        data["sources_entries_bump"] = "unchanged"
        data["sources_subindex"] = "unchanged"

    # =====================================================================
    # Step 4.5.1: question-store emit (once)
    # =====================================================================
    emit_cmd = ["python3", str(question_store), "emit",
                "--wiki-root", wiki_root,
                "--wiki-scripts-dir", str(wiki_scripts),
                "--plan", str(plan_path),
                "--candidates", str(candidates_path),
                "--ingest-manifest", str(manifest_path)]
    if args.binding:
        emit_cmd += ["--binding", args.binding]
    rc, out, err = _run(emit_cmd)
    emit_env = _parse_envelope(out)
    questions: list[dict] = []
    theme_bindings: list[dict] = []
    if rc == 0 and isinstance(emit_env, dict) and emit_env.get("success"):
        ed = emit_env.get("data") or {}
        questions = ed.get("questions") or []
        theme_bindings = ed.get("theme_bindings") or []
        data["questions"] = questions
        data["theme_bindings"] = theme_bindings
        data["skipped_no_findings"] = ed.get("skipped_no_findings") or []
        data["sources_unmapped"] = ed.get("sources_unmapped") or []
        if ed.get("binding_skipped"):
            data["warnings"].append(f"question-store binding read skipped: {ed.get('binding_skipped')}")
    else:
        err_msg = (emit_env or {}).get("error") if isinstance(emit_env, dict) else (err.strip() or "non-zero exit")
        data["warnings"].append(f"question-store emit failed: {err_msg}")
        # No question nodes this run — finalize falls through to its legacy path.

    # Persist the question manifest (phase handoff to knowledge-finalize) —
    # unconditional whenever data.questions is non-empty.
    if questions:
        try:
            (meta / "question-manifest.json").write_text(
                json.dumps(questions, ensure_ascii=False), encoding="utf-8")
            data["question_manifest"] = "written"
        except OSError as exc:
            data["warnings"].append(f"question-manifest write failed: {exc}")
            data["question_manifest"] = "failed"
    else:
        data["question_manifest"] = "skipped"

    # =====================================================================
    # Step 4.5.2 (R1 reverse links) + 4.5.3 (question index) per question
    # =====================================================================
    n_new_q = 0
    for q in questions:
        qslug = q.get("slug")
        if not qslug:
            continue
        sources_answering = q.get("sources_answering") or []
        sqid = q.get("sub_question_id")

        # --- 4.5.2 reverse source->question links (## Research questions heading) -
        if sources_answering:
            targets = [{
                "slug": src,
                "sentence": f"Answers research question [[{qslug}]].",
                "insert_after_heading": "## Research questions",
            } for src in sources_answering]
            plan_json = json.dumps({"targets": targets}, ensure_ascii=False)
            rc, out, err = _run(
                ["python3", str(backlink_audit),
                 "--wiki-root", wiki_root,
                 "--new-page", qslug,
                 "--apply-plan", "-",
                 "--create-missing-heading"],
                stdin_text=plan_json,
            )
            env = _parse_envelope(out)
            if rc == 0 and isinstance(env, dict):
                d = env.get("data") or {}
                data["reverse_links_applied"] += len(d.get("applied") or [])
                data["reverse_links_failed"] += len(d.get("failed") or [])
            else:
                data["reverse_links_failed"] += len(targets)
                data["warnings"].append(
                    f"reverse-link apply failed for question {qslug}: {err.strip() or 'non-zero exit'}")

        # --- 4.5.3 index update: file the question under its theme_label heading --
        category = ""
        if sqid:
            category = theme_label_by_sqid.get(sqid, "")
        if not category:
            category = "Research questions"
        raw_q_summary = q.get("query", "") or query_by_sqid.get(sqid, "") or ""
        clean_q_summary = sanitize_summary(raw_q_summary)
        rc, out, err = _run(["python3", str(wiki_index_update),
                             "--wiki-root", wiki_root,
                             "--slug", qslug,
                             "--summary", clean_q_summary,
                             "--category", category,
                             "--max-summary", "240"])
        if rc != 0:
            data["failed_index_updates"].append({"slug": qslug, "kind": "question",
                                                 "error": (err.strip() or "non-zero exit")})
            continue
        action = _index_action(out)
        if action == "inserted":
            n_new_q += 1

    data["n_new_q"] = n_new_q

    # =====================================================================
    # Step 4.5.4: entries_count bump by n_new_q
    # =====================================================================
    if n_new_q > 0:
        rc, out, err = _run(["python3", str(config_bump),
                             "--wiki-root", wiki_root,
                             "--key", "entries_count",
                             "--delta", str(n_new_q)])
        if rc != 0:
            data["warnings"].append(
                f"entries_count bump (+{n_new_q} questions) failed — run wiki-lint --fix=entries_count_drift")
            data["questions_entries_bump"] = "failed"
        else:
            data["questions_entries_bump"] = f"+{n_new_q}"
    else:
        data["questions_entries_bump"] = "unchanged"

    # =====================================================================
    # Step 4.5.5: record theme lineage (upsert-themes) — single binding writer
    # =====================================================================
    if theme_bindings:
        if not args.knowledge_root:
            data["warnings"].append("theme lineage skipped: --knowledge-root not provided")
        else:
            tb_path = meta / "theme-bindings.json"
            try:
                tb_path.write_text(json.dumps(theme_bindings, ensure_ascii=False), encoding="utf-8")
            except OSError as exc:
                data["warnings"].append(f"theme-bindings write failed: {exc}")
                tb_path = None
            if tb_path is not None:
                rc, out, err = _run(["python3", str(knowledge_binding), "upsert-themes",
                                     "--knowledge-root", args.knowledge_root,
                                     "--records", str(tb_path)])
                env = _parse_envelope(out)
                if rc == 0 and isinstance(env, dict) and env.get("success"):
                    bd = env.get("data") or {}
                    data["themes_added"] = bd.get("themes_added", 0)
                    data["themes_updated"] = bd.get("themes_updated", 0)
                else:
                    data["warnings"].append(
                        f"upsert-themes failed (fail-soft; re-emitted next run): "
                        f"{(env or {}).get('error') if isinstance(env, dict) else (err.strip() or 'non-zero exit')}")

    # =====================================================================
    # Step 4.5.6: render questions sub-index
    # =====================================================================
    if n_new_q > 0:
        rc, out, err = _run(["python3", str(sub_index), "render",
                             "--type", "questions",
                             "--wiki-root", wiki_root,
                             "--wiki-scripts-dir", str(wiki_scripts)])
        data["questions_subindex"] = "rendered" if rc == 0 else "failed"
        if rc != 0:
            data["warnings"].append(
                f"questions sub-index render failed — {err.strip() or 'non-zero exit'}; question nodes on disk")
    else:
        data["questions_subindex"] = "unchanged"

    return _emit(True, data=data)


if __name__ == "__main__":
    sys.exit(main())
