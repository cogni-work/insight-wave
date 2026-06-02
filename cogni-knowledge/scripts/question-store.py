#!/usr/bin/env python3
"""question-store.py — emit per-sub-question `type: question` wiki nodes.

v0.1.0 inverted pipeline, Phase 4 (`knowledge-ingest` Step 4.5, #407). The
deterministic engine that promotes each `plan.sub_questions[]` entry into a
first-class research-question node at `wiki/questions/<slug>.md` whose body
`[[links]]` the source findings that answer it. The reverse `source→question`
backlink, the `wiki/index.md` row, and the `entries_count` bump are applied by
the orchestrator via cogni-wiki's own locked helpers (`backlink_audit.py`,
`wiki_index_update.py`, `config_bump.py`) — this script owns only the page
write, which is unique-by-construction per slug (no lock needed, same posture
as the Step 3 source pages).

Subcommand:
  emit   Join plan.json + candidates.json + ingest-manifest.json, build each
         sub-question's finding set, derive a globally-unique slug, write or
         merge `wiki/questions/<slug>.md`, and return the per-question plan the
         orchestrator consumes for backlink / index / count steps.

Cross-run theme accumulation (#409): an optional `--binding` arg reads
`topic_lineage.covered_themes[]` to map a theme's `_knowledge_lib.theme_norm_key`
to its recorded `question_slug`, so a recurring theme phrased differently across
runs (variant `theme_label`) routes to the SAME question node instead of forking
a second one. Read-only — the script emits `data.theme_bindings[]` and the
orchestrator persists them via `knowledge-binding.py upsert-themes` (the single
binding writer). Without `--binding`, behaviour is byte-identical to the pre-#409
slug-only accumulation.

`--wiki-scripts-dir` points at cogni-wiki's `wiki-ingest/scripts/` (resolved by
the orchestrator, same `resolve_wiki_scripts` helper knowledge-ingest uses) so
we import `PAGE_TYPE_DIRS` + `split_frontmatter` from the single source of
truth rather than re-deriving the per-type layout. Slug derivation +
atomic write reuse `_knowledge_lib.slugify` / `atomic_write_text`.

Returns the insight-wave `{"success", "data", "error"}` envelope. Stdlib only.
"""

from __future__ import annotations

import argparse
import datetime
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import atomic_write_text, normalize_url, slugify, theme_norm_key  # noqa: E402


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def cmd_emit(args: argparse.Namespace) -> int:
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import PAGE_TYPE_DIRS, split_frontmatter  # noqa: E402
    except Exception as exc:  # pragma: no cover - import guard
        return _emit(False, error=f"could not import cogni-wiki _wikilib from {wiki_scripts}: {exc}")

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")

    try:
        plan = _load_json(Path(args.plan))
        cands = _load_json(Path(args.candidates))
        manifest = _load_json(Path(args.ingest_manifest))
    except (OSError, json.JSONDecodeError) as exc:
        return _emit(False, error=f"could not read inputs: {exc}")

    # Lineage map (#409): theme_norm_key -> recorded question_slug, from the
    # binding's topic_lineage.covered_themes[]. Read-only here — this script
    # NEVER writes binding.json; the orchestrator persists new/updated themes
    # via `knowledge-binding.py upsert-themes` (the single writer). The map is
    # empty when --binding is absent (byte-identical to the pre-#409 path), the
    # binding is older / has no covered_themes (fail-soft .get chain), the
    # binding is corrupt / transiently unreadable (#426 fail-soft read degrade),
    # or the binding parses as valid JSON but is structurally wrong for the
    # lineage read (#428 fail-soft shape degrade below). In every degrade case
    # the reason is surfaced as data.binding_skipped and emit never aborts.
    lineage: dict[str, str] = {}
    binding_skipped = ""
    if args.binding:
        try:
            binding = _load_json(Path(args.binding))
        except (OSError, json.JSONDecodeError) as exc:
            # Lineage is an enhancement layer — a corrupt / transiently
            # unreadable binding degrades to slug-only accumulation, never
            # blocks question-node creation. Reason surfaced for observability.
            binding_skipped = f"could not read --binding: {exc}"
        else:
            # #428: a binding that parses as valid JSON but is the wrong shape
            # (a JSON array/scalar, or a present-but-null / non-dict
            # topic_lineage — the {} default only fires on an ABSENT key) must
            # degrade the same way, not raise an AttributeError past the
            # read-error catch into the top-level guard. An explicit shape guard
            # keeps the binding_skipped reason accurate (vs widening the except)
            # and the happy path byte-stable.
            if not isinstance(binding, dict):
                binding_skipped = (
                    f"--binding is not a JSON object "
                    f"(got {type(binding).__name__}); ignoring lineage"
                )
            else:
                tl = binding.get("topic_lineage", {})
                if not isinstance(tl, dict):
                    binding_skipped = (
                        "--binding topic_lineage is not an object; ignoring lineage"
                    )
                    tl = {}
                for e in tl.get("covered_themes", []) or []:
                    if not isinstance(e, dict):
                        continue
                    tk = e.get("theme_key")
                    qs = e.get("question_slug")
                    if tk and qs:
                        lineage[tk] = qs

    today = datetime.date.today().isoformat()
    questions_dir = wiki_root / "wiki" / "questions"

    # URL(normalized) -> source slug, from this project's ingested findings.
    url_to_slug = {
        normalize_url(e["url"]): e["slug"]
        for e in manifest.get("ingested", []) or []
        if e.get("url") and e.get("slug")
    }
    # URL(normalized) -> sub_question_refs[], from candidates.json.
    url_to_refs = {
        normalize_url(c["url"]): (c.get("sub_question_refs") or [])
        for c in cands.get("candidates", []) or []
        if c.get("url")
    }

    # sub_question_id -> ordered, de-duped list of answering source slugs.
    # A source whose ingested URL matches no candidate sub_question_ref (e.g. a
    # redirect / PDF canonicalization diverged the ingested URL from the
    # candidate URL) maps to no question node and is recorded in
    # `sources_unmapped` rather than dropping silently (observability).
    sq_findings: dict[str, list[str]] = {}
    sources_unmapped: list[str] = []
    for nurl, slug in url_to_slug.items():
        refs = url_to_refs.get(nurl, [])
        if not refs:
            sources_unmapped.append(slug)
            continue
        for ref in refs:
            bucket = sq_findings.setdefault(ref, [])
            if slug not in bucket:
                bucket.append(slug)

    def slug_exists_as(slug: str):
        """Return the existing page type for `slug`, or None. Wiki slugs are
        global, so a question node must not collide with any other type."""
        for ptype, dirname in PAGE_TYPE_DIRS.items():
            if (wiki_root / "wiki" / dirname / f"{slug}.md").is_file():
                return ptype
        return None

    emitted_slugs: dict[str, str] = {}  # slug -> sub_question_id written this run

    def resolve_slug(base: str):
        """Free slug, or an existing QUESTION page from a PRIOR run -> reuse
        (merge). Disambiguate with -q / -q-N when the base slug collides with a
        different page type OR with a question page already written *this run*
        for a different sub-question — two distinct sub-questions whose
        theme_label slugifies identically must not conflate into one node, while
        the cross-run enrich-on-collision merge stays intact."""
        cand = base
        n = 2
        while True:
            if cand in emitted_slugs:
                # Already written this run (different sub-question; each id is
                # processed once) -> never a merge target, disambiguate.
                cand = f"{base}-q" if n == 2 else f"{base}-q-{n}"
                n += 1
                continue
            existing = slug_exists_as(cand)
            if existing in (None, "question"):
                return cand, existing == "question"
            cand = f"{base}-q" if n == 2 else f"{base}-q-{n}"
            n += 1

    questions_out: list[dict] = []
    skipped_no_findings: list[str] = []
    theme_bindings: list[dict] = []
    seen_tkeys: set[str] = set()  # first-writer-wins per theme_key within a run

    for sq in plan.get("sub_questions", []) or []:
        sqid = sq.get("id", "")
        findings = list(sq_findings.get(sqid, []))
        if not findings:
            skipped_no_findings.append(sqid)
            continue

        theme = (sq.get("theme_label") or "").strip()
        # Slug-base precedence (#409): a lineage match on the theme_norm_key
        # reuses the recorded question_slug, so a variant theme_label routes to
        # the existing prior-run node (resolve_slug then returns is_merge=True
        # and the union path fires). Otherwise the pre-#409 base derivation.
        tkey = theme_norm_key(theme)
        lineage_hit = bool(tkey) and tkey in lineage
        if lineage_hit:
            base = lineage[tkey]
        else:
            base = slugify(theme) or (slugify(sqid) or sqid)  # legacy plans -> sq-NN
        slug, is_merge = resolve_slug(base)
        path = questions_dir / f"{slug}.md"

        created = today
        notes_block = "## Notes\n"
        if is_merge and path.is_file():
            prior_text = path.read_text(encoding="utf-8")
            pfm, pbody = split_frontmatter(prior_text)
            created = pfm.get("created") or today
            # Union prior answering sources (idempotent enrich-on-collision).
            # split_frontmatter returns inline lists already parsed as lists.
            for s in (pfm.get("sources_answering") or []):
                if s not in findings:
                    findings.append(s)
            # Preserve the human-owned ## Notes tail verbatim.
            marker = "\n## Notes"
            idx = pbody.find(marker)
            if idx != -1:
                notes_block = pbody[idx + 1:].rstrip() + "\n"

        domains = sq.get("candidate_domains") or []
        fm_lines = [
            "---",
            f"id: {slug}",
            f"title: {json.dumps(sq.get('query', ''), ensure_ascii=False)}",
            "type: question",
            "tags: [question]",
            f"created: {created}",
            f"updated: {today}",
            f"theme_label: {json.dumps(theme, ensure_ascii=False)}",
            f"sub_question_id: {sqid}",
            f"search_guidance: {json.dumps(sq.get('search_guidance', ''), ensure_ascii=False)}",
            f"candidate_domains: [{', '.join(json.dumps(str(d), ensure_ascii=False) for d in domains)}]",
            f"sources_answering: [{', '.join(findings)}]",
            "---",
        ]
        body_lines = ["", "## Findings", ""]
        body_lines += [f"- [[{s}]]" for s in findings]
        body_lines += ["", notes_block.rstrip() + "\n"]
        page = "\n".join(fm_lines) + "\n" + "\n".join(body_lines).rstrip() + "\n"

        atomic_write_text(path, page)
        emitted_slugs[slug] = sqid
        questions_out.append({
            "slug": slug,
            "sub_question_id": sqid,
            "query": sq.get("query", ""),
            "sources_answering": findings,
            "action": "merged" if is_merge else "created",
        })

        # Theme-lineage binding (#409): one record per written question whose
        # theme_label has a non-empty norm key, first-writer-wins per theme_key
        # (a second same-run sub-question that -q-disambiguates to a distinct
        # node must NOT steal the canonical node's theme_key). An empty tkey
        # (legacy / stopword-only theme_label) records nothing — that node
        # accumulates by slug only, as before. The orchestrator feeds these to
        # `knowledge-binding.py upsert-themes` (the single binding writer).
        if tkey and tkey not in seen_tkeys:
            seen_tkeys.add(tkey)
            theme_bindings.append({
                "theme_key": tkey,
                "question_slug": slug,
                "theme_label": theme,
                "action": "lineage_reused" if lineage_hit else "new_theme",
            })

    data = {
        "questions": questions_out,
        "theme_bindings": theme_bindings,
        "skipped_no_findings": skipped_no_findings,
        "sources_unmapped": sources_unmapped,
        "questions_written": len(questions_out),
    }
    if binding_skipped:
        data["binding_skipped"] = binding_skipped
    return _emit(True, data=data)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_emit = sub.add_parser("emit", help="Write per-sub-question type:question nodes")
    p_emit.add_argument("--wiki-root", required=True)
    p_emit.add_argument("--wiki-scripts-dir", required=True,
                        help="cogni-wiki wiki-ingest/scripts/ dir (for PAGE_TYPE_DIRS + split_frontmatter)")
    p_emit.add_argument("--plan", required=True, help="<project>/.metadata/plan.json")
    p_emit.add_argument("--candidates", required=True, help="<project>/.metadata/candidates.json")
    p_emit.add_argument("--ingest-manifest", required=True, help="<project>/.metadata/ingest-manifest.json")
    p_emit.add_argument(
        "--binding",
        required=False,
        default="",
        help="Optional .cogni-knowledge/binding.json. When given, "
             "topic_lineage.covered_themes[] supplies a theme_norm_key -> "
             "question_slug map so a recurring theme (variant theme_label) "
             "routes to its existing question node (#409). Read-only; the "
             "orchestrator persists new/updated themes via knowledge-binding.py "
             "upsert-themes. Absent -> byte-identical to the pre-#409 path.",
    )
    p_emit.set_defaults(func=cmd_emit)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except Exception as exc:  # pragma: no cover - top-level guard
        return _emit(False, error=f"{type(exc).__name__}: {exc}")


if __name__ == "__main__":
    sys.exit(main())
